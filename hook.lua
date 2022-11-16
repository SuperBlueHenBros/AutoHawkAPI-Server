---------------------------------------------------------
-- The Lua side of things would not have been possible --
-- if it weren't for the help of one lovely individual --
--                                                     --
-- Tumn                                                --
--   * Matrix: @autumn:raincloud.dev                   --
--   * GitHub: github.com/rosemash                     --
---------------------------------------------------------

address, port = "127.0.0.1", 16154

---------------------------------------------------------
-- # HOW TO USE                                        --
--                                                     --
-- Requests can be made by connecting to the socket    --
-- at the specified address and port and sending       --
-- a message following the pattern below.              --
--                                                     --
--    OBS! Every request requires a new connection.    --
--                                                     --
--                                                     --
-- Pattern:  DOMN/ADDR/TSLE/VLUE                       --
--                                                     --
-- DOMN  - Memory domain                               --
-- ADDR  - Address                                     --
-- TSLE--.-------------------.                         --
--       Type:               Signage:                  --
--       | * [b]yte            * [u]nsigned            --
--       | * [i]nteger         * [s]igned              --
--       | * [f]loat                                   --
--       |                                             --
--       .-------------------.                         --
--       Size:               Endianness:               --
--         * [1] byte          * [l]ittle endian       --
--         * [2] bytes         * [b]ig endian          --
--         * [3] bytes                                 --
--         * [4] bytes                                 --
--                                                     --
--  VLUE  - Integer or float, ex. 12 or -1.2           --
--                                                     --
--                                                     --
--  # EXAMPLES                                         --
--                                                     --
--   VRAM/11423051/iu4b/23                             --
--     Write (23) to (11423051) in (VRAM)              --
--       an [i]nteger, [u]nsigned,                     --
--       [4] bytes long and [b]ig endian               --
--                                                     --
--   WRAM/21512962/fs2l/                               --
--     Read from (21512962) in (WRAM)                  --
--       a [f]loat, [s]igned,                          --
--       [2] bytes long and [l]ittle endian            --
--                                                     --
---------------------------------------------------------


-- Include necessary socket modules using a hack

local version = _VERSION:match("%d+%.%d+")

package.path = 'lua_modules/share/lua/'
			.. version
			.. '/?.lua;lua_modules/share/lua/'
			.. version
			.. '/?/init.lua;'
			.. package.path

package.cpath = 'lua_modules/lib/lua/'
			.. version
			.. '/?.so;'
			.. package.cpath


-- Import modules and set up socket connection

socket = require("socket")
copas = require("copas")

server = socket.bind(address, port)

-- Query types
qtype = {
    INPUT = 0;
    READ = 1;
    WRITE = 2;
    CLIENT = 3;
}

-- Cient command types
ctype = {
	ADVANCE = 0;
}

-- Response codes
rcodes = {
	INPUT 	= 0;  -- Successfully wrote to memory
	BYTE    = 1;  -- Successfully read byte
	INTEGER = 2;  -- Successfully read integer
	CLIENT  = 3;  -- Successfully controlled client
	ERROR   = 4;  -- Generic error
}


function format_response(code, message)
	-- emu.frameadvance()
	-- Format response code and message into a valid response
	-- console.log(code, "_", message)
	return tostring(code) .. '_' .. tostring(message)
end

local function handleRequest(data)
	-- Handle incoming requests for reading from
	-- and writing to memory with the BizHawk emulator
	form = tonumber(string.match(data, "(%d)%/.+"))
	if form == qtype["INPUT"] then
		-- TODO: make a proper lua table 
		query_type, button_name, button_state = string.match(data, "(%d)%/(.+)%/(.+)%/")
		button_table = {}
		button_table[button_name] = button_state
		-- console.log("Sending Input:")
		-- console.log(button_table)
	elseif form == qtype["READ"] then
		query_type, domain, mem_address = string.match(data, "(%d)%/(.+)%/(.+)%/")
		mem_address = tonumber(mem_address)
	elseif form == qtype["CLIENT"] then
		query_type, client_type = string.match(data, "(%d)%/(%d)%/")
		client_type = tonumber(client_type)
	end

	query_type = tonumber(query_type)
	
	-- Use default domain if none is provided
	if domain == "" then
		domain = nil
	end

			
	-- [ INPUT ]
	if form == qtype["INPUT"] then
		return format_response(
			rcodes.INPUT,
			joypad.set(button_table)
	)
	end
	-- [ READ ]
	if form == qtype["READ"] then
		-- [ BYTE ]
		return format_response(
			rcodes.BYTE,
			memory.readbyte(mem_address, domain)
		)
	end
	-- [ CLIENT ]
	if form == qtype["CLIENT"] then
		-- [ FRAME ADVANCE ]
		if client_type == ctype["ADVANCE"] then
			emu.frameadvance()
			return format_response(
				rcodes.CLIENT,
				true
			)
		end
	end


	-- If nothing is matched,
	-- let the client know that something's gone wrong
	return format_response(rcodes.ERROR, 'INVALID_REQUEST')
end

local function clientHandler(client)
	-- Reads data until client is disconnected
	-- and processes the data with handleRequest

	local data = ""
	-- 	-- 
	while true do
		-- Read 1 byte at a time
		chunk, errmsg = client:receive(1)

		-- Quit reading if an error has occured
		-- or no data was received
		if not chunk then
			if errmsg == 'timeout' then
				break
			end
			
			print(('Socket error: %s'):format(errmsg))
			return
		end

		-- Append new byte to data
		data = data .. chunk
	end

	

	if not data then return end

	-- Handle the request
	-- and formulate a response
	response = handleRequest(data)

	if not response then return end

	-- Make sure response is string
	-- and send back response to client
	client:send(tostring(response))
end

console.log("Adding server")

copas.addserver(server, clientHandler)

console.log("Added server")

-- Open up socket with a clear sign
while emu.framecount() < 120 do
	gui.text(20, 20, '.Opening socket at ' .. address .. ':' .. port)
	emu.frameadvance()
end

console.log("Done showing intro")

-- I spent days trying to track down the origin of a mysterious error in copas
-- I've given up and just overriden its error handler as it kills performance
copas.setErrorHandler("", "")

console.log("Disabled COPAS error handler")

while true do
	-- Communicate with client
	local handled, errmsg = copas.step(0)

	if handled == nil then
		print(('Socket error: %s'):format(errmsg))
	end
	
	-- Advance the game by a frame
	-- emu.yield()
end