# Lua Socket Server and API for Bizhawk

The Lua socket server usually extracted by Bizhook for use with [AutoHawk](https://github.com/SuperBlueHenBros/middle-tier) in via [AutoHawk-API-Client](https://github.com/SuperBlueHenBros/Bizhook). 

## Information

hook.lua is a based on OpenDisrupt's Bizhook library but is not compatible with the original API located on [GitLab](https://gitlab.com/OpenDisrupt/bizhook). Please don't bother them regarding any issues encountered when using this fork. This implementation has been completely reworked to support manual frame advancement and automated input as supported in [our fork of the Bizhook API](https://github.com/SuperBlueHenBros/Bizhook). Full credit to [Maximillian Strand](https://gitlab.com/deepadmax) and [Autumn](https://github.com/rosemash/luape) for getting this originally working. 

## Usage

### Manual Server Start-Up

#### Opening socket

In Bizhawk, go to `Tools` > `Lua Console`. Select `Open script` and open `hook.lua` from the exported components.

##### Is it working?

If it starts successfully, you should see output in Bizhawk's Lua console stating it is running.

**Note**: Do not try to communicate with the socket *before* the text has disappeared, as it isn't actually opened yet. The message is there to make it clear that the script is running successfully.

### Automatic Server Start-Up

Automatically launched with Bizhawk via [AutoHawk](https://github.com/SuperBlueHenBros/middle-tier) once configured.