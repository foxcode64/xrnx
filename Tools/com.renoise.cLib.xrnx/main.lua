--[[============================================================================
main.lua
============================================================================]]--

--[[

Unit-tests for the cLib library
.
#

TODO 
* capture results from asynchroneous test methods

PLANNED 
* turn tool into simple testrunner framework (class)


]]

_tests = table.create()
_test_path = "unit_tests"

_trace_filters = {".*"}
_clibroot = "source/cLib/classes/"
_vlibroot = "source/vLib/classes/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cFilesystem")
require (_vlibroot.."vDialog")

require ("source/TestRunner")

--------------------------------------------------------------------------------
-- test runner
--------------------------------------------------------------------------------

-- this string is assigned as the dialog title
APP_DISPLAY_NAME = "cLib"

-- TestRunner, the dialog containing the app 
local runner = nil


-- implementing preferences as a class only has benefits
-- (you can still use renoise.tool().preferences from anywhere...)   
local prefs = TestRunnerPrefs()
renoise.tool().preferences = prefs

rns = nil 

--------------------------------------------------------------------------------
-- Show the application UI 
--------------------------------------------------------------------------------

function show()

  -- set global reference to the renoise song
  rns = renoise.song()

  -- create dialog if it doesn't exist
  if not runner then
    runner = TestRunner{
      dialog_title = APP_DISPLAY_NAME,
      waiting_to_show_dialog = prefs.autostart.value,
      tests = _tests,
      test_path = _test_path,
    }
  end

  runner:show()
  
end

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..APP_DISPLAY_NAME,
  invoke = function()
    show()
  end  
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  rns = renoise.song()
  if prefs.autostart.value then
    show()
  end
end)

