-- @description Intelli Chorus Recorder (Accessible & Modular Edition)
-- @version 2.0
-- @author Unique Creators (www.uniquecreators.net)
-- @changelog
--  + v2.0: Major refactor for modularity, maintainability, and scalability.
--    - Introduced an accessible step-by-step setup wizard.
--    - Added session saving/loading via an external .ini file.
--    - Decoupled UI, core logic, and configuration into separate modules.
--    - Implemented robust, user-friendly error handling.
--  + v1.0: Initial release by Uniqueboy.
-- @about
--  Intelli Chorus Recorder automates recording chorus layers with punch-in logic,
--  track creation, naming, panning, and spoken feedback.
--  This version is fully modular and designed for community contribution.
-- @provides
--  [main] .
--  config.lua
--  ui_wizard.lua
--  core_logic.lua
--  lib/utils.lua
--  session.ini
--  README.md
--  CONTRIBUTING.md

-------------------------------------------------------------------------------
-- SCRIPT INITIALIZATION
-------------------------------------------------------------------------------

-- CRITICAL: Get the path of the currently running script.
-- This is the key to finding all other module files.
local SCRIPT_PATH = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")

-- A robust module loader that uses the script's absolute path.
local function loadModule(moduleName)
  -- Get the correct path separator for the current OS ('\' or '/').
  local separator = package.config:sub(1, 1)
  -- Replace dots in the module name with the correct separator.
  local modulePath = moduleName:gsub("%.", separator)

  -- Construct the full, valid path.
  local fullPath = SCRIPT_PATH .. modulePath .. ".lua"  
  local ok, module = pcall(dofile, fullPath)
  if not ok then
    reaper.ShowMessageBox("Fatal Error: Could not load the required module:\n" .. moduleName .. "\n\nPath tried:\n" .. fullPath .. "\n\nPlease ensure all script files are in the correct directory.", "Module Load Error", 0)
    return nil
  end
  return module
end

-------------------------------------------------------------------------------
-- MAIN EXECUTION
-------------------------------------------------------------------------------

-- Load the utils library first, as it's needed for error handling.
local utils = loadModule("lib.utils")
if not utils then return end

-- Prevent multiple instances of the script from running.
if _G.__INTELLICHORUS_RUNNING__ then
  utils.ShowMessage('info', "Notice", "Intelli Chorus Recorder is already running!")
  return
end
_G.__INTELLICHORUS_RUNNING__ = true


-- Main script execution block, wrapped for error catching.
local function main()
  -- Load the rest of the modules.
  local config = loadModule("config")
  local ui = loadModule("ui_wizard")
  local core = loadModule("core_logic")
  if not (config and ui and core) then return end -- Abort if any module failed to load.
  
  -- Pass dependencies to modules (Dependency Injection).
  ui.init(utils, config)
  core.init(utils, config)

  -- Check for the time selection prerequisite.
  local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if timeSelStart == timeSelEnd then
    utils.ShowMessage('error', "Prerequisite Missing", "You must create a time selection before starting the recorder.")
    return
  end

  reaper.Undo_BeginBlock()

  -- Get settings from the user via the UI wizard.
  local ok, settings = ui.getSettings(SCRIPT_PATH)
  if not ok then
    settings = ui.runSetupWizard(config.defaults)
  end
  -- With valid settings, execute the core logic.
  local success, message = core.run(settings, timeSelStart, timeSelEnd)
  if not success then
    -- An error occurred during the core logic execution.
    utils.ShowMessage('error', "Recording Error", message)
    reaper.Undo_EndBlock("Intelli Chorus: Failed", -1)
  else
    -- Success! The async process has started.
    reaper.Undo_EndBlock("Intelli Chorus: Operation Started", -1)
  end
end

-- Cleanup function to be called when the script exits, for any reason.
reaper.atexit(function()
  _G.__INTELLICHORUS_RUNNING__ = nil
end)

-- Run the main function and catch any unexpected errors.
local ok, err = pcall(main)
if not ok then
  if utils and utils.ShowMessage then
      utils.ShowMessage('error', "Critical Script Failure", "An unexpected error occurred:\n\n" .. tostring(err))
  else
      reaper.ShowMessageBox("A critical error occurred:\n\n" .. tostring(err), "Critical Script Failure", 0)
  end
  _G.__INTELLICHORUS_RUNNING__ = nil
end
