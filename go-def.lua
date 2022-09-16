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

-- get offset from line and column
local function offset(fname, line, col) --> integer
	-- find line
	local n, i = 0, 0
	local src = just(io.open(fname))
	local s = src:read("L")

	while s and i < line do
		n = n + #s
		i = i + 1
		s = src:read("L")
	end

	just(src:close())

	die_if(i < line, "file %q has only got %u lines in it", fname, i)

	if s then
		die_if(col >= #s,
		       "invalid column %u: line %u is only %u bytes long", col, line, #s)
	else
		die_if(col > 0, "invalid column %u: line %u is empty", col, line)
	end

	return n + col
end

-- ask "guru" tool for definition location
local function ask_guru(fname, line, col) --> string
	local src = just(io.popen("guru definition " .. Q(fname) .. ":#" .. offset(fname, line, col)))
	local s = src:read("a")

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
