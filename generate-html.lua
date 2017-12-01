#!/usr/bin/lua5.3

local json = require("cjson")
local inspect = require("inspect")
local lustache = require("lustache")
local utils = require("utils")

local outdir = "_out"
local mirrors_html = "index.html"
local mirrors_json = "mirror-status.json"

function get_branches(indexes)
	local res = {}
	for k,v in ipairs(indexes.master.branch) do
		table.insert(res, v.name)
	end
	return res
end

----
-- need to create one flipped table with both mirros and master
function flip_branches(branches)
	local res = {}
	for _,b in ipairs(branches) do
		for _,r in ipairs(b.repo) do
			for _,a in ipairs(r.arch) do
				if type(res[b.name]) == "nil" then res[b.name] = {} end
				if type(res[b.name][r.name]) == "nil" then
					res[b.name][r.name] = {}
				end
				res[b.name][r.name][a.name] = a
			end
		end
	end
	return res
end

----
-- convert table to array (values to keys)
function get_repo_arch(indexes)
	local t = {}
	for _,b in ipairs(indexes.master.branch) do
		for _,r in ipairs(b.repo) do
			for _,a in ipairs(r.arch) do
				if type(t[r.name]) == "nil" then t[r.name] = {} end
				t[r.name][a.name] = 1
			end
		end
	end
	local res = {}
	for repo in utils.kpairs(t, utils.sort_repo) do
		for arch in utils.kpairs(t[repo], utils.sort_arch) do
			table.insert(res, repo.."/"..arch)
		end
	end
	return res
end

----
-- convert table to array (values to keys) for each mirror
function flip_mirrors(mirrors)
	local res = {}
	for _,m in ipairs(mirrors) do
		res[m.url] = flip_branches(m.branch)
	end
	return res
end

----
-- format timestamp difference
function format_age(ts)
	local res = {}
	if ts < 3600 then
		res.text = "OK"
		res.class = "status-ok"
	elseif ts < 86400 then
		res.text = ("%dh"):format(math.ceil(ts/3600))
		res.class = "status-warn"
	elseif ts > 86400 then
		res.text = ("%dd"):format(math.ceil(ts/86400))
		res.class = "status-error"
	end
	return res
end

----
-- format status based on http status message
function format_status(status, age)
	local res = {}
	if status ~= "failed" then
		if status == "200" then
			res = format_age(age)
		elseif status == "404" then
			res.class = "status-na"
			res.text = "N/A"
		else
			res.class = "status-unk"
			res.text = status
		end
	else
		res.class = "status-na"
		res.text = "N/A"
	end
	return res
end

----
-- get status and format it based on http status and modified time
function get_status(fm, fb, mirror, branch, repo, arch)
	local res = { text = "N/A", class = "status-na" }
	if type(fm[mirror]) == "table" and
		type(fm[mirror][branch]) == "table" and
		type(fm[mirror][branch][repo]) == "table" and
		type(fm[mirror][branch][repo][arch]) == "table" then
		if type(fm[mirror][branch][repo][arch]) == "table" then
			local status = fm[mirror][branch][repo][arch]
			local age
			if type(status.modified) == "number" then
				age = fb[branch][repo][arch].modified - status.modified
			end
			res = format_status(status.status, age)
		end
	end
	return res
end

----
-- build the html table
function build_tables(indexes)
	local res = {}
	local fm = flip_mirrors(indexes.mirrors)
	local fb = flip_branches(indexes.master.branch)
	for idx,mirror in ipairs(indexes.mirrors) do
		local rows = {}
		for _,ra in ipairs(get_repo_arch(indexes)) do
			local repo, arch = ra:match("(.*)/(.*)")
			local row = {}
			table.insert(row, {text = ra})
			for _,branch in ipairs(get_branches(indexes)) do
				local status = get_status(fm, fb, mirror.url, branch, repo, arch)
				table.insert(row, status)
			end
			table.insert(rows, { row = row })
		end
		res[idx] = { 
			url = mirror.url, tbody = rows, duration = mirror.duration, 
			count = mirror.count
		}
	end
	return res
end

local indexes = json.decode(utils.read_file(outdir.."/"..mirrors_json))
local thead = get_branches(indexes)
table.insert(thead, 1, "branch/release")
local view = { lupdate = os.date("%c", indexes.date), mirrors = build_tables(indexes), thead = thead }
local tpl = utils.read_file("index.tpl")
utils.write_file(outdir.."/"..mirrors_html, lustache:render(tpl, view))
