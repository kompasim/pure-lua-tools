--[[
    file
]]

files = files or {}

local delimiter = nil
function files.delimiter()
    if delimiter then return delimiter end
    delimiter = string.find(os.tmpname(""), "\\") and "\\" or "/"
    return delimiter
end

function files.unixify(path)
    return path:gsub("\\+", "/"):gsub("/+", "/"):trim()
end

function files.home()
    local home = os.getenv('HOME') or os.getenv('USERPROFILE')
    return files.unixify(home)
end

function files.root()
    local cwd = files.cwd()
    return files.unixify(cwd):explode("/")[1]
end

function files.user()
    local path = string.format("%s/.%s/", files.home(), lua_get_user())
    files.mk_folder(path)
    return path
end

function files.temp()
    local path = files.user() .. "/my-lua-tmp/"
    files.mk_folder(path)
    return path
end

function files.temp_file(name, ext)
    name = name or "unknown"
    ext = ext or "txt"
    local dateText = os.date("%Y-%m-%d_%H-%M-%S", os.time())
    local tempName = os.tmpname():sub(2, -1)
    local tempFldr = files.temp()
    files.mk_folder(tempFldr)
    if string.ends(tempName, ".") then
        tempName = tempName .. "0"
    end
    return string.format("%s/%s_%s_%s.%s", tempFldr, name, dateText, tempName, ext)
end

function files.temp_clear(name)
    local tempFldr = files.temp()
    local list = files.list(tempFldr)
    local count = 0
    for i,path in ipairs(list) do
        if string.find(path, name) then
            files.delete(tempFldr .. "/" .. path)
            count = count + 1
        end
    end
    return count > 0
end

-- current working directory
local cwd = nil
function files.cwd()
    if cwd then return cwd end
    local isOk, output = nil, nil
    if tools.is_windows() then
        isOk, output = tools.execute("cd")
    else
        isOk, output = tools.execute("pwd")
    end
    assert(isOk and output ~= nil)
    cwd = output:trim():slash() .. '/'
    return files.unixify(cwd)
end

-- current script directory
function files.csd(thread)
    local info = debug.getinfo(thread or 2)
    if not info then return end
    local path = info.source:sub(2, -1)
    assert(path ~= nil)
    path = path:trim():slash()
    local folder = files.get_folder(path)
    local csd = files.absolute(folder)
    return files.unixify(csd)
end

function files.absolute(this)
    if string.match(this, "^/") or string.match(this, "^%a:") then
        return this
    end
    return files.cwd() .. this .. "/"
end

function files.relative(this)
    return this:gsub(files.cwd(), '')
end

function files.write(path, content, mode)
    local f = io.open(path, mode or "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

function files.read(path, mode)
    local f = io.open(path, mode or "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    return content
end

function files.size(path)
    f = io.open(path, "rb")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size
end

function files.delete(path)
    return os.remove(path)
end

function files.is_file(path)
    local f = io.open(path, "rb")
    if f then f:close() end
    return f ~= nil
end

function files.print(path)
    print("[file:" .. path .. "]")
    print("[[[[[[[")
    local lines = files.is_file(path) and io.lines(path) or ipairs({})
    local num = 0
    for line in lines do
        num = num + 1
        print(" " .. tostring(num):right(7, "0") .. " " .. line)
    end
    print("]]]]]]]")
end

function files.copy(from, to)
    local f1 = io.open(from, 'rb')
    local f2 = io.open(to, 'wb')
    if not f1 or not f2 then return end
    f2:write(f1:read('*a'))
    f1:close()
    f2:close()
    return true
end

function files.sync(from, to)
    assert(files.is_folder(from), 'sync from path is invalid')
    files.mk_folder(to)
    local t = files.list(from)
    for i,v in ipairs(t) do
        local fromPath = from .."/" .. v
        local toPath = to .."/" .. v
        if files.is_file(fromPath) then
            files.copy(fromPath, toPath)
        elseif files.is_folder(fromPath) then
            files.sync(fromPath, toPath)
        end
    end
end

function files.is_folder(path)
    if not path then return false end
    local isOk, _ = tools.execute("cd " .. path)
    return isOk == true
end

function files.mk_folder(path)
    if files.is_folder(path) then return end
    local isOk
    if tools.is_windows() then
        isOk = tools.execute(string.format([[mkdir "%s"]], path))
    else
        isOk = tools.execute(string.format([[mkdir -p "%s"]], path))
    end
    return isOk == true
end

function files.list(path)
    local r = table.new()
    if not files.is_folder(path) then return r end
    local isOk, out
    if tools.is_windows() then
        isOk, out = tools.execute(string.format([[dir /b "%s"]], path))
    else
        isOk, out = tools.execute(string.format([[ls "%s"]], path))
    end
    t = out:explode('\n')
    for i,v in ipairs(t) do
        if is_string(v) and #v > 0 then
            table.insert(r, v)
        end
    end
    return r
end

function files.get_folder(filePath)
    return string.gsub(filePath, "[^\\/]+%.[^\\/]+", "")
end

function files.modified(path)
    local stamp = nil
    xpcall(function()
        local isOk, result = tools.execute("stat -f %m " .. path) -- mac
        if isOk then stamp = result end
        local isOk, result = tools.execute("stat -c %Y " .. path) -- linux
        if isOk then stamp = result end
        assert(stamp ~= nil, 'get modified stamp failed')
    end, function(err)
        print(err)
    end)
    if not stamp then
        return -1
    end
    local modified = tonumber(stamp) or -1
    return modified
end

function files.watch(paths, callback, triggerDelay)
    if is_string(paths) then paths = {paths} end
    assert(#paths >= 1, 'the paths to watch should not be empty')
    assert(is_function(callback), 'the last argument should be a callback func')
    for i, path in ipairs(paths) do
        assert(files.is_file(path) or files.is_folder(path), 'path not found in watch:' .. tostring(path))
    end
    triggerDelay = triggerDelay or 1
    local modifiedMap = {}
    local function check(path)
        local modifiedTime = files.modified(path)
        if not modifiedMap[path] then
            callback(path, modifiedTime, true)
            modifiedMap[path] = modifiedTime
        elseif modifiedTime - modifiedMap[path] >= triggerDelay then
            callback(path, modifiedTime, false)
            modifiedMap[path] = modifiedTime
        end
    end
    while true do
        for i,v in ipairs(paths) do check(v) end
    end
end
