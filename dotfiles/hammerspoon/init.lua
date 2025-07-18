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

--- Audio changes

local audioBatcher = Batcher:new(2, "Audio configuration change")
-- Select by name or uid, we use both because for some devices (like Thronmax Pulse), the uid isn't stable,
-- and for others (like the built in microphone/speaker), the name depends on the device model. Uid here isn't
-- a UUID, for example, BuiltInSpeakerDevice.
function audioBatcher.findFirstAvailable(kind, devices, ...)
    for i, nameOrUid in ipairs({...}) do
        for j, device in ipairs(devices) do
            if ((device:name() == nameOrUid) or (device:uid() == nameOrUid)) then
                return device
            end
        end
    end
end
function audioBatcher:selectInput()
    local input = audioBatcher.findFirstAvailable(
        "Input",
        hs.audiodevice.allInputDevices(),
        "THRONMAX PULSE MICROPHONE",
        "BuiltInMicrophoneDevice")
    if (input ~= hs.audiodevice.defaultInputDevice()) then
        self.selectedInput = input
        self:trigger()
    end
end
function audioBatcher:selectOutput()
    local output = audioBatcher.findFirstAvailable(
        "Output",
        hs.audiodevice.allOutputDevices(),
        "External Headphones",
        "Creative Stage Air V2",
        "DELL U2723QE",
        "Beats Flex",
        "BuiltInSpeakerDevice")
    if (output ~= hs.audiodevice.defaultOutputDevice()) then
        self.selectedOutput = output
        self:trigger()
    end
end
function audioBatcher:change(event)
    self:selectInput()
    self:selectOutput()
end
function audioBatcher:fire()
    self.selectedInput:setDefaultInputDevice()
    self.selectedOutput:setDefaultOutputDevice()
    -- Ensure system sounds also go to the selected device
    self.selectedOutput:setDefaultEffectDevice()
    self:alert("🎙 " ..  hs.audiodevice.defaultInputDevice():name() .. "\n🔊 " ..  hs.audiodevice.defaultOutputDevice():name())
end
function audioBatcher:init()
    self.selectedInput = hs.audiodevice.defaultInputDevice()
    self.selectedOutput = hs.audiodevice.defaultOutputDevice()
    hs.audiodevice.watcher.setCallback(function (event) self:change(event) end)
    hs.audiodevice.watcher.start()
    self:change('init')
end
audioBatcher:init()

--- Local mail spool monitoring
-- This provides a path for surfacing background script notifications persistently

local mailMonitor = {}
function mailMonitor:checkSpool()
  local spoolFileAttributes = hs.fs.attributes(self.spoolFile)
  -- attributes can be nil, for example if the file doesn't exist, which happens if
  -- you've never recevied mail. Once you have received mail the file will hang
  -- around (at 0 size) if all mail is deleted.
  if ((spoolFileAttributes == nil) or (0 == hs.fs.attributes(self.spoolFile).size))
  then
    -- No mail, clear visible notifications
    self.menuBarIcon:removeFromMenuBar()
    self.menuBarIcon:setMenu({})
  else
    -- Got mail, set up a callback and process the mail queue
    local token = {}
    local updateCallback = hs.fnutils.partial(mailMonitor.updateMenu, self, token)
    -- You might think of using `mail -H` to look at the headers here, but mail checks
    -- ioctl(1, TIOCGWINSZ, ...) to get the width, and defaults to 80 if stdout isn't a
    -- tty, and afaics there is no override for this.
    -- https://github.com/apple-oss-distributions/mail_cmds/blob/mail_cmds-35/mail/main.c#L364
    local task = hs.task.new(
      "/usr/bin/awk", updateCallback, {
        -- So, we parse the spool ourselves using awk.
        -- According to man mbox and RFC822, headers are delimited by From_ line and a blank line.
        -- Lines starting with LWSP (space or htab) in the headers are part of the prior field (folded)
        [[
          # Variable subject is the text of the Subject: field
          # Variable state is the parser state
          # state = 0 Seeking From_ line (start of headers)
          # state = 1 In headers, seeking Subject: field
          # state = 2 In Subject: field, seeking end (body or another field)
          # state = 3 In headers, have Subject:, seeking body

          (state == 0) && /^From / { state = 1 ; next }
          (state == 0) { next }
          (state == 1) && /^Subject: / { subject = substr($0, 2 + length($1)) ; state = 2 ; next }
          (state == 2) && /^[ \t]/ { sub(/^[ \t]*/, "") ; subject = subject " " $0 ; next }
          (state == 2) { state = 3 }
          /^$/ { state = 0 ; print subject ; subject = "" }
        ]],
        self.spoolFile
      }
    ):start()
    if (task) then
      self.menuBarIcon:setMenu({ { title = "Checking ...", disabled = true } })
      self.token = token
    else
      print("mailMonitor:checkSpool Failed to launch spool check task, see above")
      self.menuBarIcon:setMenu({ { title = "Can't launch mail, see console", disabled = true } })
    end
    -- And put the visible notification back
    self.menuBarIcon:returnToMenuBar()
    self.menuBarIcon:setIcon(self.iconImage)
  end
