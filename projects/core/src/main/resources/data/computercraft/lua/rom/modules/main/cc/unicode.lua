-- UTF-8 helpers without changing legacy string APIs.
-- This works with code points, not grapheme clusters.

local expect = require("cc.expect").expect

local utf8_len = utf8.len
local utf8_offset = utf8.offset
local utf8_codes = utf8.codes
local string_sub = string.sub
local string_format = string.format

local function make_invalid_error(position)
    return string_format("Invalid UTF-8 at byte %d", position)
end

local function check_valid(text, level)
    local length, position = utf8_len(text)

    if not length then
        error(make_invalid_error(position), level or 3)
    end

    return length
end

local function check_integer(index, value, name, level)
    if value % 1 ~= 0 then
        error(string_format("bad argument #%d (%s must be an integer)", index, name), level or 3)
    end
end

local function normalise_start(index, length)
    if index == nil then
        return 1
    end

    if index < 0 then
        index = length + index + 1
    end

    if index < 1 then
        return 1
    elseif index > length + 1 then
        return length + 1
    end

    return index
end

local function normalise_finish(index, length)
    if index == nil then
        return length
    end

    if index < 0 then
        index = length + index + 1
    end

    if index < 0 then
        return 0
    elseif index > length then
        return length
    end

    return index
end

local function is_valid(text)
    expect(1, text, "string")

    return utf8_len(text) ~= nil
end

local function len(text)
    expect(1, text, "string")

    local length, position = utf8_len(text)

    if not length then
        return nil, make_invalid_error(position)
    end

    return length
end

local function offset(text, n, i)
    expect(1, text, "string")
    expect(2, n, "number")
    expect(3, i, "number", "nil")

    check_integer(2, n, "offset")
    if i ~= nil then check_integer(3, i, "index") end

    check_valid(text)

    return utf8_offset(text, n, i)
end

local function sub(text, i, j)
    expect(1, text, "string")
    expect(2, i, "number", "nil")
    expect(3, j, "number", "nil")

    if i ~= nil then check_integer(2, i, "index") end
    if j ~= nil then check_integer(3, j, "index") end

    local length = check_valid(text)

    local start_index = normalise_start(i, length)
    local finish_index = normalise_finish(j, length)

    if start_index > finish_index or start_index > length then
        return ""
    end

    local byte_start = utf8_offset(text, start_index)
    local byte_finish

    if finish_index >= length then
        byte_finish = #text
    else
        byte_finish = utf8_offset(text, finish_index + 1) - 1
    end

    return string_sub(text, byte_start, byte_finish)
end

local function codepoints(text)
    expect(1, text, "string")

    check_valid(text)

    return utf8_codes(text)
end

return {
    is_valid = is_valid,
    len = len,
    offset = offset,
    sub = sub,
    codepoints = codepoints,
}
