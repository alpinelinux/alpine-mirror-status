local conf = require("config")

local M = {}

function M.in_array(t, value)
	for k,v in ipairs(t) do
		if v == value then
			return true
		end
	end
end

function M.read_file(file)
	local f = assert(io.open(file))
	local file = f:read("*all")
	f:close()
	return file
end

function M.write_file(file, string)
	file = assert(io.open(file, "w"))
	file:write(string)
	file:close()
end

----
-- convert array to list
function M.to_list(t)
	local res = {}
	for k,v in ipairs(t) do
		res[v] = k
	end
	return res
end

----
-- table iterator which sorts on keys
function M.kpairs(t, f)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys,f)
    local i = 0
    return function()
        i = i + 1
        return keys[i], t[keys[i]]
    end
end

----
-- branch sort function for kpairs
function M.sort_branch(a,b)
	if a == "edge" then a = "z" end
	if b == "edge" then b = "z" end
	if a < b then return true end
end

----
-- repo sort function for kpairs
function M.sort_repo(a,b)
	local repos = M.to_list(conf.repos)
	if type(repos[a]) == "number" and type(repos[b]) == "number" then
		if repos[a] < repos[b] then return true end
	end
end

----
-- arch sort function for kpairs
function M.sort_arch(a,b)
	local archs = M.to_list(conf.archs)
	if type(archs[a]) == "number" and type(archs[b]) == "number" then 
		if archs[a] < archs[b] then return true end
	end
end

return M