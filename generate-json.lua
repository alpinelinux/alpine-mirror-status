#!/usr/bin/lua5.3

local request = require("http.request")
local yaml = require("lyaml")
local json = require("cjson")

local utils = require("utils")
local conf = require("config")

----
-- convert apkindex list to a table
function get_apkindexes()
	local res = {}
	local qty = 0
	for line in io.lines(conf.apkindex_list) do
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
	stream:shutdown()
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
	local headers, stream = request.new_from_uri(uri):go(conf.http_timeout)
	if stream then stream:shutdown() end
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
	local output = ("%s/%s"):format(conf.outdir, conf.mirrors_json)
	local f = assert(io.open(output, "w"))
	local json = assert(json.encode(t))
	f:write(json)
	f:close()
end

--- print msg on console when debug is provided
function msg(s)
	if arg[1] == "debug" then print(s) end
end

--- show a process indicator on stdout
function progress(num)
	if arg[1] == "debug" then
		num = (num < 10) and "0"..num or num
		io.write(("Indexes left: %s\r"):format(num))
		io.flush()
	end
end

-- check all apkindex for specific mirror
function check_apkindexes(mirror)
	local indexes, num_indexes = get_apkindexes()
	local branches = {}
	local qty = 0
	local cnt = 0
	local allowed_archs = utils.to_list(conf.archs)
	for branch in utils.kpairs(indexes, utils.sort_branch) do
		local repos = {}
		for repo in utils.kpairs(indexes[branch], utils.sort_repo) do
			local archs = {}
			for arch in utils.kpairs(indexes[branch][repo], utils.sort_arch) do
				if type(allowed_archs[arch]) == "number" then
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
	local mirrors = get_mirrors(conf.mirrors_yaml)
	for idx,mirror in ipairs(mirrors) do
		local start_time = os.time()
		res[idx] = {}
		res[idx].url = mirror
		msg(("[%s/%s] Getting indexes from mirror: %s"):format(idx,
			#mirrors, mirror))
		res[idx].branch, res[idx].count = check_apkindexes(mirror)
		res[idx].duration = os.difftime(os.time(),start_time)
	end
	return res
end

function process_master()
	msg(("Getting indexes from master: %s"):format(conf.master_url))
	local res = {}
	res.url = conf.master_url
	res.branch = check_apkindexes(conf.master_url)
	return res
end

write_json(
	{
		master = process_master(),
		mirrors = process_mirrors(),
		date = os.time(),
		version = conf.version
	}
)
