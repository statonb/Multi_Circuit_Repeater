local MODNAME = "__Multi_Circuit_Repeater__"

-------------------------
--- Main Tower Entity ---
-------------------------
local mini_radar = table.deepcopy(data.raw["radar"]["radar"])
mini_radar.name = "wireless-circuit-tower"
mini_radar.icon = MODNAME .. "/graphics/mini-radar-icon.png"
mini_radar.icon_size = 165
mini_radar.tile_width = 1
mini_radar.tile_height = 1
--mini_radar.max_distance_of_nearby_sector_revealed = 1
--mini_radar.max_distance_of_sector_revealed = 3

mini_radar.energy_source = {
    type = "electric",
    usage_priority = "secondary-input"
}

mini_radar.supply_area_distance = 1.1
mini_radar.energy_usage = "1kW"
mini_radar.energy_per_nearby_scan = "3kJ"
mini_radar.build_grid_size = 1
mini_radar.draw_copper_wires = true


-- Sounds
mini_radar.working_sound = {
        sound = {
            filename = MODNAME .. "/sound/working.ogg",
            volume = 0.2
        },
}

-- Sprites
mini_radar.pictures = {	
    layers = {		
        {
            filename = MODNAME .. "/graphics/wct-pole.png", 		-- Custom sprite
            width = 70,
            height = 220,
            frame_count = 1, 										-- Static sprite
			scale = 0.6,
            shift = {0, -1.155}, 									-- Adjust as needed for placement			
			direction_count = 1
        },
		{
            filename = MODNAME .. "/graphics/wct-pole-shadow.png",  -- Custom sprite
            width = 246,
            height = 52,
            frame_count = 1, 										-- Static sprite
            scale = 0.6,
            shift = {2.5, .6}, 										-- Adjust as needed for placement
			direction_count = 1,
			draw_as_shadow = true
        },
    }
}

mini_radar.base_picture = {
    layers = {
        {
            filename = "__core__/graphics/empty.png",
            width = 1,
            height = 1,
            shift = {0, 0}
        }
    }
}

mini_radar.radius_visualisation_picture = {
    filename = "__core__/graphics/empty.png",
    width = 1,
    height = 1,
    shift = {0, 0}
}

mini_radar.integration_patch = nil
mini_radar.integration_patch_render_layer = nil


-- This needs to be false to stop all radars automatically linking to each other
mini_radar.connects_to_other_radars = false

-- Draw circuit wires
mini_radar.draw_circuit_wires = false

-- Mini-radar_port will draw over this, but its OK
mini_radar.circuit_connector = {
			sprites = {
			connector_main = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04a-base-sequence.png",
				width = 32,
				height = 32,
				x = 116,
				y = 170,
				shift = {0.05, 0.57},
				scale = 0.5
			},
			wire_pins = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04c-wire-sequence.png",
				width = 32,
				height = 32,
				x = 377,
				y = 82,
				shift = {-0.15, 0.6},
				scale = 0.5
			},
			led_red = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04i-red-LED-sequence.png",
				width = 20,
				height = 20,
				x = 13,
				y = 8,
				shift = {0, 0},
				scale = 0.5
			},
			led_green = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04h-green-LED-sequence.png",
				width = 8,
				height = 8,
				x = 116,
				y = 170,
				shift = {0.6, -0.7},
				scale = 0.5
			},
			led_blue = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04f-blue-LED-off-sequence.png",
				width = 8,
				height = 8,
				x = 112,
				y = 123,
				shift = {0.05, 0.57},
				scale = 0.5
			}, -- Added valid led_blue, else will crash
			logistic_animation = nil,
			led_light = {
				intensity = 0.8, -- Brightness of the light
				size = 0.9,      -- Size of the light effect
				color = {r = 1.0, g = 1.0, b = 1.0} -- Color of the light (white in this case)
			}
		},
		
		-- WAS HERE
		
		wire_max_distance = 9
	}


-- Set the collision and selection boxes to 1x1
mini_radar.collision_box = {{-0.4, -0.4}, {0.4, 0.4}}  -- 1x1 grid size

--mini_radar.selection_box = {{-0.5, -1.5}, {0.5, -0.5}}  -- 1x1 selection box
--mini_radar.selection_box = {{-0.4, -1.1}, {0.4, -0.1}}
--mini_radar.selection_box = {{-0.4, -0.8}, {0.4, 0.8}}

mini_radar.selection_box = {{-0.4, -0.9}, {0.4, 0.3}}

mini_radar.minable = {
    mining_time = 1,    				 -- Time it takes to mine
    result = "wireless-circuit-tower"    -- The item dropped
}

-- Need to fix this to use custom png
mini_radar.max_health = 40

mini_radar.ghost_icon = {
    filename = MODNAME .. "/graphics/mini-radar-icon.png",  -- Path to the custom ghost icon
    size = 64,  											-- Set icon size
    flags = {"icon"}  										-- This is usually the flag used for normal icons
}

