
--[[
    Usage: love <path to this main.lua file> [--audio] [luaunit command line parameters]
         e.g. > love . -v --pattern TestUtils
    Note: If no luaunit command line parameters are supplied after the Love2D path, the
          default is to run all test cases with --quiet mode turned on.

    Flags:

    --audio : execute audio-based test cases when included, or skip them if omitted
]]

package.path = "../?.lua;../?/init.lua;" .. package.path

lu = require('lib.luaunit')

--==================
-- TEST DEPENDENCIES
--==================
require('dependencies')
local utils = require("lib.mapmatic.utils")

--=================
-- GLOBAL CONSTANTS
--=================
VIRTUAL_WIDTH = 256
VIRTUAL_HEIGHT = 224
AUDIO_TEST = false

-- Get command line arguments for luaunit.
-- arg[1] is always the path for the LOVE2D main.lua file, so get everything after that.
local temp = {}
for k = 2, #arg do
    if (arg[k] == '--audio') then
        AUDIO_TEST = true
    else
        temp[#temp + 1] = arg[k]
    end
end

-- Require all test files in the 'tests' directory structure that start with the prefix 'test_'.
utils.love.requirePath('tests', "^test_.*%.lua$")

-- Start all output on a fresh new line.
print()

-- If there are no extra parameters on the command line after the LOVE2D path,
-- the default is to run all tests in quiet mode.
if #temp == 0 then
    lu.LuaUnit.run("-q")
else
    lu.LuaUnit.run(unpack(temp))
end

-- Let LOVE do its cleanup.
love.event.quit()

