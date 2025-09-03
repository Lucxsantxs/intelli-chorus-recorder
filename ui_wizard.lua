-- UI Wizard Module for Intelli Chorus Recorder
-- Handles all user interaction in an accessible, step-by-step manner.
-- Also manages loading and saving settings from the .ini file.

local ui = {}
local utils, config, iniPath, savedSettings, settingsToUse -- Populated by init()

-- Simple INI parser/writer
local function parseIni(filePath)
  local settings = {}
  local file = io.open(filePath, "r")
  if not file then return nil end
  for line in file:lines() do
    local key, value = line:match("([^=]+)=(.*)")
    if key and value then
      key = key:gsub("^%s*(.-)%s*$", "%1")
      value = value:gsub("^%s*(.-)%s*$", "%1")
      if value == "true" then
        settings[key] = true
      elseif value == "false" then
        settings[key] = false
      elseif tonumber(value) then
        settings[key] = tonumber(value)
      else
        settings[key] = value
      end
    end
  end
  file:close()
  return settings
end

local function writeIni(filePath, settings)
  local file = io.open(filePath, "w")
  if not file then return false, "Could not open .ini file for writing." end
  for key, value in pairs(settings) do
    file:write(key .. "=" .. tostring(value) .. "\n")
  end
  file:close()
  return true
end

-- Helper functions for prompting
local function promptForNumber(title, prompt, default, min, max)
  while true do
    local ok, result = reaper.GetUserInputs(title, 1, prompt, tostring(default))
    if not ok then return nil end -- User cancelled
    
    local num = tonumber(result)
    if not num then
      utils.ShowMessage('error', config.strings.title_error, config.strings.error_nan)
    elseif num < min or num > max then
      utils.ShowMessage('error', config.strings.title_error, string.format(config.strings.error_out_of_range, min, max))
    else
      return num
    end
  end
end

local function promptForString(title, prompt, default, minLength)
  while true do
    local ok, result = reaper.GetUserInputs(title, 1, prompt, default)
    if not ok then return nil end -- User cancelled
    
    if #result < minLength then
      utils.ShowMessage('error', config.strings.title_error, config.strings.error_string_empty)
    else
      return result
    end
  end
end

local function promptYesNo(title, prompt)
  local result = utils.ShowMessage('question', title, prompt)
  if result == 7 then return nil end -- User clicked Cancel/closed dialog
  return result == 6 -- 6 = Yes
end

-- Main function to run the setup wizard
function ui.runSetupWizard(currentSettings)
  local s = {}
  local v = config.validation
  local str = config.strings
  local title = str.title_setup

  s.trackCount = promptForNumber(title, str.prompt_track_count, currentSettings.trackCount, v.trackCount.min, v.trackCount.max)
  if s.trackCount == nil then return nil end

  s.maxPan = promptForNumber(title, str.prompt_max_pan, currentSettings.maxPan, v.maxPan.min, v.maxPan.max)
  if s.maxPan == nil then return nil end

  local maxInputs = reaper.GetNumAudioInputs()
  if v.inputChannel.max ~= maxInputs then v.inputChannel.max = maxInputs end
  s.inputChannel = promptForNumber(title, str.prompt_input_channel, currentSettings.inputChannel, v.inputChannel.min, v.inputChannel.max)
  if s.inputChannel == nil then return nil end
  if s.inputChannel > maxInputs then
      utils.ShowMessage('error', str.title_error, string.format(str.error_invalid_input, maxInputs))
      return nil
  end

  s.trackName = promptForString(title, str.prompt_track_name, currentSettings.trackName, v.trackName.minLength)
  if s.trackName == nil then return nil end

  s.wrapFolder = promptYesNo(title, str.prompt_wrap_folder)
  s.wrapFolder = s.wrapFolder == true
  
  s.mutePrevious = promptYesNo(title, str.prompt_mute_previous)
s.mutePrevious = s.mutePrevious == true

  s.countInOnce = promptYesNo(title, str.prompt_count_in_once)
s.countInOnce = s.countInOnce == true

  s.saveAfter = promptYesNo(title, str.prompt_save_after)
s.saveAfter = s.saveAfter == true

  s.inform = promptYesNo(title, str.prompt_inform)
s.inform = s.inform == true

  local shouldSave = promptYesNo(config.strings.title_confirm, config.strings.prompt_save_settings)
  if shouldSave then
    writeIni(iniPath, s)
  end

  return s
end

-- The main entry point for this module
function ui.getSettings(scriptPath)
      iniPath = scriptPath .. "session.ini"
  savedSettings = parseIni(iniPath)
  settingsToUse = savedSettings or config.defaults

  if savedSettings then
    local useDefaults = promptYesNo(config.strings.title_confirm, config.strings.prompt_load_defaults)
    if useDefaults == nil then return false end -- Cancelled
    if useDefaults then
      return true, savedSettings
    end
  end
end

function ui.init(_utils, _config)
  utils = _utils
  config = _config
end

return ui
