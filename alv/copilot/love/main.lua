package.path = "./?/init.lua;" .. package.path
require('moonscript')
local Copilot = require('alv.copilot.love').LoveCopilot
Copilot(arg):run()
