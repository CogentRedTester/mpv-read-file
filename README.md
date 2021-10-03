# mpv-read-file

The purpose of this script is to provide a universal interface for reading text files in lua
scripts for mpv player. This extends the inbuilt lua io commands by also supporting network
files with the `wget` comandline utility.

This API is still extremely new, so there may be breaking changes in the future.

## Installation for users

**If you've been directed here by another script that requires this API follow these instructions unless told otherwise.**

Place [read-file.lua](read-file.lua) inside the `~~/script-modules/` directory.
Create the directory if it does not exist. `~~/` represents the mpv config directory.

### Advanced

What is important is that `read-file.lua` needs to be in one of the lua package paths; scripts that use this API are recommended to use
`~~/script-modules/`, but you can set any directory using the `LUA_PATH` environment variable.

## Installation for developers

This API is designed to be loaded as a module using `require "read-file"`.
Developers are encouranged to add the `~~/script-modules/` directory to Lua's `package.path`
variable and encourage users to save the API file in that location. The following two lines of code
are recommended:

```lua
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"})..package.path
local rf = require "read-file
```

## API Functions

### `read_file(uri)`

This function takes a uri and returns a string consisting of the entire contents of the file.
This uri can be a relative path for a local file, as well as an absolute path for a global or network
file.

If the given file cannot be read the function returns `nil` and an error message is returned as a second return value.

If the given file is not a text file then the behaviour is undefined.

### `get_file_handler(uri)`

This function returns a lua read-only file handle, as returned by `io.open`.
The user will then be responsible for closing the file.
If the uri is for a network file then the script may create a temporary local file and provide a file
handle for that local file. All temporary files are removed during mpv's shutdown.

If the uri could not be opened or written to the temporary file, then the function returns `nil`, and
an error message as the second return value

If the given file is not a text file then the behaviour is undefined.

### `lines(uri)`

Returns an iterator that returns each line of the given file. For use with `for` loops.
Any file handlers are closed when the loop reaches EOF, as with `io.lines()`.

If the given file is not a text file then the behaviour is undefined.

## Configuration

Available options for the API are inside the [read_file.conf](read_file.conf) file.
These options currently apply to all scripts that use read_file, though this may be changed in the future.
