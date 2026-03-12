require("mod-gui")
local MODNAME = "__Multi_Circuit_Repeater__"

------------------------------------------------------------
-- PERSISTENT STORAGE INITIALISATION (Factorio 2.0: `storage`)
------------------------------------------------------------

local function init_storage()
  storage.renamer = storage.renamer or {}
  storage.tmp_backer = storage.tmp_backer or {}
  storage.wct_overlays = storage.wct_overlays or {}
  storage.renderings_by_target = storage.renderings_by_target or {}
  storage.renderings2_by_target = storage.renderings2_by_target or {}
  storage.mini_radar_power_states = storage.mini_radar_power_states or {}
end

script.on_init(init_storage)
script.on_configuration_changed(init_storage)

script.on_load(function()
  -- no persistent mutation here
end)

------------------------------------------------------------
-- SETTINGS / FLAGS
------------------------------------------------------------

local default_channel_name = "UNASSIGNED"
local isDebugPrint = false
local isPowerChecksDisabled = false

local function debug_print(message)
  if isDebugPrint then
    game.print(message)
  end
end

------------------------------------------------------------
-- ENTITY FILTERS
------------------------------------------------------------

local built_filters = {
  { filter = "name", name = "wireless-circuit-tower" }
}

------------------------------------------------------------
-- RENDERING HELPERS + UNIFIED CLEANUP
------------------------------------------------------------

local function AddTowerText(entity, text)
  if entity and entity.valid then
    return rendering.draw_text{
      surface = entity.surface,
      only_in_alt_mode = true,
      text = text or "",
      target = entity,
      color = { r = 0.7, g = 0.8, b = 0.9 },
      scale = 0.4,
      orientation = 0.0,
      alignment = "center",
      vertical_alignment = "top",
      offset = { 1, 0 },
      force = entity.force
    }
  end
end

local function UnifiedRenderCleanup(unit_number)
  local entry = storage.renderings_by_target[unit_number]
  if not entry then return end

  local t = type(entry)

  -- Old saves: numeric ID
  if t == "number" then
    local obj = rendering.get_object_by_id(entry)
    if obj and obj.valid then
      obj.destroy()
    end
    storage.renderings_by_target[unit_number] = nil
    return
  end

  -- New saves: LuaRenderObject
  if t == "userdata" then
    if entry.valid then
      entry.destroy()
    end
    storage.renderings_by_target[unit_number] = nil
    return
  end

  -- Fallback
  storage.renderings_by_target[unit_number] = nil
end

function RemoveTowerText(surface, unit_number)
  UnifiedRenderCleanup(unit_number)
end

------------------------------------------------------------
-- ENTITY CREATED
------------------------------------------------------------

local function OnEntityCreated(event)
  local entity = event.entity or event.destination
  if not (entity and entity.valid) then return end
  if entity.name ~= "wireless-circuit-tower" then return end

  entity.backer_name = default_channel_name

  -- ensure connectors exist (2.0: must use result)
  local _ = entity.get_wire_connectors(true)

  local obj = AddTowerText(entity, "")
  if obj then
    storage.renderings_by_target[entity.unit_number] = obj
    debug_print("Label created for tower " .. entity.unit_number)
  end

  local surface = entity.surface
  local port_entity = surface.create_entity{
    name = "wireless-circuit-tower-port",
    position = { entity.position.x, entity.position.y },
    force = entity.force
  }

  if port_entity and port_entity.valid then
    port_entity.backer_name = "(Connect circuit wires here)"
    port_entity.name_tag = tostring(entity.unit_number)

    local red1 = entity.get_wire_connector(defines.wire_connector_id.circuit_red)
    local red2 = port_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    if red1 and red2 then
      red1.connect_to(red2, false)
      debug_print("Tower port red connected: " .. entity.unit_number)
    end

    local green1 = entity.get_wire_connector(defines.wire_connector_id.circuit_green)
    local green2 = port_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    if green1 and green2 then
      green1.connect_to(green2, false)
      debug_print("Tower port green connected: " .. entity.unit_number)
    end
  end

  debug_print("Tower created: " .. entity.unit_number)
