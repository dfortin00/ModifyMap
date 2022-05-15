local _utils = {}

local cwd = (...) .. '.'

_utils.array  = require(cwd .. 'utils_array')
_utils.class  = require(cwd .. 'utils_class')
_utils.colors = require(cwd .. 'utils_colors')
_utils.love   = require(cwd .. 'utils_love')
_utils.math   = require(cwd .. 'utils_math')
_utils.string = require(cwd .. 'utils_string')
_utils.table  = require(cwd .. 'utils_table')
_utils.params = require(cwd .. 'utils_params')

--[[--------------------------]]

-- Shortcuts/Aliases
pprint = _utils.table.print

return _utils