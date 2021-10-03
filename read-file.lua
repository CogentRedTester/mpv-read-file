--[[
    An API script for reading the contents of text files over a variety of protocols
    Available at: https://github.com/CogentRedTester/mpv-read-file
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"
local opts = require "mp.options"

local o = {
    wget_flags = ""
}

opts.read_options(o, "read_file")

local rf = {}
local temp_files = {}

--this platform test was taken from mpv's console.lua
local PLATFORM_WINDOWS = mp.get_property_native('options/vo-mmcss-profile', o) ~= o

local function execute(args)
    local cmd = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })

    if (cmd.status == 0) then
        return cmd.stdout
    else
        msg.warn(table.concat(args, ' '))
        msg.warn("command exitted with status code:", cmd.status)
        msg.error(cmd.stderr)
        return nil
    end
end

--gets the path of a temporary file that can be used by the script
local function get_temp_file_name()
    local file = os.tmpname()
    if not PLATFORM_WINDOWS then return file
    else return mp.command_native({"expand-path", "~/AppData/Local/Temp"}) .. file end
end

--creates a new temporary file with the given contents, and returns a file read handle for this file
local function get_temp_file_handler(contents)
    local filename = get_temp_file_name()
    table.insert(temp_files, filename)

    local tmpfile = io.open(filename, "w")
    tmpfile:write(contents)
    tmpfile:close()

    return io.open(filename, "r")
end
local function get_protocol(uri)
    return uri:match("^(%a%w*)://")
end

local function get_local(file)
    return io.open(file, "r")
end

local function get_wget(file)
    return execute({"wget", "-O", "-", file, o.wget_flags})
end

--tracks what functions should be used for specific protocols
local protocols = {
    file = get_local,
    http = get_wget,
    https = get_wget,
}

--uses the protocol of the file uri to determine what get function to run, and converts the result into
--either a string or a file handle, depending on the second argument. If as_string is nil then return whichever
--type the get function defaults to
local function get_file(file, as_string)
    local path = file
    local protocol = get_protocol(file)
    local get_method = nil

    --determines what utility to use to read the file
    if not protocol then
        path = utils.join_path(mp.get_property("working-directory", ""), file)
        get_method = get_local
    else
        get_method = protocols[protocol] or get_wget
    end

    local contents = get_method(path)
    if not contents or as_string == nil then return nil end

    --converts the result of the get function into the correct output type - either a string or a file handle
    if as_string and io.type(contents) then
        local tmp = contents
        contents = tmp:read("*a")
        tmp:close()
    elseif not as_string and not io.type(contents) then
        contents = get_temp_file_handler(contents)
    end

    return contents
end

--returns a file handler for the given file
function rf.get_file_handler(file)
    return get_file(file, false)
end

--reads the contents of the file to a string and returns the result
--if the file could not be read then return nil
function rf.read_file(file)
    return get_file(file, true)
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