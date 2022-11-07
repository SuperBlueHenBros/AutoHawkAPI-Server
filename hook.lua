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


-- Response codes
rcodes = {
	WRITTEN = 0;  -- Successfully wrote to memory
	BYTE    = 1;  -- Successfully read byte
	INTEGER = 2;  -- Successfully read integer
	FLOAT   = 3;  -- Successfully read float
	ERROR   = 4;  -- Generic error
}

function mysplit (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function format_response(code, message)
	-- -- console.log(" ")
	-- -- console.log("format_response")
	emu.frameadvance()
	-- console.log("code:", code, "message:", message)
	-- Format response code and message into a valid response
	return tostring(code) .. '_' .. tostring(message)
end

local function handleRequest(data)
	-- Handle incoming requests for reading from
	-- and writing to memory with the BizHawk emulator

	-- console.log(" ")
	-- console.log("handleRequest:")
	-- -- console.log(data)

	split_data = mysplit(data, '/')
	-- console.log("split_data:")
	-- console.log(split_data)

	query_type = tonumber(split_data[1])
	domain = split_data[2]
	address = tonumber(split_data[3])
	
	-- Use default domain if none is provided
	if domain == "" then
		domain = nil
	end

	-- console.log("query_type:", query_type)
	-- console.log("domain:", domain)
	-- console.log("address:", address)

	-- [ INPUT ]
	if query_type == 0 then
		-- console.log("input")
	else
		-- console.log("read bytes")
		-- [ READ ]
		if query_type == 1 then

			-- [ BYTE ]
			return format_response(
				rcodes.BYTE,
				memory.readbyte(address, domain)
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
	-- -- console.log(" ")
	-- -- console.log("handing client")

	while true do
		-- Read 1 byte at a time
		chunk, errmsg = client:receive(1)

		emu.frameadvance()

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

	-- console.log("response", tostring(response))

	if not response then return end

	-- Make sure response is string
	-- and send back response to client
	client:send(tostring(response))
end

console.log("Adding server")

copas.addserver(server, clientHandler)

console.log("Displaying socket info")

-- Open up socket with a clear sign
while emu.framecount() < 600 do
	gui.text(20, 20, '.Opening socket at ' .. address .. ':' .. port)
	emu.frameadvance()
end

console.log("Done starting socket")

while true do
	-- Communicate with client
	local handled, errmsg = copas.step(0)
	if handled == nil then
		print(('Socket error: %s'):format(errmsg))
	end
	
	-- Advance the game by a frame
	emu.frameadvance()
end