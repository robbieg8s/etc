--- Configure console and alert fonts
-- I don't see any other settings for this, so do it as early as possible

hs.console.consoleFont({ name = "Menlo", size = 18 })
hs.alert.defaultStyle.strokeWidth = 8
hs.alert.defaultStyle.textFont = "Menlo"
hs.alert.defaultStyle.textSize = 64

--- General purpose utility class for batching changes and triggering an update

local Batcher = {}
Batcher.__index = Batcher
function Batcher:new(delay, description)
  local o = {}
  setmetatable(o, self)
  o.lastAlert = nil
  o.description = description
  o.reloadTimer = hs.timer.delayed.new(delay, function () o:fire() end)
  return o
end
function Batcher:alert(message)
  self.lastAlert = self.lastAlert and hs.alert.closeSpecific(self.lastAlert)
  self.lastAlert = hs.alert(message)
end
function Batcher:trigger()
  if self.reloadTimer:running() then
    self:alert(self.description .. " pending")
  else
    self:alert(self.description .. " queued")
  end
  self.reloadTimer:start()
end

--- Reload when configuration changes
-- Similar to the ReloadConfiguration spoon, but implemented on Batcher

local reloadConfigurationBatcher = Batcher:new(1, "Hammerspoon configuration change")
function reloadConfigurationBatcher:fire()
  hs.reload()
end
reloadConfigurationBatcher.configurationWatcher = hs.pathwatcher.new(
  hs.configdir,
  hs.fnutils.partial(reloadConfigurationBatcher.trigger, reloadConfigurationBatcher)
):start()

---- Enable CLI
-- This provides the message port for
-- /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs
-- See also bin/hammerspoon-alert

require("hs.ipc")

--- Notify that everything is loaded

hs.alert.show("Hammerspoon configuration loaded")
