#!/usr/bin/lua5.3

local inspect = require("inspect")
local request = require("http.request")
local yaml = require("yaml")
local json = require("cjson")
local utils = require("utils")

local app_version = "v0.0.1"
local apkindex_list = "apkindex.list"
local mirrors_yaml = "https://git.alpinelinux.org/cgit/aports/plain/main/alpine-mirrors/mirrors.yaml"
local master = "http://rsync.alpinelinux.org/alpine/"
local output = "_out/mirror-status.json"
local http_timeout = 3

----
-- convert apkindex list to a table
function get_apkindexes()
	local res = {}
	local qty = 0
	for line in io.lines(apkindex_list) do
		branch, repo, arch = line:match("^alpine/(.*)/(.*)/(.*)/APKINDEX.tar.gz")
		if type(res[branch]) == "nil" then res[branch] = {} end
		if type(res[branch][repo]) == "nil" then res[branch][repo] = {} end
		res[branch][repo][arch] = 1
		qty = qty + 1
	end
	return res, qty
end

----
-- convert last-modified header date to timestamp
function rfc2616_date_to_ts(s)
	local day,month,year,hour,min,sec
	local m = { Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9,
		Oct=10,Nov=11,Dec=12 }
	local format = "%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT"
	local day,month,year,hour,min,sec = s:match(format)
	return os.time({day=day,month=m[month],year=year,hour=hour,min=min,sec=sec})
end

----
-- get a list of http urls from mirrors yaml
function get_mirrors(uri)
	local res = {}
	local headers, stream = assert(request.new_from_uri(uri):go())
	if headers:get(":status") ~= "200" then
		error("Failed to get mirrors yaml!")
	end
	local y = assert(stream:get_body_as_string())
	local mirrors = yaml.load(y)
	for idx, mirror in ipairs(mirrors) do
		for _,url in ipairs(mirror.urls) do
			if url:match("http://") then
				table.insert(res, url)
			end
		end
	end
	return res
end

function get_index_status(uri)
	local res = {}
	local status, modified
	local headers = request.new_from_uri(uri):go(http_timeout)
	if headers then 
		status = headers:get(":status")
	else
		return "failed"
	end
	if status == "200" then
		modified = headers:get("last-modified")
		modified = rfc2616_date_to_ts(modified)
	end
	return status, modified
end

--- write results to json file on disk
function write_json(t)
	local f = assert(io.open(output, "w"))
	local json = assert(json.encode(t))
	f:write(json)
	f:close()
end

--- show a process indicator on stdout
function progress(num)
	num = (num < 10) and "0"..num or num
	io.write(("Indexes left: %s\r"):format(num))
	io.flush()
end

-- check all apkindex for specific mirror
function check_apkindexes(mirror)
	local indexes, num_indexes = get_apkindexes()
	local branches = {}
	local qty = 0
	local cnt = 0
	for branch in utils.kpairs(indexes, utils.sort_branch) do
		local repos = {}
		for repo in utils.kpairs(indexes[branch], utils.sort_repo) do
			local archs = {}
			for arch in utils.kpairs(indexes[branch][repo], utils.sort_arch) do
				if type(utils.allowed.archs[arch]) == "number" then
					local uri = ("%s/%s/%s/%s/APKINDEX.tar.gz"):format(mirror, branch, repo, arch)
					status, modified = get_index_status(uri)
					table.insert(archs, {name=arch, status=status, modified=modified})
					if status == "200" then qty = qty+1 end
				end
				cnt = cnt + 1
				progress(num_indexes-cnt)
			end
			table.insert(repos, {name=repo, arch=archs})
		end
		table.insert(branches, {name=branch, repo=repos})
	end
	return branches, qty
end

function process_mirrors()
	local res = {}
	local mirrors = get_mirrors(mirrors_yaml)
	for idx,mirror in ipairs(mirrors) do
		local start_time = os.time()
		res[idx] = {}
		res[idx].url = mirror
		print(("[%s/%s] Getting indexes from mirror: %s"):format(idx, 
			#mirrors, mirror))
		res[idx].branch, res[idx].count = check_apkindexes(mirror)
		res[idx].duration = os.difftime(os.time(),start_time)
	end
	return res
end

function process_master()
	print(("Getting indexes from master: %s"):format(master))
	local res = {}
	res.url = master
	res.branch = check_apkindexes(master)
	return res
end

write_json(
	{
		master = process_master(),
		mirrors = process_mirrors(),
		date = os.time(),
		version = app_version
	}
)
