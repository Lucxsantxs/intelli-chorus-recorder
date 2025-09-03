-- Configuration file for Intelli Chorus Recorder
-- Contains default settings, validation rules, and all user-facing text strings.
-- This makes the script easy to customize and translate.

local M = {}

-- Factory default settings
-- These are used when no .ini file is found and for resetting.
M.defaults = {
  trackCount = 4,
  maxPan = 50,
  inputChannel = 1,
  wrapFolder = true,
  mutePrevious = false,
  countInOnce = true,
  saveAfter = false,
  trackName = "Chorus",
  inform = true
}

-- Validation rules for each setting
M.validation = {
  trackCount = { min = 1, max = 50, type = 'number' },
  maxPan = { min = 1, max = 100, type = 'number' },
  inputChannel = { min = 1, max = reaper.GetNumAudioInputs(), type = 'number' },
  trackName = { minLength = 1, type = 'string' }
}

-- All user-facing text strings for the UI Wizard
M.strings = {
  -- Window Titles
  title_setup = "Intelli Chorus Setup",
  title_confirm = "Confirm Settings",
  title_error = "Input Error",
  title_success = "Success",
  title_complete = "Recording Complete",
  title_metronome = "Metronome Check",

  -- Wizard Prompts
  prompt_load_defaults = "Load previously saved settings?",
  prompt_track_count = "Enter the number of tracks to record.",
  prompt_max_pan = "Enter the maximum pan width (1-100).",
  prompt_input_channel = "Enter the physical input channel number.",
  prompt_track_name = "Enter the base name for the tracks (e.g., 'Chorus').",
  prompt_wrap_folder = "Wrap the new tracks in a parent folder?",
  prompt_mute_previous = "Mute the previously recorded track while recording the next?",
  prompt_count_in_once = "Only play the count-in/pre-roll before the first take?",
  prompt_save_after = "Save the project automatically when all tracks are recorded?",
  prompt_inform = "Provide spoken feedback for each step (for screen readers)?",
  prompt_save_settings = "Save these settings as your new default?",
  
  -- Metronome
  prompt_metronome_off = "The metronome is OFF. Would you like to enable it for recording?",

  -- Feedback messages
  feedback_started = "Intelli Chorus started.",
  feedback_recording = "Recording %s...", -- %s will be replaced with track name
  feedback_cancelled = "Recording cancelled by user.",
  feedback_complete = "All chorus takes have been recorded.",
  feedback_project_saved = "Project saved.",

  -- Error messages
  error_nan = "Input must be a number.",
  error_out_of_range = "Number must be between %d and %d.",
  error_string_empty = "Track name cannot be empty.",
  error_invalid_input = "Invalid input channel. This project has %d available inputs.",
}

return M

