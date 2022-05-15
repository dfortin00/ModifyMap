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
  nextlayerid = 7,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "world_tileset16x16",
      firstgid = 1,
      tilewidth = 16,
      tileheight = 16,
      spacing = 0,
      margin = 0,
      columns = 8,
      image = "../../../world_tileset.png",
      imagewidth = 128,
      imageheight = 128,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 16,
        height = 16
      },
      properties = {
        ["tileset_prop"] = "tileset property value"
      },
      wangsets = {},
      tilecount = 64,
      tiles = {
        {
          id = 0,
          properties = {
            ["tile_prop"] = "tile property value"
          },
          objectGroup = {
            type = "objectgroup",
            draworder = "index",
            id = 2,
            name = "",
            visible = true,
            opacity = 1,
            offsetx = 0,
            offsety = 0,
            parallaxx = 1,
            parallaxy = 1,
            properties = {},
            objects = {
              {
                id = 1,
                name = "rect_object",
                type = "",
                shape = "rectangle",
                x = 7.82609,
                y = 1.30435,
                width = 8.17391,
                height = 6.13043,
                rotation = 0,
                visible = true,
                properties = {
                  ["tile_object_prop"] = "tile object property value"
                }
              },
              {
                id = 2,
                name = "ellipse_object",
                type = "",
                shape = "ellipse",
                x = 1.08696,
                y = 0.652174,
                width = 4.56522,
                height = 4.34783,
                rotation = 0,
                visible = true,
                properties = {}
              },
              {
                id = 6,
                name = "polygon_object",
                type = "",
                shape = "polygon",
                x = 1.86957,
                y = 11.1304,
                width = 0,
                height = 0,
                rotation = 0,
                visible = true,
                polygon = {
                  { x = 0, y = 0 },
                  { x = 0.130435, y = 4.47826 },
                  { x = 4.17391, y = 4.30435 }
                },
                properties = {}
              },
              {
                id = 7,
                name = "polyline_object",
                type = "",
                shape = "polyline",
                x = 10.1304,
                y = 11.3043,
                width = 0,
                height = 0,
                rotation = 0,
                visible = true,
                polyline = {
                  { x = 0, y = 0 },
                  { x = 4.43478, y = 3.86957 }
                },
                properties = {}
              }
            }
          }
        },
        {
          id = 1,
          animation = {
            {
              tileid = 1,
              duration = 500
            },
            {
              tileid = 33,
              duration = 500
            }
          }
        }
      }
    },
    {
      name = "tile_collection",
      firstgid = 65,
      tilewidth = 81,
      tileheight = 76,
      spacing = 0,
      margin = 0,
      columns = 0,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 1,
        height = 1
      },
      properties = {},
      wangsets = {},
      tilecount = 6,
      tiles = {
        {
          id = 0,
          image = "../../../back.png",
          width = 16,
          height = 16
        },
        {
          id = 1,
          image = "../../../bpanel.png",
          width = 15,
          height = 15,
          animation = {
            {
              tileid = 1,
              duration = 500
            },
            {
              tileid = 0,
              duration = 500
            }
          }
        },
        {
          id = 2,
          image = "../../../portrait.png",
          width = 81,
          height = 76
        },
        {
          id = 3,
          image = "../../../gradient_panel.png",
          width = 9,
          height = 9,
          animation = {
            {
              tileid = 3,
              duration = 500
            },
            {
              tileid = 2,
              duration = 500
            }
          }
        },
        {
          id = 4,
          image = "../../../mage_portrait.png",
          width = 81,
          height = 76,
          animation = {
            {
              tileid = 4,
              duration = 500
            },
            {
              tileid = 0,
              duration = 500
            }
          }
        },
        {
          id = 6,
          image = "../../../gradient_panel_different.png",
          width = 8,
          height = 9
        }
      }
    },
    {
      name = "world_tileset32x32",
      firstgid = 72,
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 4,
      image = "../../../world_tileset.png",
      imagewidth = 128,
      imageheight = 128,
      objectalignment = "unspecified",
      tileoffset = {
        x = 10,
        y = 20
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 16,
      tiles = {}
    },
    {
      name = "tmw_desert_spacing",
      firstgid = 88,
      tilewidth = 32,
      tileheight = 32,
      spacing = 1,
      margin = 1,
      columns = 8,
      image = "../../../tmw_desert_spacing.png",
      imagewidth = 265,
      imageheight = 199,
      objectalignment = "unspecified",
      tileoffset = {
        x = 10,
        y = 20
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {
        ["tileset_property"] = "tileset property value"
      },
      wangsets = {},
      tilecount = 48,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 1,
      name = "ts_layer__fit",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        24, 24, 24, 24, 24, 24, 24, 24,
        24, 25, 26, 27, 24, 24, 24, 24,
        24, 33, 34, 35, 24, 24, 24, 24,
        24, 41, 42, 43, 24, 24, 24, 24,
        24, 24, 24, 24, 24, 24, 24, 24,
        24, 24, 24, 24, 24, 48, 24, 24,
        24, 24, 24, 24, 24, 24, 24, 24,
        1, 24, 24, 24, 24, 24, 24, 24
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 2,
      name = "ts_layer__does_not_fit",
      visible = false,
      opacity = 0.7,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        19, 19, 19, 19, 19, 19, 19, 19,
        72, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 19, 19,
        19, 19, 19, 19, 19, 19, 87, 19
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 3,
      name = "tc_layer__fit",
      visible = false,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 66, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 66, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 66, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 4,
      name = "tc_layer__does_not_fit",
      visible = false,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 67, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65,
        65, 65, 65, 65, 65, 65, 65, 65
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 8,
      height = 8,
      id = 5,
      name = "tc_anim__fit",
      visible = false,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 66, 0, 0,
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
      id = 6,
      name = "tc_anim_does_not_fit",
      visible = false,
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
        0, 0, 69, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
      }
    }
  }
}