end
function mailMonitor:updateMenu(token, exitCode, stdout, stderr)
  if (token ~= self.token) then
    -- this is purely informational
    print("mailMonitor:updateMenu token mismatch, ignoring update")
  else
    -- ok, this is the most recent invocation, so process the awk parse of the mail
    self.token = nil
    if (0 ~= exitCode) then
      print("mailMonitor:updateMenu exitCode " .. exitCode)
      print(stderr)
      self.menuBarIcon:setMenu({ { title = "Mail parse failed (" .. exitCode .. "), see console", disabled = true } })
    else
      local items = {}
      for mail in string.gmatch(stdout, "([^\n]*)\n") do
        table.insert(items, { title = mail })
      end
      self.menuBarIcon:setMenu(items)
    end
  end
end

mailMonitor.spoolFile = "/var/mail/" .. os.getenv("USER")
mailMonitor.menuBarIcon = hs.menubar.new(false)
mailMonitor.iconImage = hs.image.imageFromName(hs.image.systemImageNames.TouchBarNewMessageTemplate)
mailMonitor.configurationWatcher = hs.pathwatcher.new(
  mailMonitor.spoolFile,
  hs.fnutils.partial(mailMonitor.checkSpool, mailMonitor)
):start()
mailMonitor:checkSpool()

--- Mailto callback handler
-- Hammerspoon can provide the mailto: handler, so we direct it to the gmail web interface

-- To have macOS find this, you also need to set launchservices to call hammerspoon.
-- The macOS Mail App can set the default and offers hammerspoon as a choice.
-- This is checked by libexec/mailto-handler-check, called from libexec/weekly.

function handleMailto(scheme, host, params, fullUrl, senderPID)
  function encodeByte(char)
    return string.format("%%%02X", string.byte(char))
  end
  -- Gmail does not (iiuc as of this writing) provide a way to open the compose window
  -- within the inbox tab via a url. The url below gets Gmail to handle the mailto,
  -- which it does by opening a full tab compose window, which isn't great (because
  -- you can't see which account is going to send), but is workable.
  -- See https://stackoverflow.com/posts/70030094/revisions for more on gmail urls
  local gmailPrefix = "https://mail.google.com/mail/?extsrc=mailto&url="
  local gmailUrl = gmailPrefix .. fullUrl:gsub("[^0-9a-zA-Z ]", encodeByte)
  hs.urlevent.openURL(gmailUrl)
end

hs.urlevent.mailtoCallback = handleMailto

--- Enable CLI
-- This provides the message port for
-- /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs
-- See also bin/hammerspoon-alert

require("hs.ipc")

--- Window management functions and hotkeys

function normalizeWindow(screen, window)
  local frame = screen:frame()
  -- A few windows i like in particular positions
  local right1280 = function()
    -- Fixed width, pushed to the right edge
    local width = 1280
    frame.x = frame.x2 - width
    frame.w = width
  end
  local smallerUpperRight = function()
    -- Fixed width and height, pushed to the upper right, smaller than the whole laptop screen
    local width = 1024
    local height = 640
    frame.x = frame.x2 - width
    frame.w = width
    frame.h = height
  end
  local handlers = {
    ["com.googlecode.iterm2"] = function()
      -- iTerm
      -- This is 132 columns of Menlo 15, my current terminal font, plus the iTerm2 padding
      -- In priciple i can query the font geometry using osascript:
      --   ObjC.import('AppKit');
      --   $.NSFont.fontWithNameSize('Menlo',15.0). maximumAdvancement.width;
      -- but i'd still have to know the padding. Probably i should just use the iTerm API directly,
      -- but i've not yet invested in understanding that, and this is convenient.
      frame.w = 1213
    end,
    ["com.1password.1password"] = smallerUpperRight,
    ["com.apple.MobileSMS"] = right1280,
    ["com.apple.Terminal"] = function()
      -- Apple Terminal
      -- I have this configured for escalation for running unsigned binaries etc, this placement is
      -- ad hoc based on current font choice and avoiding interfering with iTerm.
      local width = 768
      local height = 768
      frame.x = frame.x2 - width
      frame.w = width
      frame.h = height
    end,
    ["com.apple.reminders"] = smallerUpperRight,
    ["com.kapeli.dashdoc"] = right1280,
    ["com.tinyspeck.slackmacgap"] = right1280,
    ["com.unity3d.unityhub"] = smallerUpperRight,
    ["org.whispersystems.signal-desktop"] = smallerUpperRight
  }
  local bundleId = window:application():bundleID()
  -- Make it easy to get the data you need to extend the handler map
  -- If this is useful outside this context, you could put extra info here also ...
  hs.pasteboard.setContents(bundleId)
  local handler = handlers[bundleId]
  if handler ~= nil then
    handler()
  -- else for everything else, just maximize - leave frame unchanged
  end
  window:setFrame(frame)
end

function normalizeCurrentWindow()
  -- main is screen with currently focused window
  local screen = hs.screen.mainScreen()
  local window = hs.window.frontmostWindow()
  normalizeWindow(screen, window)
end

function switchCurrentWindowScreen()
  local screen = hs.screen.mainScreen()
  local window = hs.window.frontmostWindow()
  -- No need to set duration, as the normalize makes everything happen fast anyway
  window:moveToScreen(screen:next())
  -- We need to pass values through, otherwise normalizeWindow sees stale values
  normalizeWindow(screen:next(), window)
end

hs.hotkey.bind({"ctrl"}, "pageup", "normalize window", normalizeCurrentWindow)
hs.hotkey.bind({"ctrl"}, "pagedown", "switch screen", switchCurrentWindowScreen)

--- Notify that everything is loaded

hs.alert.show("Hammerspoon configuration loaded")