local mini_radar_remnants = {
    type = "corpse",
    name = "mini-radar-remnants",  -- Unique name for the corpse
    icon = MODNAME .. "/graphics/mini-radar-icon.png",  -- Use a custom icon for the corpse
    icon_size = 64,  -- Set the icon size
    flags = {"placeable-neutral", "not-on-map"},  -- Flags to control corpse behavior
    selection_box = {{-0.8, -0.8}, {0.8, 0.8}},  -- The clickable area of the corpse
    tile_width = 1,  -- Width in tiles
    tile_height = 1,  -- Height in tiles
    selectable_in_game = false,  -- The corpse cannot be selected in the game
    time_before_removed = 60 * 60 * 10,  -- 10 minutes before being removed
    subgroup = "remnants",  -- Subgroup to categorize corpses
    order = "d[remnants]-a[mini-radar]",  -- Sorting order
    final_render_layer = "remnants",  -- Render layer
    animation = {
        layers = {
            {
                filename = MODNAME .. "/graphics/mini-radar-remnants.png",  -- Use custom sprite for the corpse
                width = 135,
                height = 84,
                frame_count = 1,
                scale = 0.75,
                shift = {0, 0},  -- Adjust the shift of the corpse sprite
                direction_count = 1,
                hr_version = {
                    filename = MODNAME .. "/graphics/mini-radar-remnants.png",  -- HR version, can use the same sprite
                    width = 135,
                    height = 84,
                    frame_count = 1,
                    scale = 0.75,
                    shift = {0, 0},
                    direction_count = 1,
                },
            },
        },
    },
}


data:extend({mini_radar_remnants})
mini_radar.corpse = "mini-radar-remnants"




-- Mini Radar Item
local mini_radar_item = {
  type = "item",
  name = "wireless-circuit-tower",
  --icon = "__base__/graphics/icons/radar.png",
  icon = MODNAME .. "/graphics/mini-radar-icon.png",
  icon_size = 165,
  subgroup = "defensive-structure",
  order = "d[radar]-b[wireless-circuit-tower]",
  place_result = "wireless-circuit-tower",
  stack_size = 50
}


-- Mini Radar Recipe
local mini_radar_recipe = {
  type = "recipe",
  name = "wireless-circuit-tower",
  enabled = false,
  energy_required = 5,
  ingredients = {    
    {type = "item", name = "iron-plate", amount = 30},
    {type = "item", name = "copper-cable", amount = 15}
  },
  results = {
    {type = "item", name = "wireless-circuit-tower", amount = 1}
  }
}



-- Mini Radar Technology
local mini_radar_technology = {
  type = "technology",
  name = "wireless-circuit-tech",
  -- need a technology icon
  icon = MODNAME .. "/graphics/mini-radar-tech.png",
  icon_size = 256,
  icon_mipmaps = 4,
  prerequisites = {"radar"},
  unit = {
    count = 100,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"military-science-pack", 1},
      },
    time = 30
  },
  effects = {
    {
      type = "unlock-recipe",
      recipe = "wireless-circuit-tower"
    }
  }
}

data:extend({mini_radar_technology})



