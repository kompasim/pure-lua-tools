--[[
    tools
]]

tools = tools or {}

local isWindows = nil
function tools.is_windows()
    if is_boolean(isWindows) then return isWindows end
    isWindows = package.config:sub(1,1) == "\\"
    return isWindows 
end

local isLinux = nil
function tools.is_linux()
    if is_boolean(isLinux) then return isLinux end
    isLinux = not tools.is_windows() and string.find(os.getenv("HOME") or "", '/home/') ~= nil
    return isLinux
end

local isLinux = nil
function tools.is_mac()
    if is_boolean(isLinux) then return isLinux end
    isLinux = not tools.is_windows() and string.find(os.getenv("HOME") or "", '/Users/') ~= nil
    return isLinux
end

function tools.execute(cmd)
    local flag = "::MY_ERROR_FLAG::"
    local file = io.popen(cmd .. [[ 2>&1 || echo ]] .. flag, "r")
    local out = file:read("*all"):trim()
    local isOk = not out:find(flag)
    if not isOk then
        out = out:sub(1, #out - #flag)
    end
    file:close()
    out = out:trim()
    return isOk, out
end

function tools.get_timezone()
    local now = os.time()
    local utc = os.time(os.date("!*t", now))
    local diff = os.difftime(now, utc)
    local zone = math.floor(diff / 60 / 60)
    return zone
end

function tools.get_milliseconds()
    local clock = os.clock()
    local _, milli = math.modf(clock)
    return math.floor(os.time() * 1000 + milli * 1000)
end

function tools.where_is(program)
    local command = tools.is_windows() and "where" or "which"
    local isOk, result = tools.execute(command .. [[ "]] .. program .. [["]])
    if isOk then
        local results = string.explode(result, "\n")
        return unpack(results)
    end
end

local editorNames = {'notepad', 'code'}
function tools.edit_file(path)
    for i,editorName in ipairs(editorNames) do
        local isFound = tools.where_is(editorName) ~= nil
        if isFound then
            os.execute(editorName .. " " .. path)
            return true
        end
    end
    return false
end

function tools.open_url(url)
    return tools.execute([[start "]] .. url .. [["]])
end
