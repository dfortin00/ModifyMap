
local mapdir                   = "assets/maps/plugins/modifymap/"

local batch_8x8_ortho          = mapdir .. 'batch_8x8_ortho__ts1_tc1'
local layers_8x8_ortho         = mapdir .. 'layers_8x8_ortho'
local layer_8x8_ortho_ts1_anim = mapdir .. 'layer_8x8_ortho_ts1_anim'
local simple_8x8_ortho_ts1     = mapdir .. 'simple_8x8_ortho_ts1'

local function _load_plugin(mapname)
    local map = MapFactory(mapname)
    return map:loadPlugin("ModifyMap"), map
end

TestModifyMapPlugin = {}

    function TestModifyMapPlugin:tearDown()
        MapFactory:clearCache()
    end

    function TestModifyMapPlugin:test_modify_map_plugin__class_name()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertEquals(plugin:type(), "ModifyMapPlugin")
    end

    function TestModifyMapPlugin:test_modify_map_plugin__type_of()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertIsTrue(plugin:typeOf("PluginBase"))
    end

    --[[ ModifyMapPlugin:init ]]

    function TestModifyMapPlugin:test_modify_map_plugin_init__next_entity_id()
        local _, map = _load_plugin(layers_8x8_ortho)
        lu.assertEquals(map.nextentityid, 1)
    end

    --[[ ModifyMapPlugin:addGroupLayer ]]

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__name()
        local plugin = _load_plugin(layers_8x8_ortho)
        local layer = plugin:addGroupLayer("new_group_layer", 1)
        lu.assertEquals(layer:getName(), "new_group_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__type()
        local plugin = _load_plugin(layers_8x8_ortho)
        local layer = plugin:addGroupLayer("new_group_layer", 1)
        lu.assertEquals(layer:type(), "GroupLayer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layerpath_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 1)
        lu.assertIsTrue(map.layerpaths[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layerpath_index__group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer("group_layer")
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)
        lu.assertIsTrue(map.layerpaths[grouplayer.layerindex + 1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layerpath_name()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 1)
        lu.assertIsTrue(map.layerpaths['new_group_layer'] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layerpath_name__group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer("group_layer")
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)
        lu.assertIsTrue(map.layerpaths['group_layer.new_group_layer'] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__default_values()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer")

        lu.assertItemsEquals(layer, {
            id             = map.nextlayerid - 1,
            layerindex     = #map.layerpaths,
            layerpath      = "new_group_layer",
            name           = "new_group_layer",
            visible        = true,
            x              = 0,
            y              = 0,
            opacity        = 1,
            offsetx        = 0,
            offsety        = 0,
            parallaxx      = 1,
            parallaxy      = 1,
            layertype      = "group",

            -- Stuff that can't be verified but needs to be included for luaunit assertion to work...
            map            = layer.map,
            properties     = layer.properties,
            layers         = layer.layers,

            render         = layer.render,
            update         = layer.update,
            addGroupLayer  = layer.addGroupLayer,
            addCustomLayer = layer.addCustomLayer,
            removeLayer    = layer.removeLayer,
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layer_inherits_parent_properties()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)

        lu.assertEquals(layer:getProperty('custom_map_property'), "test map string")
        lu.assertEquals(layer:getProperty('custom_group_property'), "test group string")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__next_layer_id()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        plugin:addGroupLayer("new_group_layer")
        lu.assertEquals(map.nextlayerid, #map.layerpaths + 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__number_child_layers()
        local plugin = _load_plugin(layers_8x8_ortho)
        local layer = plugin:addGroupLayer("new_group_layer")
        lu.assertEquals(#layer.layers, 0)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__first_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 1)
        lu.assertIsTrue(map.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__equals_last_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 4)
        lu.assertIsTrue(map.layers[4] == layer)
        lu.assertIsTrue(map.layers[5] == map:getLayer('group_layer'))
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__past_last_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 5)
        lu.assertIsTrue(map.layers[5] == layer)
        lu.assertIsTrue(map.layers[4] == map:getLayer('group_layer'))
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__index_less_than_one()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 0)
        lu.assertIsTrue(map.layers[#map.layers] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__negative_index_less_than_first_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", -999)
        lu.assertIsTrue(map.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__index_greater_than_top_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addGroupLayer("new_group_layer", 999)
        lu.assertIsTrue(map.layers[5] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__index_add_to_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)
        lu.assertIsTrue(grouplayer.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__group_layer_is_parent()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)
        lu.assertIsTrue(layer.parent == grouplayer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layers_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addGroupLayer("new_group_layer", 1, grouplayer)
        lu.assertNotIsNil(layer.layers)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__group__add_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local grouplayer = map:getLayer("group_layer")
        grouplayer:addGroupLayer("new_group_layer", 1)

        lu.assertIsTrue(grouplayer:hasLayer("new_group_layer"))
        lu.assertEquals(grouplayer.layers[1].name, "new_group_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__group__return_value()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local layer = map:getLayer("group_layer"):addGroupLayer("new_group_layer", 1)

        lu.assertEquals(layer.name, "new_group_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__param1_empty_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addGroupLayer : param #1 cannot be an empty string', plugin.addGroupLayer, plugin, '')
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__param1_empty_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addGroupLayer : param #1 cannot be an empty string', plugin.addGroupLayer, plugin, '')
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__param3_not_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addGroupLayer : param #3 must be a valid group layer',
            plugin.addGroupLayer, plugin, "group_layer", 1, {})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__param3_not_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = map:getLayer('tile_layer')
        lu.assertErrorMsgContains('addGroupLayer : param #3 must be a valid group layer',
            plugin.addGroupLayer, plugin, "group_layer", 1, layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_group_layer__layerpath_must_be_unique()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer("group_layer")
        lu.assertErrorMsgContains('init : duplicate layer paths are not supported : path=group_layer.child_tile_layer',
            plugin.addGroupLayer, plugin, "child_tile_layer", 1, grouplayer)
    end

    --[[ ModifyMapPlugin:addCustomLayer ]]

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__name()
        local plugin = _load_plugin(layers_8x8_ortho)
        local layer = plugin:addCustomLayer("custom_layer", 1)
        lu.assertEquals(layer:getName(), "custom_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__type()
        local plugin = _load_plugin(layers_8x8_ortho)
        local layer = plugin:addCustomLayer("custom_layer", 1)
        lu.assertEquals(layer:type(), "CustomLayer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__layerpath_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 1)
        lu.assertIsTrue(map.layerpaths[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__layerpath_name()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 1)
        lu.assertIsTrue(map.layerpaths['custom_layer'] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__default_values()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer('custom_layer')
        lu.assertItemsEquals(layer, {
            id         = map.nextlayerid - 1,
            layerindex = #map.layerpaths,
            layerpath  = "custom_layer",
            name       = "custom_layer",
            visible    = true,
            opacity    = 1,
            offsetx    = 0,
            offsety    = 0,
            parallaxx  = 1,
            parallaxy  = 1,
            layertype  = "custom",

            -- Stuff that can't be verified but needs to be included for luaunit assertion to work...
            entities   = layer.entities,
            map        = layer.map,
            properties = layer.properties,
            render     = layer.render,
            update     = layer.update
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__layer_inherits_parent_properties()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addCustomLayer("custom_layer", 1, grouplayer)

        lu.assertEquals(layer:getProperty('custom_map_property'), "test map string")
        lu.assertEquals(layer:getProperty('custom_group_property'), "test group string")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__next_layer_id()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        plugin:addCustomLayer("custom_layer")
        lu.assertEquals(map.nextlayerid, #map.layerpaths + 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__first_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 1)
        lu.assertIsTrue(map.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__equals_last_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 4)
        lu.assertIsTrue(map.layers[4] == layer)
        lu.assertIsTrue(map.layers[5] == map:getLayer('group_layer'))
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__past_last_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 5)
        lu.assertIsTrue(map.layers[5] == layer)
        lu.assertIsTrue(map.layers[4] == map:getLayer('group_layer'))
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__index_less_than_one()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 0)
        lu.assertIsTrue(map.layers[#map.layers] == layer)
    end

    function TestModifyMapPlugin.test_modify_map_plugin_add_custom_layer__negative_index_less_than_first_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", -999)
        lu.assertIsTrue(map.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__index_greater_than_top_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = plugin:addCustomLayer("custom_layer", 999)
        lu.assertIsTrue(map.layers[5] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__index_add_to_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addCustomLayer("custom_layer", 1, grouplayer)
        lu.assertIsTrue(grouplayer.layers[1] == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__group_layer_is_parent()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addCustomLayer("custom_layer", 1, grouplayer)
        lu.assertIsTrue(layer.parent == grouplayer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__no_layers_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local layer = plugin:addCustomLayer("custom_layer", 1, grouplayer)
        lu.assertIsNil(layer.layers)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__group__add_custom_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')

        grouplayer:addCustomLayer("new_custom_layer", 1)

        lu.assertIsTrue(grouplayer:hasLayer("new_custom_layer"))
        lu.assertEquals(grouplayer.layers[1].name, "new_custom_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__group__return_value()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local layer = map:getLayer("group_layer"):addCustomLayer("new_custom_layer", 1)

        lu.assertEquals(layer.name, "new_custom_layer")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__param1_empty_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addCustomLayer : param #1 cannot be an empty string', plugin.addCustomLayer, plugin, '')
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__param1_empty_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addCustomLayer : param #1 cannot be an empty string', plugin.addCustomLayer, plugin, '')
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__param3_not_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains('addCustomLayer : param #3 must be a valid group layer',
            plugin.addCustomLayer, plugin, "custom_layer", 1, {})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__param3_not_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local layer = map:getLayer('tile_layer')
        lu.assertErrorMsgContains('addCustomLayer : param #3 must be a valid group layer',
            plugin.addCustomLayer, plugin, "custom_layer", 1, layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_add_custom_layer__layerpath_must_be_unique()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer("group_layer")
        lu.assertErrorMsgContains('init : duplicate layer paths are not supported : path=group_layer.child_tile_layer',
            plugin.addCustomLayer, plugin, "child_tile_layer", 1, grouplayer)
    end

    --[[ ModifyMapPlugin:removeLayer ]]

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__layer_removed_from_root()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local numlayers = #map.layers
        plugin:removeLayer(1)
        lu.assertEquals(#map.layers, numlayers - 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__layer_removed_from_group()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local grouplayer = map:getLayer('group_layer')
        local numlayers = #grouplayer.layers
        plugin:removeLayer(1, grouplayer)
        lu.assertEquals(#grouplayer.layers, numlayers - 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_object_layer()
        local plugin = _load_plugin(layer_8x8_ortho_ts1_anim)
        local map = plugin:getMap()

        local objectids = {}
        for _, object in ipairs(map:getLayer("object_layer2").objects) do
            table.insert(objectids, object.id)
        end

        plugin:removeLayer("object_layer2")

        for _, id in ipairs(objectids) do
            if map.objects.layers[id] then
                lu.fail("object id=" .. id .. " not removed from map object lookup table")
            end
        end
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_object_layer__keep_other_objects()
        local plugin = _load_plugin(layer_8x8_ortho_ts1_anim)
        local map = plugin:getMap()

        local objectids = {}
        for _, object in ipairs(map:getLayer("object_layer1").objects) do
            table.insert(objectids, object.id)
        end

        plugin:removeLayer("object_layer2")

        for _, id in ipairs(objectids) do
            if not map.objects.layers[id] then
                lu.fail("object id=" .. id .. " was not supposed to be removed from map object lookup table")
            end
        end
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_tile_animations()
        local plugin = _load_plugin(layer_8x8_ortho_ts1_anim)
        local map = plugin:getMap()
        plugin:removeLayer("tile_layer1")
        lu.assertIsNil(map.animations["tile_layer1"])
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_tile_animations__keep_other_animations()
        local plugin = _load_plugin(layer_8x8_ortho_ts1_anim)
        local map = plugin:getMap()
        plugin:removeLayer("tile_layer1")
        lu.assertNotIsNil(map.animations["tile_layer2"])
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_group_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()
        local numlayers = #map.layers
        plugin:removeLayer('group_layer')
        lu.assertEquals(#map.layers, numlayers - 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_group_layer__all_children_indices_removed()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local indices = {
            map:getLayer('group_layer.child_group_layer').layerindex,
            map:getLayer('group_layer.child_group_layer.sub_layer').layerindex,
            map:getLayer('group_layer.child_image_layer').layerindex,
            map:getLayer('group_layer.child_object_layer').layerindex,
            map:getLayer('group_layer.child_tile_layer').layerindex,
        }

        plugin:removeLayer('group_layer')

        lu.assertIsNil(map.layerpaths[indices[1]])
        lu.assertIsNil(map.layerpaths[indices[2]])
        lu.assertIsNil(map.layerpaths[indices[3]])
        lu.assertIsNil(map.layerpaths[indices[4]])
        lu.assertIsNil(map.layerpaths[indices[5]])
    end

    function TestModifyMapPlugin:test_modify_map_plugin_remove_layer__remove_group_layer__all_children_layerpaths_removed()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        plugin:removeLayer('group_layer')

        lu.assertIsNil(map.layerpaths['group_layer.child_group_layer'])
        lu.assertIsNil(map.layerpaths['group_layer.child_group_layer.sub_layer'])
        lu.assertIsNil(map.layerpaths['group_layer.child_image_layer'])
        lu.assertIsNil(map.layerpaths['group_layer.child_object_layer'])
        lu.assertIsNil(map.layerpaths['group_layer.child_tile_layer'])
    end

    function TestModifyMapPlugin:test_mapmatic_group_layer_remove_child_layer__by_index()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local grouplayer = map:getLayer("group_layer")
        grouplayer:removeLayer(1)

        lu.assertEquals(grouplayer:getNumChildren(), 4)
        lu.assertIsFalse(grouplayer:hasLayer("layer.with.dots"))
    end

    function TestModifyMapPlugin:test_mapmatic_group_layer_remove_child_layer__by_name()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local grouplayer = map:getLayer("group_layer")
        grouplayer:removeLayer("child_object_layer")

        lu.assertEquals(grouplayer:getNumChildren(), 4)
        lu.assertIsFalse(grouplayer:hasLayer("child_object_layer"))
    end

    --[[ ModifyMapPlugin:createMapObject ]]

    local function _create_map_object(shape, gid)
        return {
            shape      = shape,
            name       = "test_object",
            gid        = gid,
            x          = 10,
            y          = 20,
            width      = 30,
            height     = 40,
            rotation   = 0,
            visible    = true,
            properties = {testprop="test prop value"}
        }
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__type()
        local plugin = _load_plugin(layers_8x8_ortho)
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object)

        lu.assertEquals(object:type(), "MapObject")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__id()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local id = map.nextobjectid
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object)

        lu.assertEquals(object:getId(), id)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__nextid()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local id = map.nextobjectid
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object)

        lu.assertEquals(map.nextobjectid, id + 1)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__gid()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local object = _create_map_object("rectangle", 1)
        object = plugin:createMapObject(object)

        lu.assertNotIsNil(object:getTile())
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__gid__shape()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local object = _create_map_object("ellipse", 1)
        object = plugin:createMapObject(object)

        lu.assertEquals(object:getShape(), "tileobject")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__detached()
        local plugin = _load_plugin(layers_8x8_ortho)
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object)

        lu.assertIsNil(object:getOwner())
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local layer = map:getLayer("tile_layer")
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, layer)

        lu.assertIsTrue(object:getOwner() == layer)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__tile_instance()
        local plugin = _load_plugin(batch_8x8_ortho)
        local map = plugin:getMap()

        local layer = map:getLayer("ts_layer__fit")
        local instance = layer:getTileInstance(0, 0)
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, instance)

        lu.assertIsTrue(object:getOwner() == instance)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__map_entity()
        local plugin = _load_plugin(batch_8x8_ortho)

        local entity = MapEntity()
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, entity)

        lu.assertIsTrue(object:getOwner() == entity)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__object_layer()
        local plugin = _load_plugin(layers_8x8_ortho)
        local map = plugin:getMap()

        local objectlayer = map:getLayer("object_layer")
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, objectlayer)

        local objects = objectlayer:getObjects()
        lu.assertIsTrue(objects[#objects] == object)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__map_objects_table__layers()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local map = plugin:getMap()

        local objectlayer = map:getLayer("entities")
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, objectlayer)

        local objects = map.objects.layers
        lu.assertIsTrue(objects[#objects] == object)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__tile()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local map = plugin:getMap()

        local tile = map:getTile(1)
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, tile)

        local objects = tile:getObjects()
        lu.assertIsTrue(objects[#objects] == object)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__map_objects_table__tiles()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local map = plugin:getMap()

        local tile = map:getTile(1)
        local object = _create_map_object("rectangle")
        object = plugin:createMapObject(object, tile)

        local objects = map.objects.tiles
        lu.assertIsTrue(objects[#objects] == object)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__polygon__vertex_table_can_be_empty()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local map = plugin:getMap()

        local tile = map:getTile(1)

        local object = _create_map_object("polygon")
        object.polygon = {}

        object = plugin:createMapObject(object, tile)

        lu.assertEquals(object:type(), "MapObject")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__polyline__vertex_table_can_be_empty()
        local plugin = _load_plugin(simple_8x8_ortho_ts1)
        local map = plugin:getMap()

        local tile = map:getTile(1)

        local object = _create_map_object("polyline")
        object.polyline = {}

        object = plugin:createMapObject(object, tile)

        lu.assertEquals(object:type(), "MapObject")
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__param1_is_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: param #1 is not a table type : actual (boolean)",
            plugin.createMapObject, plugin, true)
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__shape__is_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.shape' is not a string : actual (boolean)",
            plugin.createMapObject, plugin, {shape=true})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__shape__any_of()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.shape' does not match any of the expected values : expected (rectangle,ellipse,polygon,polyline) : actual (true)",
            plugin.createMapObject, plugin, {shape="true"})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__name__is_string()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.name' is not a string : actual (boolean)",
            plugin.createMapObject, plugin, {shape="rectangle", name=true})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__gid__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.gid' is not a number type : actual (boolean)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", gid=true})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__gid__is_greater_than()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.gid' must be greater than the expected value : expected (0) : actual (0)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", gid=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__x__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.x' is not a number type : actual (boolean)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=true})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__y__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.y' is not a number type : actual (nil)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__width__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.width' is not a number type : actual (nil)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=0, y=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__height__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.height' is not a number type : actual (nil)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=0, y=0, width=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__rotation__is_number()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.rotation' is not a number type : actual (nil)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=0, y=0, width=0, height=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__visible__is_boolean()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.visible' is not a boolean type : actual (nil)",
            plugin.createMapObject, plugin, {shape="rectangle", name="", x=0, y=0, width=0, height=0, rotation=0})
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__properties__is_type()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.properties' is an invalid type : expected (table,MapProperties) : actual (nil)",
            plugin.createMapObject, plugin, {
                shape="rectangle", name="", x=0, y=0, width=0, height=0, rotation=0, visible=true
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polygon__missing_polygon_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object' missing expected hash key(s) : expected (polygon)",
            plugin.createMapObject, plugin, {
                shape="polygon", name="", x=0, y=0, width=0, height=0, rotation=0, visible=true, properties={}
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polygon__not_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polygon' is not a table type : actual (number)",
            plugin.createMapObject, plugin, {
                shape="polygon", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polygon=0
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polygon__vertices__not_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polygon.vertex#1' is not a table type : actual (number)",
            plugin.createMapObject, plugin, {
                shape="polygon", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polygon={0}
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polygon__vertices__has_keys()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polygon.vertex#1' missing expected hash key(s) : expected (x,y)",
            plugin.createMapObject, plugin, {
                shape="polygon", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polygon={{}}
        })
    end


    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polyline__missing_polyline_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object' missing expected hash key(s) : expected (polyline)",
            plugin.createMapObject, plugin, {
                shape="polyline", name="", x=0, y=0, width=0, height=0, rotation=0, visible=true, properties={}
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polyline__not_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polyline' is not a table type : actual (number)",
            plugin.createMapObject, plugin, {
                shape="polyline", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polyline=0
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polyline__vertices__not_table()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polyline.vertex#1' is not a table type : actual (number)",
            plugin.createMapObject, plugin, {
                shape="polyline", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polyline={0}
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__object__polyline__vertices__has_keys()
        local plugin = _load_plugin(layers_8x8_ortho)
        lu.assertErrorMsgContains("createMapObject: 'object.polyline.vertex#1' missing expected hash key(s) : expected (x,y)",
            plugin.createMapObject, plugin, {
                shape="polyline", name="", x=0, y=0, width=0, height=0, rotation=0,
                visible=true, properties={}, polyline={{}}
        })
    end

    function TestModifyMapPlugin:test_modify_map_plugin_create_map_object__owner__not_layer_or_tile()
        local plugin = _load_plugin(layers_8x8_ortho)
        local object = _create_map_object("rectangle")
        lu.assertErrorMsgContains("createMapObject: param #2 is an invalid type : expected (Layer,Tile,TileInstance,MapEntity) : actual (table)",
            plugin.createMapObject, plugin, object, {})
    end










































