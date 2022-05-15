local mapdir = 'assets/maps/plugins/ModifyMap/'
local layers_8x8_ortho = mapdir .. 'layers_8x8_ortho'

TestMapMaticMap = {}

    function TestMapMaticMap:tearDown()
        MapFactory:clearCache()
    end

    function TestMapMaticMap:test_mapmatic_map_get_layers__grouped__custom_layer()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        plugin:addCustomLayer("custom_layer_1")
        plugin:addCustomLayer("custom_layer_1", 1, group)

        local list = map:getLayers(true)
        lu.assertNotIsNil(list.customs)
    end

    function TestMapMaticMap:test_mapmatic_map_get_layers__grouped__group_layer__number()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        plugin:addCustomLayer("custom_layer_1")
        plugin:addCustomLayer("custom_layer_2", 1, group)

        local list = map:getLayers(true)
        lu.assertEquals(#list.customs, 2)
    end

    function TestMapMaticMap:test_mapmatic_map_get_layers__grouped__group_layer__order()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer1 = plugin:addCustomLayer("custom_layer_1", 1)
        local layer2 = plugin:addCustomLayer("custom_layer_2", 1, group)

        local list = map:getLayers(true)

        lu.assertEquals(list.customs, {layer1, layer2})
    end







































