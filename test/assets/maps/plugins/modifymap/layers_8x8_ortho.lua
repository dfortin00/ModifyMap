return {
  version = "1.5",
  luaversion = "5.1",
  tiledversion = "1.8.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 8,
  height = 8,
  tilewidth = 16,
  tileheight = 16,
  nextlayerid = 11,
  nextobjectid = 1,
  properties = {
    ["custom_map_property"] = "test map string"
  },
  tilesets = {},
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 1,
      name = "tile_layer",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1.5,
      parallaxy = 2.5,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 3,
      name = "object_layer",
      visible = false,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {}
    },
    {
      type = "imagelayer",
      image = "",
      id = 4,
      name = "image_layer",
      visible = true,
      opacity = 1,
      offsetx = 30,
      offsety = 40,
      parallaxx = 1,
      parallaxy = 1,
      repeatx = false,
      repeaty = false,
      properties = {}
    },
    {
      type = "group",
      id = 2,
      name = "group_layer",
      visible = true,
      opacity = 0.5,
      offsetx = 10,
      offsety = 20,
      parallaxx = 1,
      parallaxy = 1,
      properties = {
        ["custom_group_property"] = "test group string"
      },
      layers = {
        {
          type = "tilelayer",
          x = 0,
          y = 0,
          width = 8,
          height = 8,
          id = 10,
          name = "layer.with.dots",
          visible = true,
          opacity = 1,
          offsetx = 0,
          offsety = 0,
          parallaxx = 1,
          parallaxy = 1,
          properties = {},
          encoding = "lua",
          data = {
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
          }
        },
        {
          type = "tilelayer",
          x = 0,
          y = 0,
          width = 8,
          height = 8,
          id = 5,
          name = "child_tile_layer",
          visible = true,
          opacity = 0.6,
          offsetx = 30,
          offsety = 40,
          parallaxx = 1,
          parallaxy = 1,
          properties = {
            ["custom_child_property"] = "test child string"
          },
          encoding = "lua",
          data = {
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
          }
        },
        {
          type = "objectgroup",
          draworder = "topdown",
          id = 7,
          name = "child_object_layer",
          visible = false,
          opacity = 1,
          offsetx = 0,
          offsety = 0,
          parallaxx = 1,
          parallaxy = 1,
          properties = {},
          objects = {}
        },
        {
          type = "imagelayer",
          image = "",
          id = 6,
          name = "child_image_layer",
          visible = true,
          opacity = 1,
          offsetx = 0,
          offsety = 0,
          parallaxx = 1,
          parallaxy = 1,
          repeatx = false,
          repeaty = false,
          properties = {}
        },
        {
          type = "group",
          id = 8,
          name = "child_group_layer",
          visible = true,
          opacity = 1,
          offsetx = 0,
          offsety = 0,
          parallaxx = 1,
          parallaxy = 1,
          properties = {},
          layers = {
            {
              type = "tilelayer",
              x = 0,
              y = 0,
              width = 8,
              height = 8,
              id = 9,
              name = "sub_layer",
              visible = true,
              opacity = 1,
              offsetx = 0,
              offsety = 0,
              parallaxx = 1,
              parallaxy = 1,
              properties = {},
              encoding = "lua",
              data = {
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0
              }
            }
          }
        }
      }
    }
  }
}
