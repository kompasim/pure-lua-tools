--[[
    Time
]]

assert(Time == nil)
Time = class("Time")

local SECONDS_WEEK = 60 * 60 * 24 * 7
local SECONDS_DAY = 60 * 60 * 24
local SECONDS_HOUR = 60 * 60
local SECONDS_MINUTE = 60
local SECONDS_SECOND = 1

function Time:__init__(time, zone)
    self._time = time or os.time()
    self._zone = zone
    if not self._zone then
        local now = os.time()
        local utc = os.time(os.date("!*t", now))
        local diff = os.difftime(now, utc)
        self._zone = math.floor(diff / SECONDS_HOUR)
    end
end

function Time:getValue()
    return self._time
end

function Time:getDate(desc)
    return os.date(desc or "%Y-%m-%d_%H:%M:%S", self._time)
end

function Time:getTime()
    return self._time
end

function Time:setTime(time)
    assert(time ~= nil)
    self._time = time
    return self
end

function Time:getZone()
    return self._zone
end

function Time:setZone(zone)
    assert(zone ~= nil)
    self._time = self._time - self._zone * SECONDS_HOUR
    self._zone = zone
    self._time = self._time + self._zone * SECONDS_HOUR
    return self
end

function Time:getYear()
    return tonumber(os.date("%Y", self._time))
end

function Time:getMonth()
    return tonumber(os.date("%m", self._time))
end

function Time:nameMonth(isFull)
    return os.date(isFull and "%B" or "%b", self._time)
end

function Time:getDay()
    return tonumber(os.date("%d", self._time))
end

function Time:getYMD()
    return self:getYear(), self:getMonth(), self:getDay()
end

function Time:getHour()
    return tonumber(os.date("%H", self._time))
end

function Time:getMinute()
    return tonumber(os.date("%M", self._time))
end

function Time:getSecond()
    return tonumber(os.date("%S", self._time))
end

function Time:getHMS()
    return self:getHour(), self:getMinute(), self:getSecond()
end

function Time:getWeek()
    local w = tonumber(os.date("%w", self._time))
    return w == 0 and 7 or w
end

function Time:nameWeek(isFull)
    return os.date(isFull and "%A" or "%a", self._time)
end

function Time:isAm()
    return self:getHour() < 12
end

function Time:isLeap()
    local year = self:getYear()
    if year % 4 == 0 and year % 100 ~= 0 then
        return true
    end
    if year % 400 == 0 then
        return true
    end
    return false
end

function Time:isSameWeek(time)
    return self:countWeek() == time:countWeek()
end

function Time:isSameDay(time)
    return self:countDay() == time:countDay()
end

function Time:isSameHour(time)
    return self:countHour() == time:countHour()
end

function Time:isSameMinute(time)
    return self:countMinute() == time:countMinute()
end

function Time:getYMDHMS()
    return self:getYear(), self:getMonth(), self:getDay(), self:getHour(), self:getMinute(), self:getSecond()
end

function Time:countWeek()
    local second = self._time % SECONDS_WEEK
    local hour = (self._time - second) / SECONDS_WEEK
    local time = Time(second)
    local result = {time:countDay()}
    table.insert(result, 1, hour)
    return unpack(result)
end

function Time:countDay()
    local second = self._time % SECONDS_DAY
    local hour = (self._time - second) / SECONDS_DAY
    local time = Time(second)
    local result = {time:countHour()}
    table.insert(result, 1, hour)
    return unpack(result)
end

function Time:countHour()
    local second = self._time % SECONDS_HOUR
    local hour = (self._time - second) / SECONDS_HOUR
    local time = Time(second)
    local result = {time:countMinute()}
    table.insert(result, 1, hour)
    return unpack(result)
end

function Time:countMinute()
    local second = self._time % SECONDS_MINUTE
    local minute = (self._time - second) / SECONDS_MINUTE
    return minute, second
end

function Time:addWeek(count)
    assert(count ~= nil)
    self._time = self._time + count * SECONDS_WEEK
    return self
end

function Time:addDay(count)
    assert(count ~= nil)
    self._time = self._time + count * SECONDS_DAY
    return self
end

function Time:addHour(count)
    assert(count ~= nil)
    self._time = self._time + count * SECONDS_HOUR
    return self
end

function Time:addMinute(count)
    assert(count ~= nil)
    self._time = self._time + count * SECONDS_MINUTE
    return self
end

function Time:addSecond(count)
    assert(count ~= nil)
    self._time = self._time + count * SECONDS_SECOND
    return self
end

function Time:diffTime(time)
    assert(time ~= nil)
    local distance = self:getValue() - time:getValue()
    return Time(math.abs(distance)), distance > 0
end

function Time:addTime(time)
    assert(time ~= nil)
    self._time = self._time + time:getValue()
    return self
end
