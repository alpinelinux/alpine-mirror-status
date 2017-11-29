local M = {}


M.allowed = {
	archs = { x86=1, x86_64=2, armhf=3, aarch64=4, ppc64le=5, s390x=6 },
	repos = { main=1, community=2, testing=3, backports=4 }
}

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
	local repos = M.allowed.repos
	if type(repos[a]) == "number" and type(repos[b]) == "number" then
		if repos[a] < repos[b] then return true end
	end
end

----
-- arch sort function for kpairs
function M.sort_arch(a,b)
	local archs = M.allowed.archs
	if type(archs[a]) == "number" and type(archs[b]) == "number" then 
		if archs[a] < archs[b] then return true end
	end
end

return M