end

------------------------------------------------------------
-- FLASHER CLEANUP
------------------------------------------------------------

local function TidyUpFlashers()
  local all_render_objects = rendering.get_all_objects()
  for _, obj in ipairs(all_render_objects) do
    if obj.valid and obj.type == "animation" and obj.animation == "custom-blue-led-animation" then
      obj.destroy()
    end
  end
  storage.renderings2_by_target = {}
  debug_print("Flashers tidied")
end

------------------------------------------------------------
-- EVENT REGISTRATION FOR CREATION
------------------------------------------------------------

script.on_event(defines.events.on_built_entity, OnEntityCreated, built_filters)
script.on_event(defines.events.on_robot_built_entity, OnEntityCreated, built_filters)
script.on_event(defines.events.script_raised_built, OnEntityCreated, built_filters)
script.on_event(defines.events.on_entity_cloned, OnEntityCreated, built_filters)
script.on_event(defines.events.script_raised_revive, OnEntityCreated, built_filters)
script.on_event(defines.events.on_space_platform_built_entity, OnEntityCreated, built_filters)

------------------------------------------------------------
-- SETTINGS HANDLERS
------------------------------------------------------------

local function LoadSettingsRuntime(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  if event.setting == "enable-wct-debug-messages" then
    isDebugPrint = player.mod_settings["enable-wct-debug-messages"].value
  end

  if event.setting == "disable-tower-power-checks" then
    isPowerChecksDisabled = player.mod_settings["disable-tower-power-checks"].value
  end
end

local function LoadSettingsJoin(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  isDebugPrint = player.mod_settings["enable-wct-debug-messages"].value
  isPowerChecksDisabled = player.mod_settings["disable-tower-power-checks"].value
end

script.on_event(defines.events.on_runtime_mod_setting_changed, LoadSettingsRuntime)
script.on_event(defines.events.on_player_joined_game, LoadSettingsJoin)

------------------------------------------------------------
-- MESH CONNECTION HELPERS
------------------------------------------------------------

local function RemoveUnpoweredMeshConnections()
  for _, surface in pairs(game.surfaces) do
    for _, radar in pairs(surface.find_entities_filtered{ name = "wireless-circuit-tower" }) do
      if radar.valid and radar.get_control_behavior() then
        local radar_energy = radar.energy
        local wire_connectors = radar.get_wire_connectors()
        if wire_connectors then
          for _, connector in pairs(wire_connectors) do
            for i = #connector.connections, 1, -1 do
              local connection = connector.connections[i]
              local target = connection.target.owner
              if target.name == "wireless-circuit-tower" then
                if radar_energy == 0 or target.energy == 0 then
                  connector.disconnect_from(connection.target)
                end
              end
            end
          end
        end
      end
    end
  end
end

local function RemoveAllMeshConnections()
  for _, surface in pairs(game.surfaces) do
    local towers = surface.find_entities_filtered{ name = "wireless-circuit-tower" }
    for _, radar in pairs(towers) do
      if radar.valid then
        local wire_connectors = radar.get_wire_connectors()
        if wire_connectors then
          for _, connector in pairs(wire_connectors) do
            for _, connection in pairs(connector.connections) do
              if connection.target.owner.name == "wireless-circuit-tower" then
                connector.disconnect_from(connection.target)
              end
            end
          end
        end
      end
    end
  end
end

local function MakeMeshConnections(channel)
  if not channel then return end

  for _, surface in pairs(game.surfaces) do
    local mini_radars = surface.find_entities_filtered{ name = "wireless-circuit-tower" }

    local radar_groups = {}
    for _, radar in pairs(mini_radars) do
      if radar.backer_name ~= default_channel_name then
        local name = radar.backer_name
        radar_groups[name] = radar_groups[name] or {}
        table.insert(radar_groups[name], radar)
      end
    end

    local group = radar_groups[channel]
    if group then
      for i, radar1 in pairs(group) do
        if radar1.valid then
          local red1 = radar1.get_wire_connector(defines.wire_connector_id.circuit_red)
          local green1 = radar1.get_wire_connector(defines.wire_connector_id.circuit_green)

          if red1 then
            for j, radar2 in pairs(group) do
              if i ~= j and radar2.valid then
                local red2 = radar2.get_wire_connector(defines.wire_connector_id.circuit_red)
                if red2 then
                  red1.connect_to(red2, false)
                end
              end
            end
          end

          if green1 then
            for j, radar2 in pairs(group) do
              if i ~= j and radar2.valid then
                local green2 = radar2.get_wire_connector(defines.wire_connector_id.circuit_green)
                if green2 then
                  green1.connect_to(green2, false)
                end
              end
            end
          end
        end
      end
    end
  end
end

local function RebuildAllMeshConnections()
  RemoveAllMeshConnections()
  local rebuilt = {}
  for _, surface in pairs(game.surfaces) do
    for _, radar in pairs(surface.find_entities_filtered{ name = "wireless-circuit-tower" }) do
      if radar.valid and radar.backer_name ~= default_channel_name then
        if not rebuilt[radar.backer_name] then
          MakeMeshConnections(radar.backer_name)
          rebuilt[radar.backer_name] = true
        end
      end
    end
  end
end

local function ProcessFullLinkMesh(channel)
  RebuildAllMeshConnections()
end

------------------------------------------------------------
-- POWER RETURNED / STATE TRACKING
------------------------------------------------------------

local function CheckPowerReturnedRestoreConnections()
  RebuildAllMeshConnections()
end

local function UpdateTowerPowerStates(surface)
  local mini_radar_power_states = storage.mini_radar_power_states
  local change_count = 0

  local mini_radars = surface.find_entities_filtered{ name = "wireless-circuit-tower" }
  for _, radar in pairs(mini_radars) do
    if radar.valid then
      local current_state = radar.energy > 0
      local previous_state = mini_radar_power_states[radar.unit_number]

      if previous_state ~= current_state then
        change_count = change_count + 1
        debug_print("Wireless-circuit-tower " .. radar.unit_number .. " is now " .. (current_state and "Powered" or "Unpowered"))

        if current_state then
          local sprite_id = rendering.draw_sprite{
            sprite = "wct-overlay",
            target = radar,
            surface = surface,
            render_layer = "object",
            x_scale = 1,
            y_scale = 1,
            only_in_alt_mode = false
          }
          storage.wct_overlays[radar.unit_number] = sprite_id
        else
          local id = storage.wct_overlays[radar.unit_number]
          if id then
            if type(id) == "number" then
              local obj = rendering.get_object_by_id(id)
              if obj and obj.valid then obj.destroy() end
            elseif type(id) == "userdata" then
              if id.valid then id.destroy() end
            end
            storage.wct_overlays[radar.unit_number] = nil
          end
        end

        mini_radar_power_states[radar.unit_number] = current_state

        if not current_state then
          debug_print("Disconnecting: " .. radar.unit_number)
          if radar.energy <= 0 then
            local wire_connectors = radar.get_wire_connectors()
            if wire_connectors then
              for _, connector in pairs(wire_connectors) do
                for _, connection in pairs(connector.connections) do
                  if connection.target.owner.name == "wireless-circuit-tower" then
                    connector.disconnect_from(connection.target)
                  end
                end
              end
            end
            RemoveTowerText(radar.surface, radar.unit_number)
          end
        else
          debug_print("Reconnecting: " .. radar.unit_number)
          if radar.backer_name ~= default_channel_name then
            RebuildAllMeshConnections()

            local label = ""
            if #radar.backer_name > 0 then
              label = string.sub(radar.backer_name, 1, 3)
            end

            if not storage.renderings_by_target[radar.unit_number] then
              local obj = AddTowerText(radar, label)
              if obj then
                storage.renderings_by_target[radar.unit_number] = obj
                debug_print("Label recreated for tower " .. radar.unit_number)
              end
            end
          end
        end
      end
    end
  end

  return change_count
end

------------------------------------------------------------
-- TICK HANDLER
------------------------------------------------------------

script.on_event(defines.events.on_tick, function(event)
  if event.tick % 900 == 0 then
    if not isPowerChecksDisabled then
      for _, surface in pairs(game.surfaces) do
        if surface.valid then
          debug_print("Checking tower powers on " .. surface.name)
          local count = UpdateTowerPowerStates(surface)
          if count > 0 then
            RemoveUnpoweredMeshConnections()
          end
          debug_print(count .. " towers changed power state")
        end
      end
    end
  end
end)

------------------------------------------------------------
-- ENTITY REMOVAL
------------------------------------------------------------

local function OnEntityRemoved(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end

  local surface = entity.surface

  if entity.name == "wireless-circuit-tower" then
    RemoveTowerText(surface, entity.unit_number)

    local ports = surface.find_entities_filtered{ name = "wireless-circuit-tower-port" }
    for _, port in pairs(ports) do
      if port.valid and port.position.x == entity.position.x and port.position.y == entity.position.y then
        port.destroy()
      end
    end

    debug_print("Tower entity destroyed")
  elseif entity.name == "wireless-circuit-tower-port" then
    RemoveTowerText(surface, entity.unit_number)

    local towers = surface.find_entities_filtered{ name = "wireless-circuit-tower" }
    for _, tower in pairs(towers) do
      if tower.valid and tower.position.x == entity.position.x and tower.position.y == entity.position.y then
        RemoveTowerText(surface, tower.unit_number)
        tower.destroy()
      end
    end

    debug_print("Tower port entity destroyed")
  end
end

script.on_event(defines.events.on_player_mined_entity, OnEntityRemoved)
script.on_event(defines.events.on_entity_died, OnEntityRemoved)

------------------------------------------------------------
-- RENAMER / GUI (no LuaEntity stored in `storage`)
------------------------------------------------------------

local function set_renamer_target(player, entity)
  storage.renamer[player.index] = {
    surface_index = entity.surface.index,
    position = { x = entity.position.x, y = entity.position.y },
    unit_number = entity.unit_number
  }
end

local function get_renamer_entity(player)
  local data = storage.renamer[player.index]
  if not data then return nil end

  local surface = game.surfaces[data.surface_index]
  if not (surface and surface.valid) then return nil end

  local entity = surface.find_entity("wireless-circuit-tower", data.position)
  if entity and entity.valid and entity.unit_number == data.unit_number then
    return entity
  end
  return nil
end

local function SpawnGUI(player)
  if player.gui.screen.renamer_frame then
    player.gui.screen.renamer_frame.destroy()
  end

  local entity = get_renamer_entity(player)
  if not (entity and entity.valid) then
    storage.renamer[player.index] = nil
    return
  end

  local frame = player.gui.screen.add{
    type = "frame",
    name = "renamer_frame",
    direction = "vertical"
  }
  frame.style.padding = 12

  local titlebar = frame.add{
    type = "flow",
    name = "renamer_titlebar_flow",
    direction = "horizontal"
  }

  local title = titlebar.add{
    type = "label",
    caption = "Tune Channel (Press Enter)",
    style = "frame_title"
  }
  title.drag_target = frame

  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space_header"
  }
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  filler.drag_target = frame

  titlebar.add{
    type = "sprite-button",
    name = "renamer_cancel",
    sprite = "utility/close",
    style = "frame_action_button"
  }

  local content = frame.add{
    type = "flow",
    name = "renamer_content_flow",
    direction = "horizontal"
  }
  content.style = "horizontal_flow"

  local textfield = content.add{
    type = "textfield",
    name = "renamer_textfield",
    text = entity.backer_name or default_channel_name
  }
  textfield.style.width = 200

  local old_label = content.add{
    type = "label",
    name = "renamer_old_textfield",
    caption = entity.backer_name or default_channel_name
  }
  old_label.visible = false
  old_label.style.width = 0
  old_label.style.height = 0

  local commit = content.add{
    type = "sprite-button",
    name = "renamer_commit",
    sprite = "renamer-return-key",
    style = "tool_button",
    tooltip = {"renamer-gui-tooltips.commit"}
  }
  commit.style.top_margin = 1

  textfield.select_all()
  textfield.focus()
  frame.force_auto_center()
  player.opened = frame
end

local function CancelRename(player)
  if player.gui.screen.renamer_frame then
    player.gui.screen.renamer_frame.destroy()
  end
  storage.renamer[player.index] = nil
end

local function CommitRename(player)
  if not player.gui.screen.renamer_frame then return end

  local entity = get_renamer_entity(player)
  if not (entity and entity.valid) then
    CancelRename(player)
    return
  end

  if not entity.is_connected_to_electric_network() then
    game.print("Can't tune a tower that is not powered up")
    CancelRename(player)
    return
  end

  local content = player.gui.screen.renamer_frame.renamer_content_flow
  local new_channel = content.renamer_textfield.text
  local old_channel = content.renamer_old_textfield.caption

  entity.backer_name = new_channel
  content.renamer_old_textfield.caption = new_channel

  if old_channel ~= default_channel_name and old_channel ~= nil then
    ProcessFullLinkMesh(old_channel)
    debug_print("Remeshing previous channel: " .. old_channel)
  end

  if new_channel ~= default_channel_name then
    ProcessFullLinkMesh(new_channel)
    debug_print("Remeshing new channel: " .. new_channel)
  end

  UnifiedRenderCleanup(entity.unit_number)

  local label = ""
  if #entity.backer_name > 0 then
    label = string.sub(entity.backer_name, 1, 3)
  end

  local obj = AddTowerText(entity, label)
  if obj then
    storage.renderings_by_target[entity.unit_number] = obj
  end

  player.gui.screen.renamer_frame.destroy()
  storage.renamer[player.index] = nil
end

local function ResetRename(player)
  if not player.gui.screen.renamer_frame then return end

  local textfield = player.gui.screen.renamer_frame.renamer_content_flow.renamer_textfield
  local entity = get_renamer_entity(player)
  if entity and entity.valid then
    textfield.text = entity.backer_name or default_channel_name
  else
    textfield.text = default_channel_name
  end
  textfield.select_all()
  textfield.focus()
end

------------------------------------------------------------
-- GUI / HOTKEY EVENTS
------------------------------------------------------------

script.on_event("rename", function(event)
  local player = game.players[event.player_index]
  if player.gui.screen.renamer_frame then
    player.gui.screen.renamer_frame.destroy()
  end

  local selection = player.selected
  if selection and selection.valid and selection.name == "wireless-circuit-tower" then
    set_renamer_target(player, selection)
    SpawnGUI(player)
  end
end)

script.on_event("rename-mouse", function(event)
  local player = game.players[event.player_index]
  if player.gui.screen.renamer_frame then
    player.gui.screen.renamer_frame.destroy()
  end

  local selection = player.selected
  if selection and selection.valid and selection.name == "wireless-circuit-tower" then
    set_renamer_target(player, selection)
    SpawnGUI(player)
  end
end)

script.on_event("remove-artifacts", function(event)
  TidyUpFlashers()
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
  if event.element and event.element.name == "renamer_textfield" then
    CommitRename(game.players[event.player_index])
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.name == "renamer_textfield" then
    CancelRename(game.players[event.player_index])
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  if not (event.element and event.element.valid) then return end

  if event.element.name == "renamer_cancel" then
    CancelRename(player)
  elseif event.element.name == "renamer_commit" then
    CommitRename(player)
  end
end)