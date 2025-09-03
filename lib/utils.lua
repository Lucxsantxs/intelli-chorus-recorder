-- General Utilities Library for REAPER Scripts
-- Contains reusable helper functions.

local utils = {}

--[[
  Shows a message box to the user. A wrapper around the REAPER API.
  @param type string: 'info', 'error', or 'question'
  @param title string: The title of the dialog window.
  @param message string: The message to display.
  @return number: The button pressed (6=Yes, 7=No, 1=OK, 2=Cancel).
--]]
function utils.ShowMessage(type, title, message)
  local typeMap = {
    info = 0, -- OK button
    error = 0, -- OK button
    question = 4, -- Yes/No/Cancel buttons
  }
  local dialogType = typeMap[type] or 0
  return reaper.ShowMessageBox(message, title, dialogType)
end

--[[
  Provides spoken feedback via OSARA or falls back to the console.
  @param text string: The text to speak.
  @param inform boolean: If false, the function does nothing.
--]]
function utils.speak(text, inform)
  if not inform then return end
  if reaper.osara_outputMessage then
    reaper.osara_outputMessage(text)
  else
    reaper.ShowConsoleMsg(text .. "\n")
  end
end

return utils

