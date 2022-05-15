
local mapdir = 'assets/maps/plugins/modifymap/'

local batch_8x8_ortho  = mapdir .. 'batch_8x8_ortho__ts1_tc1'
local layers_8x8_ortho = mapdir .. 'layers_8x8_ortho'
local empty_8x8_ortho  = mapdir .. 'empty_8x8_ortho'

TestModifyMapMapEntity = {}

    function TestModifyMapMapEntity:setUp()
        local map = MapFactory(empty_8x8_ortho)
        map:loadPlugin("ModifyMap")
    end

    function TestModifyMapMapEntity:tearDown()
        MapFactory:clearCache()
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__class_name()
        local entity = MapEntity()
        lu.assertEquals(entity:type(), "MapEntity")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__type_of()
        local entity = MapEntity()
        lu.assertIsTrue(entity:typeOf("TObject"))
    end

    --[[ MapEntity:init ]]

    function TestModifyMapMapEntity:test_modify_map_map_entity_init__defaults()
        local entity = MapEntity()
        lu.assertEquals(entity, {
            x        = 0,
            y        = 0,
            width    = 1,
            height   = 1,
            rotation = 0,
            sx       = 1,
            sy       = 1,
            ox       = 0,
            oy       = 0,
            offsetx  = 0,
            offsety  = 0,
            name     = "default",
            visible  = true,
            opacity  = 1,

            properties = entity.properties,
        })
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_init__definitions()
        local defs = {
            x        = 10,
            y        = 20,
            width    = 30,
            height   = 40,
            rotation = math.rad(45),
            sx       = 2,
            sy       = 3,
            ox       = 15,
            oy       = 20,
            offsetx  = 50,
            offsety  = 60,
            name     = "test",
            visible  = false,
            opacity  = 2,
        }

        local entity = MapEntity(defs)
        defs.properties = entity.properties
        lu.assertEquals(entity, defs)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_init__properties()
        local entity = MapEntity()
        lu.assertEquals(entity.properties:type(), "MapProperties")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_init__properties__initializer()
        local entity = MapEntity {properties={test_prop="test_value"}}
        lu.assertEquals(entity.properties.props["test_prop"].value, "test_value")
    end

    --[[ MapEntity:getOwner ]]

    function TestModifyMapMapEntity:test_modify_map_map_entity_get_owner__not_added_to_layer()
        local entity = MapEntity()
        lu.assertIsNil(entity:getOwner())
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_get_owner__added_to_layer()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")
        local layer = plugin:addCustomLayer("custom_layer")

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertIsTrue(entity:getOwner() == layer)
    end

    --[[ MapEntity:getIndex ]]

    function TestModifyMapMapEntity:test_modify_map_map_entity_get_index__not_added_to_layer()
        local entity = MapEntity()
        lu.assertIsNil(entity:getIndex())
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_get_index__added_to_layer()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")
        local layer = plugin:addCustomLayer("custom_layer")

        local entity1 = MapEntity()
        local entity2 = MapEntity()
        layer:addEntity(entity1)
        layer:addEntity(entity2)

        lu.assertEquals(entity1:getIndex(), 1)
        lu.assertEquals(entity2:getIndex(), 2)
    end

    --[[ MapEntity:collides ]]

    function TestModifyMapMapEntity:test_modify_map_map_entity_collides__true()
        local entity1 = MapEntity({x=10, y=20, width=30, height=40})
        local entity2 = MapEntity({x=0 , y=0 , width=30, height=40})

        lu.assertIsTrue(entity1:collides(entity2))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_collides__false()
        local entity1 = MapEntity({x=10, y=20, width=30, height=40})
        local entity2 = MapEntity({x=90, y=90, width=30, height=40})

        lu.assertIsFalse(entity1:collides(entity2))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_collides__target_has_get_rect()
        local map = MapFactory(batch_8x8_ortho)
        local instance = map:getLayer("ts_layer__fit"):getTileInstance(1, 1)
        local entity1 = MapEntity({x=10, y=20, width=30, height=40})

        lu.assertIsTrue(entity1:collides(instance))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_collides__target_has_coordinates()
        local entity1 = MapEntity({x=10, y=20, width=30, height=40})
        lu.assertIsTrue(entity1:collides({x=0, y=0, width=30, height=40}))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity_collides__target_is_array()
        local entity1 = MapEntity({x=10, y=20, width=30, height=40})
        lu.assertIsTrue(entity1:collides({0, 0, 30, 40}))
    end

    --============================
    -- TObject
    --============================

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_id__not_added_to_layer()
        local entity = MapEntity()
        lu.assertEquals(entity:getId(), 0)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_id__added_to_layer()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")
        local layer = plugin:addCustomLayer("custom_layer")

        local entity = MapEntity()
        layer:addEntity(entity)

        lu.assertEquals(entity:getId(), 1)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_id__after_removal()
        local map = MapFactory(layers_8x8_ortho)
        local plugin = map:loadPlugin("ModifyMap")
        local layer = plugin:addCustomLayer("custom_layer")

        local entity1 = MapEntity()
        local entity2 = MapEntity()
        local entity3 = MapEntity()

        layer:addEntity(entity1)
        layer:addEntity(entity2)

        layer:removeEntity(entity1)

        layer:addEntity(entity3)

        lu.assertEquals(entity3:getId(), 3)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_name__default()
        local entity = MapEntity()
        lu.assertEquals(entity:getName(), "default")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_name()
        local entity = MapEntity({name="Test Name"})
        lu.assertEquals(entity:getName(), "Test Name")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_name()
        local entity = MapEntity({name="Test Name"})
        entity:setName("new_entity_name")
        lu.assertEquals(entity:getName(), "new_entity_name")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_position()
        local entity = MapEntity {x=10, y=20}
        lu.assertEquals({entity:getPosition()}, {10, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_x()
        local entity = MapEntity {x=10, y=20}
        lu.assertEquals(entity:getX(), 10)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_y()
        local entity = MapEntity {x=10, y=20}
        lu.assertEquals(entity:getY(), 20)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_position()
        local entity = MapEntity()
        entity:setPosition(10, 20)
        lu.assertEquals({entity.x, entity.y}, {10, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_x()
        local entity = MapEntity({x=10, y=20})
        entity:setX(50)
        lu.assertEquals({entity.x, entity.y}, {50, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_y()
        local entity = MapEntity({x=10, y=20})
        entity:setY(50)
        lu.assertEquals({entity.x, entity.y}, {10, 50})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__move_by()
        local entity = MapEntity({x=10, y=20})
        entity:moveBy(30, 60)
        lu.assertEquals({entity.x, entity.y}, {40, 80})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_rotation()
        local entity = MapEntity({rotation=math.rad(45)})
        lu.assertEquals(entity:getRotation(), math.rad(45))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_rotation()
        local entity = MapEntity()
        entity:setRotation(math.rad(45))
        lu.assertEquals(entity:getRotation(), math.rad(45))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__rotate_by()
        local entity = MapEntity({rotation=math.rad(30)})
        entity:rotateBy(math.rad(45))
        lu.assertAlmostEquals(entity:getRotation(), math.rad(30 + 45), 0.000001)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_scale()
        local entity = MapEntity({sx=0.5, sy=0.6})
        lu.assertEquals({entity:getScale()}, {0.5, 0.6})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_scale_x()
        local entity = MapEntity({sx=0.5, sy=0.6})
        lu.assertEquals(entity:getScaleX(), 0.5)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_scale_y()
        local entity = MapEntity({sx=0.5, sy=0.6})
        lu.assertEquals(entity:getScaleY(), 0.6)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_scale()
        local entity = MapEntity()
        entity:setScale(0.5, 0.6)
        lu.assertEquals({entity:getScale()}, {0.5, 0.6})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_scale_x()
        local entity = MapEntity()
        entity:setScaleX(0.5)
        lu.assertEquals({entity:getScale()}, {0.5, 1})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_scale_y()
        local entity = MapEntity()
        entity:setScaleY(0.6)
        lu.assertEquals({entity:getScale()}, {1, 0.6})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__scale_by()
        local entity = MapEntity({sx=2, sy=3})
        entity:scaleBy(4, 5)
        lu.assertEquals({entity:getScale()}, {6, 8})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_origin()
        local entity = MapEntity({ox=15, oy=20})
        lu.assertEquals({entity:getOrigin()}, {15, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_origin_x()
        local entity = MapEntity({ox=15, oy=20})
        lu.assertEquals(entity:getOriginX(), 15)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_origin_y()
        local entity = MapEntity({ox=15, oy=20})
        lu.assertEquals(entity:getOriginY(), 20)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_origin()
        local entity = MapEntity()
        entity:setOrigin(15, 20)
        lu.assertEquals({entity:getOrigin()}, {15, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_origin_x()
        local entity = MapEntity()
        entity:setOriginX(15)
        lu.assertEquals({entity:getOrigin()}, {15, 0})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_origin_y()
        local entity = MapEntity()
        entity:setOriginY(20)
        lu.assertEquals({entity:getOrigin()}, {0, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_draw_coords()
        local entity = MapEntity({x=10, y=20, width=30, height=40, rotation=math.rad(45),
            sx=2, sy=3, ox=15, oy=20, offsetx=50, offsety=60})
        lu.assertEquals({entity:getDrawCoords()}, {10 + 50 - 15, 20 + 60 - 20, math.rad(45), 2, 3, 15, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_dimensions()
        local entity = MapEntity {width=10, height=20}
        lu.assertEquals({entity:getDimensions()}, {10, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_width()
        local entity = MapEntity {width=10, height=20}
        lu.assertEquals(entity:getWidth(), 10)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_height()
        local entity = MapEntity {width=10, height=20}
        lu.assertEquals(entity:getHeight(), 20)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_rect()
        local entity = MapEntity({x=10, y=20, width=30, height=40, rotation=math.rad(45),
            sx=2, sy=3, ox=15, oy=20, offsetx=50, offsety=60})
        lu.assertEquals({entity:getRect()}, {10 - 15, 20 - 20, 30, 40})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_offsets()
        local entity = MapEntity {offsetx=10, offsety=20}
        lu.assertEquals({entity:getOffsets()}, {10, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_offset_x()
        local entity = MapEntity {offsetx=10, offsety=20}
        lu.assertEquals(entity:getOffsetX(), 10)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_offset_y()
        local entity = MapEntity {offsetx=10, offsety=20}
        lu.assertEquals(entity:getOffsetY(), 20)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_offsets()
        local entity = MapEntity {offsetx=10, offsety=20}
        entity:setOffsets(30, 40)
        lu.assertEquals({entity:getOffsets()}, {30, 40})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_offset_x()
        local entity = MapEntity {offsetx=10, offsety=20}
        entity:setOffsetX(30)
        lu.assertEquals({entity:getOffsets()}, {30, 20})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_offset_y()
        local entity = MapEntity {offsetx=10, offsety=20}
        entity:setOffsetY(30)
        lu.assertEquals({entity:getOffsets()}, {10, 30})
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__is_visible__true()
        local entity = MapEntity()
        lu.assertIsTrue(entity:isVisible())
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__is_visible__false()
        local entity = MapEntity({visible=false})
        lu.assertIsFalse(entity:isVisible())
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_visibility__true()
        local entity = MapEntity({visible=false})
        entity:setVisibility(true)
        lu.assertIsTrue(entity.visible)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_visibility__false()
        local entity = MapEntity()
        entity:setVisibility(false)
        lu.assertIsFalse(entity.visible)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_opacity__default()
        local entity = MapEntity()
        lu.assertEquals(entity:getOpacity(), 1)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_opacity()
        local entity = MapEntity({opacity=0.3})
        lu.assertEquals(entity:getOpacity(), 0.3)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_opacity()
        local entity = MapEntity()
        entity:setOpacity(0.5)
        lu.assertEquals(entity.opacity, 0.5)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_property()
        local entity = MapEntity {properties={test_prop="test value"}}
        lu.assertEquals(entity:getProperty("test_prop"), "test value")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__set_property()
        local entity = MapEntity()
        entity:setProperty("test_prop", "test value")
        lu.assertEquals(entity:getProperty("test_prop"), "test value")
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__get_num_properties()
        local entity = MapEntity()
        entity:setProperty("test_prop", "test value")
        lu.assertEquals(entity:getNumProperties(), 1)
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__has_property_key__true()
        local entity = MapEntity()
        entity:setProperty("test_prop", "test value")
        lu.assertIsTrue(entity:hasPropertyKey("test_prop"))
    end

    function TestModifyMapMapEntity:test_modify_map_map_entity__tobject__has_property_key__false()
        local entity = MapEntity()
        entity:setProperty("test_prop", "test value")
        lu.assertIsFalse(entity:hasPropertyKey("not_a_property"))
    end

























