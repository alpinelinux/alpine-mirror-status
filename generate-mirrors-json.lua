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
local output = assert(arg[2], "Please provide output json as second argument!")

local mirrors = yaml.load(pfile.read(input))
local public_keys = { "name", "location", "bandwidth", "urls" }

local res = {}

for k,m in ipairs(mirrors) do
	res[k] = {}
	for _,pk in ipairs(public_keys) do
		res[k][pk] = m[pk]
	end
end

pfile.write(output, json.encode(res))
