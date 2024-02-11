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

---- Enable CLI
-- This provides the message port for
-- /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs
-- See also bin/hammerspoon-alert

require("hs.ipc")

--- Notify that everything is loaded

hs.alert.show("Hammerspoon configuration loaded")