---------------------------------
--- Tower Base Section / Port ---
--------------------------------
local mini_radar_port = table.deepcopy(data.raw["radar"]["radar"])
	mini_radar_port.name = "wireless-circuit-tower-port"
	mini_radar_port.minable = { 
		result = "wireless-circuit-tower",
		mining_time = 1,
	}
	mini_radar_port.energy_source = { type = "void" }
    mini_radar_port.energy_usage_per_tick = "1W"
	mini_radar_port.active_energy_usage = "1W"
	mini_radar_port.selection_box = {{-.4, -0.1}, {0.4, 0.9}}
	
	mini_radar_port.max_distance_of_nearby_sector_revealed = 1
	mini_radar_port.max_distance_of_sector_revealed = 1
	mini_radar_port.energy_usage = "1W"
	mini_radar_port.energy_per_nearby_scan = "10J"
	mini_radar_port.build_grid_size = 1
	
	mini_radar_port.collision_mask = { layers={} }
	mini_radar_port.collision_box = {{-0.1,-0.1},{0.1,0.1}}
	
	
	
	mini_radar_port.flags = {
      "player-creation",
      "not-flammable",
      "not-rotatable",
      "hide-alt-info", 
    }
	mini_radar_port.destructible = true
	mini_radar_port.max_health = 40
	
	mini_radar_port.working_sound = {
			sound = {
				filename = MODNAME .. "/sound/working.ogg",
				volume = 0
			},
	}

	local matching_connection_points = {
		-- North
		{
			shadow = { red = {-0, 0}, green = {-0.3, 0.66} },
			wire = { red = {-.85, 0}, green = {-.85, 0.46} }
		},
		-- East
		{
			shadow = { red = {-0, 0}, green = {-0.3, 0.66} },
			wire = { red = {-.85, 0}, green = {-.85, 0.46} }
		},
		-- South
		{
			shadow = { red = {-0, 0}, green = {-0.3, 0.66} },
			wire = { red = {-.85, 0}, green = {-.85, 0.46} }
		},
		-- West
		{
			shadow = { red = {-0, 0}, green = {-0.3, 0.66} },
			wire = { red = {-.85, 0}, green = {-.85, 0.46} }
		}
	}
	
	
	
	circuit_wire_max_distance = 12
	

	--mini_radar_port.sprites = dc.sprites
	
	mini_radar_port.pictures = {	
		layers = {		
			{
				filename = MODNAME .. "/graphics/wct-pole-port.png",
				width = 70,
				height = 220,
				frame_count = 1,
				scale = 0.6,
				shift = {0, -1.155},
				direction_count = 1
			},
		}
	}

	mini_radar_port.integration_patch = nil
	
	mini_radar_port.connects_to_other_radars = false

	mini_radar_port.circuit_connector = {
			sprites = {
			connector_main = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04a-base-sequence.png",
				width = 32,
				height = 32,
				x = 116,
				y = 170,
				shift = {0.05, 0.57},
				scale = 0.5
			},
			wire_pins = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04c-wire-sequence.png",
				width = 32,
				height = 32,
				x = 377,
				y = 82,
				shift = {-0.15, 0.6},
				scale = 0.5
			},
			led_red = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04i-red-LED-sequence.png",
				width = 20,
				height = 20,
				x = 13,
				y = 8,
				shift = {0, 0},
				scale = 0.5
			},
			led_green = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04h-green-LED-sequence.png",
				width = 8,
				height = 8,
				x = 116,
				y = 170,
				shift = {0.6, -0.7},
				scale = 0.5
			},
			led_blue = {
				filename = "__base__/graphics/entity/circuit-connector/ccm-universal-04f-blue-LED-off-sequence.png",
				width = 8,
				height = 8,
				x = 112,
				y = 123,
				shift = {0.05, 0.57},
				scale = 0.5
			}, -- Added valid led_blue, else will crash
			logistic_animation = nil,
			led_light = {
				intensity = 0.8, -- Brightness of the light
				size = 0.9,      -- Size of the light effect
				color = {r = 1.0, g = 1.0, b = 1.0} -- Color of the light (white in this case)
			}
		},
		points = {
			shadow = {
				copper = {0, 0},   -- Shadow position of the copper wire
				red = {-0.3, 0.46},      -- Shadow position of the red wire
				green = {-0.3, 0.66}     -- Shadow position of the green wire
			},
			wire = {
				copper = {0, 0},   -- Actual connection point for the copper wire
				red = {-0.3, 0.46},      -- Actual connection point for the red wire
				green = {-0.3, 0.66}     -- Actual connection point for the green wire
			}
		},
		wire_max_distance = 9
	}

local mini_radar_port_item = {
	  type = "item",
	  name = "wireless-circuit-tower-port",
	  --icon = "__base__/graphics/icons/radar.png",
	  icon = MODNAME .. "/graphics/mini-radar-icon.png",
	  icon_size = 165,
	  subgroup = "defensive-structure",
	  order = "d[radar]-b[wireless-circuit-tower]",
	  place_result = "wireless-circuit-tower-port", --  Added -port in .19
	  stack_size = 50
	}

	
-- Power Sprites
local mini_radar_sprites = {
	type = "sprite",
	name = "wct-overlay",
	filename = "__Multi_Circuit_Repeater__/graphics/wct-overlay.png",
	width = 70,
	height = 220,
	priority = "extra-high-no-scale",
	flags = {"icon"},
	scale = 0.6,
	shift = {0, -1.15}
}

-- Extend Data
data:extend({
  mini_radar,
  mini_radar_item,
  mini_radar_recipe,
  mini_radar_technology,
  mini_radar_sprites,
})

data:extend({
  mini_radar_port,
  mini_radar_port_item,
})

-- Renamer

data:extend({
  {
    type = "custom-input",
    name = "rename",
    key_sequence = "CTRL + N",
    consuming = "none"
  },
  {
    type = "custom-input",
    name = "remove-artifacts",
    key_sequence = "CONTROL + F1",
    consuming = "none"
  },
  {
    type = "custom-input",
    name = "rename-mouse",
    key_sequence = "mouse-button-1",
    consuming = "none" -- Allows other interactions to happen simultaneously
  },
  {
    type = "sprite",
    name = "renamer-return-key",
    filename = MODNAME .. "/graphics/return-key.png",
    priority = "extra-high-no-scale",
    size = 32,
    scale = 1,
    flags = {"icon"}
  }
})

data.raw["gui-style"].default["renamer_titlebar_flow"] = {
    type = "horizontal_flow_style",
    direction = "horizontal",
    horizontally_stretchable = "on",
    vertical_align = "center"
}