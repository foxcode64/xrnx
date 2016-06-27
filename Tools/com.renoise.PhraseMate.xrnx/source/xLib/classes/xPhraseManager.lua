--[[============================================================================
xPhraseManager
============================================================================]]--

--[[--

This class will assist in managing phrases, phrase mappings
.
#


Note that some methods only work with the selected instrument. This is a 
API limitation which would stands until we can determine the selected phrase 
without having to rely on the global 'selected_phrase/_index' property

See also: 
http://forum.renoise.com/index.php/topic/26329-the-api-wishlist-thread/?p=221484


--]]

--==============================================================================

class 'xPhraseManager'

--------------------------------------------------------------------------------
-- Retrieve the next available phrase mapping, based on current criteria
-- @param instr_idx (int), index of instrument 
-- @param insert_range (int), the size of the mapping in semitones
-- @param keymap_offset (int), start search from this note [first, if nil]
-- @return table{} or nil (if not able to find room)
-- @return int, the index where we can insert

function xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)
  TRACE("xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)",instr_idx,insert_range,keymap_offset)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not locate instrument"
  end

  -- provide defaults...
  if not keymap_offset then
    keymap_offset = 0
  end
  if not insert_range then
    insert_range = 12 
  end

  -- find empty space from the selected phrase and upwards
  -- (nb: phrase mappings are always ordered by note)
  local phrase_idx = nil
  --local insert_idx = 1
  local max_note = 119
  local begin_at = nil
  local stop_at = nil
  local prev_end = nil
  for k,v in ipairs(instr.phrase_mappings) do
    --print(">>> check mapping",v.note_range[1],v.note_range[2])
    if (v.note_range[2] >= keymap_offset) then      
      if not prev_end then
        prev_end = v.note_range[1]-1
      end
      if not begin_at 
        and (v.note_range[1] > prev_end+1) 
      then
        begin_at = prev_end+1
        stop_at = v.note_range[1]-1
        --print(">>> found room between",begin_at,stop_at)
        phrase_idx = k
        break
      else
        --print(">>> no room at",v.note_range[1],v.note_range[2])
      end
      prev_end = v.note_range[2]
    else
      --print(">>> less than keymap_offset")
      local next_mapping = instr.phrase_mappings[k+1]
      if next_mapping 
        and (next_mapping.note_range[1] > keymap_offset)
      then
        prev_end = keymap_offset-1 --v.note_range[2]
      end

    end
  end
  
  if not begin_at then
    begin_at = math.max(keymap_offset,(prev_end) and prev_end+1 or 0)
    if table.is_empty(instr.phrase_mappings) then
      phrase_idx = 1
    else
      phrase_idx = #instr.phrase_mappings+1
    end
    --print(">>> found begin_at",begin_at,phrase_idx)
  end
  if not stop_at then
    stop_at = begin_at + insert_range - 1
    --print(">>> found stop_at",stop_at)
  end

  stop_at = math.min(119,stop_at)

  if (stop_at-begin_at < insert_range) then
    -- another phrase appears within our range
    insert_range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    insert_range = max_note-prev_end-1
  end

  -- no room for the start
  if (begin_at > 119) then
    return false,"There is no more room for phrase mapping"
  end

  local note_range = {begin_at,begin_at+insert_range}
  --print(">>> note_range...",rprint(note_range))

  return note_range,phrase_idx

end

--------------------------------------------------------------------------------
--- Automatically add a new phrase to the specified instrument 
-- @param instr_idx (int), index of instrument 
-- @param create_keymap (bool), add mapping 
-- @param insert_range (int), size of mappings (in semitones)
-- @param keymap_offset (int), starting note (0-120)
-- @return 
--  + InstrumentPhrase, the resulting phrase object
--  + int, the phrase index
--  or nil if failed

