-- Core Logic Module for Intelli Chorus Recorder
-- Handles all REAPER API interactions related to track creation and recording.
-- It receives a settings table and executes the recording process.

local core = {}
local utils, config -- Populated by init()

-- Local helper functions
local function calculatePan(index, total, maxPan)
  -- Handle simple edge cases first
  if total <= 1 then return 0 end -- A single track is always centered.
  local isRightChannel = (index % 2 == 0)
  if total == 2 then
    -- For exactly two tracks, pan them fully left and right.
    local panValue = maxPan / 100
    return isRightChannel and panValue or -panValue
  end
  -- For 3+ tracks, use the original formula's intent, but make it robust.
  local half = math.ceil(total / 2)
  local pairIndex = math.floor((index - 1) / 2) -- Which pair are we (0-indexed)
  -- The denominator is the number of panning "steps" from the center.
  -- For 4 tracks, half=2, steps=1. For 6 tracks, half=3, steps=2.
  local steps = half - 1
  if steps == 0 then steps = 1 end -- Prevent division by zero
  local panAmount = (maxPan / steps) * pairIndex
  -- Convert to REAPER's scale (-1.0 to 1.0)
  local panValue = panAmount / 100
  return isRightChannel and panValue or -panValue
end

local function createTracks(settings)
  local tracks = {}
  -- Create folder if needed
  if settings.wrapFolder then
    reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
    local folderTrack = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
    reaper.GetSetMediaTrackInfo_String(folderTrack, "P_NAME", settings.trackName .. " Folder", true)
    reaper.SetMediaTrackInfo_Value(folderTrack, "I_FOLDERDEPTH", 1)
  end

  -- Create tracks
  for i = 1, settings.trackCount do
    reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
    local track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
    local trackName = settings.trackName .. " " .. i
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", trackName, true)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", calculatePan(i, settings.trackCount, settings.maxPan))
    reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", settings.inputChannel - 1)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", 0)
    
    if settings.wrapFolder and i == settings.trackCount then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", -1)
    end
    table.insert(tracks, track)
  end
  return tracks
end

-- The main entry point for this module
function core.run(settings, timeSelStart, timeSelEnd)
    local originalRepeat = reaper.GetToggleCommandState(1068)
      local function restoreSettings()
    if originalRepeat == 1 then
      reaper.GetSetRepeat(1)
    end
  end

  -- 1. Prepare Environment
  if reaper.GetToggleCommandState(40364) == 0 then
    local enableMetronome = utils.ShowMessage('question', config.strings.title_metronome, config.strings.prompt_metronome_off)
    if enableMetronome == 7 then restoreSettings() end
    if enableMetronome == 6 then reaper.Main_OnCommand(40364, 0) end
  end

  if originalRepeat == 1 then reaper.GetSetRepeat(0) end  
  reaper.GetSetProjectInfo(0, "RECORD_MODE", 5, true) -- Tape mode
  reaper.Main_OnCommand(1016, 0) -- Stop
  reaper.ClearConsole()
  utils.speak(config.strings.feedback_started, settings.inform)

  -- 2. Create Tracks
  local tracks = createTracks(settings)
  if #tracks == 0 then restoreSettings()() return false, "Failed to create tracks." end

  -- 3. Recording Loop
  local currentTrackIndex = 1
  local countInPlayed = false

  local function recordNext()
    if currentTrackIndex > settings.trackCount then
      -- All recordings finished
      reaper.Main_OnCommand(40290, 0) -- Unarm all tracks
      -- Unmute all tracks if they are muted per user preference
            if settings.mutePrevious then
          for _, track in ipairs(tracks) do
              reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0) -- 0 = false (unmuted)
          end
      end
      reaper.SetEditCurPos(timeSelStart, true, false)
      if settings.saveAfter then 
        reaper.Main_OnCommand(40026, 0) -- Save Project
        utils.speak(config.strings.feedback_project_saved, settings.inform)
      end
restoreSettings()
      utils.speak(config.strings.feedback_complete, settings.inform)
      utils.ShowMessage('info', config.strings.title_complete, config.strings.feedback_complete)
      return
    end

    local track = tracks[currentTrackIndex]
    
    if (not countInPlayed) or (not settings.countInOnce) then
      reaper.Main_OnCommand(1016, 0)
    end

    reaper.PreventUIRefresh(1)
    reaper.Main_OnCommand(40290, 0); reaper.Main_OnCommand(40289, 0) -- Unarm/Unselect all
    reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
    reaper.PreventUIRefresh(-1)

    if settings.mutePrevious and currentTrackIndex > 1 then
      reaper.SetMediaTrackInfo_Value(tracks[currentTrackIndex - 1], "B_MUTE", 1)
    end
    
    local trackName = settings.trackName .. " " .. currentTrackIndex
    utils.speak(string.format(config.strings.feedback_recording, trackName), settings.inform)

    reaper.SetEditCurPos(timeSelStart, false, false)
    reaper.Main_OnCommand(1013, 0) -- Record
    
    local function monitor()
      if reaper.GetPlayState() == 0 then
        utils.speak(config.strings.feedback_cancelled, settings.inform)
restoreSettings()
        return
      end
      
      if reaper.GetPlayPosition() >= timeSelEnd then
        reaper.Main_OnCommand(1016, 0) -- Stop
        reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
        countInPlayed = true
        currentTrackIndex = currentTrackIndex + 1
        reaper.defer(recordNext) -- Schedule next recording
      else
        reaper.defer(monitor) -- Continue monitoring
      end
    end
    monitor()
  end
  
  reaper.defer(recordNext) -- Start the first recording pass
  
  -- The core logic is now running asynchronously. We return success to the main thread.
  return true, "Recording process initiated."
end

function core.init(_utils, _config)
  utils = _utils
  config = _config
end

return core

