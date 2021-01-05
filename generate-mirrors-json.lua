#!/usr/bin/lua5.3

---
-- convert private yaml to a public json mirror file
-- dependencies:
--  lua5.3-cjson
--  lua5.3-lyaml
--  lua5.3-penlight

local json = require("cjson")
local yaml = require("lyaml")
local pfile = require("pl.file")

local input  = assert(arg[1], "Please provide input yaml as first argument!")
local output = assert(arg[2], "Please provide output directory as second argument!")

local mirrors = yaml.load(pfile.read(input))
local public_keys = { "name", "location", "bandwidth", "urls" }

local res = {}
local txt = {}

for k,m in ipairs(mirrors) do
	res[k] = {}
	for _,pk in ipairs(public_keys) do
		http_url = nil
		https_url = nil
		res[k][pk] = m[pk]
		if pk == "urls" then
			for _,url in pairs(m.urls) do
				if url:find("http://") then
					http_url = url
				end
				if url:find("https://") then
					https_url = url
				end
			end
			if https_url ~= nil then
				table.insert(txt, https_url)
			elseif http_url ~= nil then
				table.insert(txt, http_url)
			end
		end
	end
end

pfile.write(output.."/mirrors.json", json.encode(res))
pfile.write(output.."/mirrors.txt", table.concat(txt, "\n"))
