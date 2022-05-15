
local mapdir = 'assets/maps/plugins/modifymap/'

local layers_8x8_ortho     = mapdir .. 'layers_8x8_ortho2'
local simple_8x8_ortho_tc1 = mapdir .. 'simple_8x8_ortho_tc1'

local function _custom_layer(name)
    name = name or "custom_layer"

    local map = MapFactory(layers_8x8_ortho)
    local plugin = map:loadPlugin("ModifyMap")
    local layer = plugin:addCustomLayer(name)

    return layer, map
end

TestModifyMapCustomLayer = {}

    function TestModifyMapCustomLayer:tearDown()
        MapFactory:clearCache()
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer__class_name()
        local layer = _custom_layer()
        lu.assertEquals(layer:type(), "CustomLayer")
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer__type_of()
        local layer = _custom_layer()
        lu.assertIsTrue(layer:typeOf("Layer"))
    end

    --[[ CustomLayer:init ]]

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_init__entities()
        local layer = _custom_layer()
        lu.assertNotIsNil(layer.entities)
    end

    --[[ CustomLayer:getEntity ]]

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_get_entity__by_index()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertIsTrue(layer:getEntity(1) == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_get_entity__by_name()
        local layer = _custom_layer()

        local entity = MapEntity({name="Test Entity 2"})
        layer:addEntity(MapEntity({name="Test Entity 1"}))
        layer:addEntity(entity)

        lu.assertIsTrue(layer:getEntity("Test Entity 2") == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_get_entity__not_found()
        local layer = _custom_layer()
        layer:addEntity(MapEntity({name="Test Entity"}))
        lu.assertIsNil(layer:getEntity("Not an Entity"))
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_get_entity__param1_not_string_or_number()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("getEntity : param #1 must be either a string or an integer : id=true",
            layer.getEntity, layer, true)
    end

    --[[ CustomLayer:addEntity ]]

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__default_index_empty_list()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertIsTrue(layer.entities[1] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__default_index_end_of_list()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity)

        lu.assertIsTrue(layer.entities[2] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__with_index()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity, 1)

        lu.assertIsTrue(layer.entities[1] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__index_less_than_one()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity, 0)

        lu.assertIsTrue(layer.entities[#layer.entities] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__negative_index_less_than_first_index()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity, -999)

        lu.assertIsTrue(layer.entities[1] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__index_greater_than_num_entities()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(MapEntity())
        layer:addEntity(entity, 5)

        lu.assertIsTrue(layer.entities[3] == entity)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__entity_index()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity)

        lu.assertEquals(entity.entityindex, 2)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__entity_index_recalculated()
        local layer = _custom_layer()

        local entity1 = MapEntity()
        local entity2 = MapEntity()

        layer:addEntity(entity1)
        layer:addEntity(entity2, 1)

        lu.assertEquals(entity1.entityindex, 2)
        lu.assertEquals(entity2.entityindex, 1)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__entity_owner()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertIsTrue(entity.owner == layer)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__next_entity_id()
        local layer, map = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertEquals(entity.id, 1)
        lu.assertEquals(map.nextentityid, 2)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_add_entity__param1_not_map_entity()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("addEntity : param #1 must be a MapEntity type", layer.addEntity, layer, {})
    end

    --[[ CustomLayer:removeEntity ]]

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__by_index()
        local layer = _custom_layer()

        layer:addEntity(MapEntity())
        layer:removeEntity(1)

        lu.assertEquals(#layer.entities, 0)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__by_index__returns_entity()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(entity)
        local ret = layer:removeEntity(1)

        lu.assertIsTrue(entity == ret)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__by_name()
        local layer = _custom_layer()

        layer:addEntity(MapEntity({name="TestEntity"}))
        layer:removeEntity("TestEntity")

        lu.assertEquals(#layer.entities, 0)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__by_name__returns_entity()
        local layer = _custom_layer()

        local entity = MapEntity({name="TestEntity"})
        layer:addEntity(entity)
        local ret = layer:removeEntity("TestEntity")

        lu.assertIsTrue(entity == ret)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__by_entity()
        local layer = _custom_layer()

        local entity = MapEntity()
        layer:addEntity(MapEntity())
        layer:addEntity(entity)
        layer:addEntity(MapEntity())

        local ret = layer:removeEntity(entity)

        lu.assertEquals(#layer.entities, 2)
        lu.assertIsTrue(entity == ret)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__ids_recalculated__by_index()
        local layer = _custom_layer()

        local entities = {MapEntity(), MapEntity(), MapEntity()}
        layer:addEntity(entities[1])
        layer:addEntity(entities[2])
        layer:addEntity(entities[3])

        layer:removeEntity(2)

        lu.assertEquals(entities[1].entityindex, 1)
        lu.assertEquals(entities[3].entityindex, 2)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__ids_recalculated__by_name()
        local layer = _custom_layer()

        local entities = {MapEntity(), MapEntity({name="TestEntity"}), MapEntity()}
        layer:addEntity(entities[1])
        layer:addEntity(entities[2])
        layer:addEntity(entities[3])

        layer:removeEntity("TestEntity")

        lu.assertEquals(entities[1].entityindex, 1)
        lu.assertEquals(entities[3].entityindex, 2)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__param1_not_entity()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("removeEntity : param #1 must be either a string, integer or a MapEntity object",
            layer.removeEntity, layer, {})
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__param1_not_string_or_number()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("removeEntity : param #1 must be either a string, integer or a MapEntity object : id=true",
            layer.removeEntity, layer, true)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_remove_entity__param1_name_not_found()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("removeEntity : no entity with provided id found on custom layer",
            layer.removeEntity, layer, "not_an_entity")
    end

    --[[ CustomLayer:sortEntities ]]

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_sort_entities__default_function()
        local layer = _custom_layer()

        local entities = {
            MapEntity{name="Entity1", y=30},
            MapEntity{name="Entity2", y=10},
            MapEntity{name="Entity3", y=20},
        }

        layer:addEntity(entities[1])
        layer:addEntity(entities[2])
        layer:addEntity(entities[3])

        layer:sortEntities()

        lu.assertEquals(layer.entities[1].name, "Entity2")
        lu.assertEquals(layer.entities[2].name, "Entity3")
        lu.assertEquals(layer.entities[3].name, "Entity1")
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_sort_entities__sort_function()
        local layer = _custom_layer()

        local entities = {
            MapEntity{name="Entity1", y=30},
            MapEntity{name="Entity2", y=10},
            MapEntity{name="Entity3", y=20},
        }

        layer:addEntity(entities[1])
        layer:addEntity(entities[2])
        layer:addEntity(entities[3])

        layer:sortEntities(function(a, b) return a.y > b.y end)

        lu.assertEquals(layer.entities[1].name, "Entity1")
        lu.assertEquals(layer.entities[2].name, "Entity3")
        lu.assertEquals(layer.entities[3].name, "Entity2")
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_sort_entities__indices_recalculated()
        local layer = _custom_layer()

        local entities = {
            MapEntity{name="Entity1", y=30},
            MapEntity{name="Entity2", y=10},
            MapEntity{name="Entity3", y=20},
        }

        layer:addEntity(entities[1])
        layer:addEntity(entities[2])
        layer:addEntity(entities[3])

        layer:sortEntities()

        lu.assertEquals(entities[1].entityindex, 3)
        lu.assertEquals(entities[2].entityindex, 1)
        lu.assertEquals(entities[3].entityindex, 2)
    end

    function TestModifyMapCustomLayer:test_modify_map_custom_layer_sort_entities__indices_recalculated()
        local layer = _custom_layer()
        lu.assertErrorMsgContains("sortEntities : param #1 must be a sorting function that returns a boolean value",
            layer.sortEntities, layer, {})
    end

    --============================
    -- Layer
    --============================

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_map()
        local layer, map = _custom_layer()
        lu.assertIsTrue(layer:getMap() == map)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_child__true()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertIsTrue(layer:isChild())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_child__false()
        local layer = _custom_layer()
        lu.assertIsFalse(layer:isChild())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__has_parent__true()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertIsTrue(layer:hasParent())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__has_parent__false()
        local layer = _custom_layer()
        lu.assertIsFalse(layer:hasParent())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_parent__false()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertIsFalse(layer:isParent())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__has_children__false()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertIsFalse(layer:hasChildren())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_parent()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertIsTrue(layer:getParent() == group)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_layer_type()
        local layer = _custom_layer()
        lu.assertEquals(layer:getLayerType(), "custom")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_layer_path()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 1, group)

        lu.assertEquals(layer:getLayerPath(), "group_layer.child_custom_layer")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_index()
        local layer = _custom_layer()
        lu.assertEquals(layer:getIndex(), 12)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_group_index()
        local layer, map = _custom_layer()
        lu.assertEquals(layer:getGroupIndex(), #map.layers)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_group_index__child()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        lu.assertEquals(layer:getGroupIndex(), 3)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_parallax()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallax(4, 5)

        lu.assertEquals({layer:getParallax()}, {8, 15})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_parallax_x()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallax(4, 5)

        lu.assertEquals(layer:getParallaxX(), 8)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_parallax_y()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallax(4, 5)

        lu.assertEquals(layer:getParallaxY(), 15)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__set_parallax()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallax(0.5, 2)

        -- parent: 2, 3 ; layer: 0.5, 2
        lu.assertEquals({layer:getParallax()}, {1, 6})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__set_parallax_x()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallaxX(5)

        -- parent: 2, 3 ; layer: 5, 1
        lu.assertEquals({layer:getParallax()}, {10, 3})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__set_parallax_y()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        layer:setParallaxY(2)

        -- parent: 2, 3 ; layer: 1, 2
        lu.assertEquals({layer:getParallax()}, {2, 6})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_visible__true()
        local layer = _custom_layer()
        lu.assertIsTrue(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_visible__false()
        local layer = _custom_layer()
        layer.visible = false
        lu.assertIsFalse(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_visible__parent_visible()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer")
        local layer = plugin:addCustomLayer("child_custom_layer", 3, group)

        lu.assertIsTrue(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__is_visible__parent_not_visible()
        local map = MapFactory(simple_8x8_ortho_tc1)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer.child_group_layer")
        local layer = plugin:addCustomLayer("child_child_custom_layer", 3, group)

        lu.assertIsFalse(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_offset_x()
        local layer = _custom_layer()
        layer:setOffsets(10, 20)
        lu.assertEquals(layer:getOffsetX(), 10)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_offset_y()
        local layer = _custom_layer()
        layer:setOffsets(10, 20)
        lu.assertEquals(layer:getOffsetY(), 20)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__layer__get_opacity()
        local map = MapFactory(simple_8x8_ortho_tc1)
        local plugin = map:loadPlugin("ModifyMap")

        local group = map:getLayer("group_layer.child_group_layer")
        local layer = plugin:addCustomLayer("child_child_custom_layer", 3, group)

        layer:setOpacity(0.2)

        lu.assertAlmostEquals(layer:getOpacity(), 0.04, 0.00001)
    end

    --============================
    -- TObject
    --============================

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_id()
        local layer, map = _custom_layer()
        lu.assertEquals(layer:getId(), map.nextlayerid - 1)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_name()
        local layer = _custom_layer()
        lu.assertEquals(layer:getName(), "custom_layer")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_name()
        local layer = _custom_layer()
        layer:setName("new_layer_name")
        lu.assertEquals(layer:getName(), "new_layer_name")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_position()
        local layer = _custom_layer()
        lu.assertEquals({layer:getPosition()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_x()
        local layer = _custom_layer()
        lu.assertEquals(layer:getX(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_y()
        local layer = _custom_layer()
        lu.assertEquals(layer:getY(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_position()
        local layer = _custom_layer()
        layer:setPosition(10, 20)
        lu.assertEquals({layer:getPosition()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_x()
        local layer = _custom_layer()
        layer:setX(10)
        lu.assertEquals({layer:getPosition()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_y()
        local layer = _custom_layer()
        layer:setY(10)
        lu.assertEquals({layer:getPosition()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__move_by()
        local layer = _custom_layer()
        layer:moveBy(10, 20)
        lu.assertEquals({layer:getPosition()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_rotation()
        local layer = _custom_layer()
        lu.assertEquals(layer:getRotation(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_rotation()
        local layer = _custom_layer()
        layer:setRotation(20)
        lu.assertEquals(layer:getRotation(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__rotate_by()
        local layer = _custom_layer()
        layer:rotateBy(20)
        lu.assertEquals(layer:getRotation(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_scale()
        local layer = _custom_layer()
        lu.assertEquals({layer:getScale()}, {1, 1})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_scale_x()
        local layer = _custom_layer()
        lu.assertEquals(layer:getScaleX(), 1)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_scale_y()
        local layer = _custom_layer()
        lu.assertEquals(layer:getScaleY(), 1)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_scale()
        local layer = _custom_layer()
        layer:setScale(3)
        lu.assertEquals({layer:getScale()}, {1, 1})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_scale_x()
        local layer = _custom_layer()
        layer:setScaleX(3)
        lu.assertEquals({layer:getScale()}, {1, 1})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_scale_y()
        local layer = _custom_layer()
        layer:setScaleY(3)
        lu.assertEquals({layer:getScale()}, {1, 1})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__scale_by()
        local layer = _custom_layer()
        layer:scaleBy(3, 5)

        lu.assertEquals({layer:getScale()}, {1, 1})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_origin()
        local layer = _custom_layer()
        lu.assertEquals({layer:getOrigin()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_origin_x()
        local layer = _custom_layer()
        lu.assertEquals(layer:getOriginX(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_origin_y()
        local layer = _custom_layer()
        lu.assertEquals(layer:getOriginY(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_origin()
        local layer = _custom_layer()
        layer:setOrigin(10, 20)
        lu.assertEquals({layer:getOrigin()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_origin_x()
        local layer = _custom_layer()
        layer:setOriginX(10)
        lu.assertEquals({layer:getOrigin()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_origin_y()
        local layer = _custom_layer()
        layer:setOriginY(10)
        lu.assertEquals({layer:getOrigin()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__draw_coords()
        local layer = _custom_layer()
        layer:setOffsets(10, 20)
        lu.assertEquals({layer:getDrawCoords()}, {10, 20, 0, 1, 1, 0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_dimensions()
        local layer = _custom_layer()
        lu.assertEquals({layer:getDimensions()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_width()
        local layer = _custom_layer()
        lu.assertEquals(layer:getWidth(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_height()
        local layer = _custom_layer()
        lu.assertEquals(layer:getHeight(), 0)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_rect()
        local layer = _custom_layer()
        lu.assertEquals({layer:getRect()}, {0, 0, 0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_offsets()
        local layer = _custom_layer()
        lu.assertEquals({layer:getOffsets()}, {0, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_offsets()
        local layer = _custom_layer()
        layer:setOffsets(40, 50)
        lu.assertEquals({layer:getOffsets()}, {40, 50})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_offset_x()
        local layer = _custom_layer()
        layer:setOffsetX(40)
        lu.assertEquals({layer:getOffsets()}, {40, 0})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_offset_y()
        local layer = _custom_layer()
        layer:setOffsetY(40)
        lu.assertEquals({layer:getOffsets()}, {0, 40})
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_visibility__true()
        local layer = _custom_layer()
        layer:setVisibility(true)
        lu.assertIsTrue(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_visibility__false()
        local layer = _custom_layer()
        layer:setVisibility(false)
        lu.assertIsFalse(layer:isVisible())
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_opacity()
        local layer = _custom_layer()
        layer:setOpacity(0.1)
        lu.assertEquals(layer.opacity, 0.1)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__get_property()
        local layer = _custom_layer()
        lu.assertEquals(layer:getProperty("custom_map_property"), "test map string")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_property()
        local layer = _custom_layer()
        layer:setProperty("additional_property", "additional property string")
        lu.assertEquals(layer:getProperty("additional_property"), "additional property string")
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__set_num_properties()
        local layer = _custom_layer()
        lu.assertEquals(layer:getNumProperties(), 1)
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__has_property_key__true()
        local layer = _custom_layer()
        lu.assertIsTrue(layer:hasPropertyKey("custom_map_property"))
    end

    function TestModifyMapCustomLayer:test_mapmatic_custom_layer__tobject__has_property_key__false()
        local layer = _custom_layer()
        lu.assertIsFalse(layer:hasPropertyKey("not_a_property"))
    end

































