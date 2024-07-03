local handler = require("event_handler")
lib = require("__tier-generator__.library")

handler.add_lib(require("__tier-generator__.global"))
handler.add_lib(lib)
handler.add_lib(require("__gui-modules__.gui"))
handler.add_lib(require("__tier-generator__.interface.tierMenu"))
handler.add_lib(require("__tier-generator__.interface.tierConfig"))

-- require("__tier-generator__.calculation.ErrorFinder")