--[[
    An API script for reading the contents of text files over a variety of protocols
    Available at: https://github.com/CogentRedTester/mpv-read-file
]]--

local mp = require "mp"
local utils = require "mp.utils"
local opts = require "mp.options"

local o = {
    wget_flags = ""
}

opts.read_options(o, "read_file")

local rf = {}

local function get_protocol(uri)
    return uri:match("^(%a%w*)://")
end

local function get_local(file)
    return io.open(file, "r")
end

local function get_wget(file)
    return io.popen( ("wget -q -O - %q %s"):format(file, o.wget_flags), "r" )
end

--tracks what functions should be used for specific protocols
local protocols = {
    file = get_local,
    http = get_wget,
    https = get_wget,
}

--returns a file handler for the given file
function rf.get_file_handler(file)
    local path = file
    local protocol = get_protocol(file)
    local get_handler = nil
    if not protocol then
        path = utils.join_path(mp.get_property("working-directory", ""), file)
        get_handler = get_local
    else
        get_handler = protocols[protocol] or get_wget
    end

    return get_handler(path)
end

--reads the contents of the file to a string and returns the result
--if the file could not be read then return nil
function rf.read_file(file)
    local handler = rf.get_file_handler(file)
    if not handler then return nil end

    local contents = handler:read("*a")
    handler:close()
    return contents
end

--returns an iterator for the lines in the file, which closes the file once EOF is reached
--this is the same as using io.lines()
function rf.lines(file)
    local handler = rf.get_file_handler(file)
    if not handler then return nil end

    return function()
        local line = handler:read("*l")
        if not line then handler:close() end
        return line
    end
end

return rf