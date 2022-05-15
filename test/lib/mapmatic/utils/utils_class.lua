
local _class = {}

--[[ Determines if a table is a class generated from the lib.class library. ]]
function _class.isClass(class)
    return (
        (type(class) == 'table') and
        (class.typeOf) and
        (type(class.typeOf) == 'function') and
        (class:typeOf('Class') == true)
    ) == true
end

--[[ Helper function that walks up a class heirarchy and returns the parent base class.]]
function _class.getBaseClass(class, className)
    assert(_class.isClass(class), "<utils>.class.getBaseClass: param #1 must be a valid class")

    local baseClass = class
    while(not (baseClass:type() == className)) do
        if not baseClass.__includes then return end
        baseClass = baseClass.__includes
    end

    return baseClass
end

--[[ Safe typeOf() method for classes. ]]
function _class.typeOf(class, className)
    return class and _class.isClass(class) and class:typeOf(className)
end

return _class