function xPhraseManager.auto_insert_phrase(instr_idx,create_keymap,insert_range,keymap_offset)
  TRACE("xPhraseManager.auto_insert_phrase(instr_idx,create_keymap,insert_range,keymap_offset)",instr_idx,create_keymap,insert_range,keymap_offset)

  local instr = rns.instruments[instr_idx]
  if not instr then
    local msg = "Failed to allocate a phrase (could not locate instrument)"
    return false,err
  end

  local vphrase,vphrase_idx = nil,nil
  if create_keymap then
    vphrase,vphrase_idx = xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)
    if not vphrase then
      local err = "Failed to allocate a phrase (no more room left?)"
      return false,err
    end
  else
    vphrase_idx = (#instr.phrases > 0) and #instr.phrases+1 or 1
    --print(">>> vphrase_idx",vphrase_idx)
  end
  
  local phrase = instr:insert_phrase_at(vphrase_idx)
  if (create_keymap and renoise.API_VERSION > 4) then
    instr:insert_phrase_mapping_at(#instr.phrase_mappings+1,phrase)
  end
  if (create_keymap or renoise.API_VERSION <= 4) then
    phrase.mapping.note_range = {
      vphrase[1],
      vphrase[2]
    }
    phrase.mapping.base_note = vphrase[1]
  end
  phrase:clear() -- clear default C-4 

  return phrase,vphrase_idx

end


--------------------------------------------------------------------------------
-- Select previous phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_previous_phrase()
  TRACE("xPhraseManager.select_previous_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx then
    return false,"No phrase have been selected"
  end

  phrase_idx = math.max(1,phrase_idx-1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx

end

--------------------------------------------------------------------------------
-- Select previous/next phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_next_phrase()
  TRACE("xPhraseManager.select_next_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx then
    return false,"No phrase have been selected"
  end

  phrase_idx = math.min(#instr.phrases,phrase_idx+1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx
  

end

--------------------------------------------------------------------------------
-- Select next phrase mapping as it appears in phrase bar

function xPhraseManager.select_next_phrase_mapping()
  TRACE("xPhraseManager.select_next_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase.mapping then
    return false,"No mapping has been assigned to selected phrase"
  end

  local lowest_note = nil
  local candidates = {}
  for k,v in ipairs(instr.phrases) do
    if v.mapping
      and (v.mapping.note_range[1] > phrase.mapping.note_range[1]) 
    then
      candidates[v.mapping.note_range[1]] = {
        phrase = v,
        index = k,
      }
      if not lowest_note then
        lowest_note = v.mapping.note_range[1]
      end
      lowest_note = math.min(lowest_note,v.mapping.note_range[1])
    end
  end

  if not table.is_empty(candidates) then
    rns.selected_phrase_index = candidates[lowest_note].index
  end

end

--------------------------------------------------------------------------------
-- Select previous phrase mapping as it appears in phrase bar

function xPhraseManager.select_previous_phrase_mapping()
  TRACE("xPhraseManager.select_previous_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase.mapping then
    return false,"No mapping has been assigned to selected phrase"
  end

  local highest_note = nil
  local candidates = {}
  for k,v in ipairs(instr.phrases) do
    if v.mapping
      and (v.mapping.note_range[1] < phrase.mapping.note_range[1]) 
    then
      candidates[v.mapping.note_range[1]] = {
        phrase = v,
        index = k,
      }
      if not highest_note then
        highest_note = v.mapping.note_range[1]
      end
      highest_note = math.max(highest_note,v.mapping.note_range[1])
    end
  end

  if not table.is_empty(candidates) then
    rns.selected_phrase_index = candidates[highest_note].index
  end

end



--------------------------------------------------------------------------------

function xPhraseManager.set_selected_phrase(idx)
  TRACE("xPhraseManager.set_selected_phrase(idx)",idx)

  local instr = rns.selected_instrument
  if instr.phrases[idx] then
    rns.selected_phrase_index = idx
  end

end

--------------------------------------------------------------------------------
-- API5: Using the mapping index to specify the selected phrase

function xPhraseManager.set_selected_phrase_by_mapping_index(idx)
  TRACE("xPhraseManager.set_selected_phrase_by_mapping_index(idx)",idx)

  local instr = rns.selected_instrument
  local mapping = instr.phrase_mappings[idx]
  if not mapping then
    return false,"Could not find the specified phrase mapping"
  end
  
  for k,v in ipairs(instr.phrases) do
    if (rawequal(v,mapping.phrase)) then
      rns.selected_phrase_index = k
    end
  end

end

--------------------------------------------------------------------------------
-- Delete the currently selected phrase

function xPhraseManager.delete_selected_phrase()
  TRACE("xPhraseManager.delete_selected_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx 
    and instr.phrases[phrase_idx]) 
  then
    instr:delete_phrase_at(phrase_idx)
  end

end

--------------------------------------------------------------------------------
-- Delete the currently selected phrase mapping
-- TODO in API4+, delete phrase + mapping

function xPhraseManager.delete_selected_phrase_mapping()
  TRACE("xPhraseManager.delete_selected_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx 
    and instr.phrases[phrase_idx]
    and instr.phrases[phrase_idx].mapping) 
  then
    instr:delete_phrase_mapping_at(phrase_idx)
  end

end

--------------------------------------------------------------------------------
-- @return renoise.InstrumentPhraseMapping or nil

function xPhraseManager.get_selected_mapping()
  TRACE("xPhraseManager.get_selected_mapping()")

  local phrase = rns.selected_phrase
  if phrase then
    return phrase.mapping
  end

end

--------------------------------------------------------------------------------
-- @return int or nil

function xPhraseManager.get_selected_mapping_index()
  TRACE("xPhraseManager.get_selected_mapping_index()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase then
    return 
  end

  local mapping = phrase.mapping
  if not mapping then
    return
  end

  for k,v in ipairs(instr.phrase_mappings) do
    if (rawequal(phrase,v.phrase)) then
      return k
    end 
  end

end

--------------------------------------------------------------------------------
-- @param mode (int), renoise.Instrument.PHRASES_xxx
-- @return int or nil
-- @return string (error message when failed)

function xPhraseManager.set_playback_mode(mode)
  TRACE("xPhraseManager.set_playback_mode(mode)",mode)

  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end

  if (rns.selected_instrument.phrase_playback_mode == mode) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
  else
    rns.selected_instrument.phrase_playback_mode = mode
  end

end

--------------------------------------------------------------------------------
-- locate duplicate phrases within instrument
-- @param instr
-- @return table containing indices 

function xPhraseManager.find_duplicates(instr)

end
