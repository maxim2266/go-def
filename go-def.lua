-- shell quoting
local function Q(s) --> quoted string
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- fail with a message
local function die(msg, ...)
	if select("#", ...) > 0 then
		msg = string.format(msg, ...)
	end

	io.stderr:write(arg[0]:match("[^/]+$"), ": [error] ", msg, "\n")
	os.exit(false)
end

-- conditional failure
local function die_if(cond, msg, ...)
	if cond then
		die(msg, ...)
	end
end

-- check return of a system function
local function just(ok, err, code, ...) --> all parameters
	if ok then
		return ok, err, code, ...
	end

	if math.type(code) == "integer" then
		die_if(err == "signal", "interrupted with signal %u", code)

		if err == "exit" then
			os.exit(code)
		end
	end

	die(err)
end

-- convert string to a positive integer
local function as_number(s) --> integer
	die_if(not s:match("^%d+$"), "invalid parameter: %q", s)
	return s | 0
end

-- ask "guru" tool for definition location
local function ask_guru(fname, line_no, line_pos) --> string
	-- find line
	local n, i = 0, 0
	local src = just(io.open(fname))
	local s = src:read("L")

	while s and i < line_no do
		n = n + #s
		s = src:read("L")
		i = i + 1
	end

	just(src:close())

	die_if(i < line_no, "file %q has only got %u lines in it", fname, i)

	if s then
		die_if(line_pos >= #s,
		       "invalid position %u: line %u is only %u bytes long", line_pos, line_no, #s)
	else
		die_if(line_pos > 0, "invalid position %u: line %u is empty", line_pos, line_no)
	end

	-- ask guru
	src = just(io.popen("guru definition " .. Q(fname) .. ":#" .. (n + line_pos)))
	s = src:read("a")

	just(src:close())
	return s
end

-- check parameters
if not arg[1] or not arg[2] or not arg[3] or arg[4] then
	die("This is a tool for Kate editor, do not use it standalone.")
end

-- get definition location string
local loc = ask_guru(arg[1], as_number(arg[2]), as_number(arg[3]))

-- launch editor
just(os.execute('kate 2>/dev/null ' .. Q(loc:match("^.-:%d+:%d+"))))
