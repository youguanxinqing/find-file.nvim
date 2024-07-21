local M = {}

function M.flatten(arr)
	return vim.iter(arr):flatten(10):totable()
end

function M.join(tbl, sep)
	local str = ""

	local length = #tbl
	for i = 1, length - 1, 1 do
		str = str .. tostring(tbl[i]) .. sep
	end
	str = str .. tostring(tbl[length])
	return str
end

function M.split(s, sep)
	if sep == nil then
		return { s }
	end

	local chunks = {}
	for item in string.gmatch(s, "([^" .. sep .. "]+)") do
		table.insert(chunks, item)
	end
	return chunks
end

function M.splitn(s, sep, n)
	if sep == nil or n <= 0 then
		return { s }
	end

	local chunks = {}
	for item in string.gmatch(s, "([^" .. sep .. "]+)") do
		table.insert(chunks, item)
	end

	local chunk_len = vim.fn.len(chunks)
	if n > (chunk_len - 1) then
		n = chunk_len - 1
	end

	local new_chunks = {}
	for i = 0, (n - 1) do
		table.insert(new_chunks, chunks[i + 1])
	end

	table.insert(new_chunks, vim.fn.join(M.slice(chunks, n, chunk_len), sep))
	return new_chunks
end

function M.slice(arr, start, _end, step)
	start, _end, step = start or 0, _end or #arr, step or 1

	local sliced = {}
	if _end < start or start > #arr then
		return sliced
	end
	if not _end or _end > #arr then
		_end = #arr
	end

	for i = start + 1, _end, step do
		table.insert(sliced, arr[i])
	end

	return sliced
end

function M.escape(s)
	local new_str = string.gsub(s, "[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
	return new_str
end

function M.replace(s, old, new)
	local v = string.gsub(s, M.escape(old), new)
	return v
end

function M.get_cur_buf_dir()
	local relative_filepath = M.replace(vim.api.nvim_buf_get_name(0), vim.loop.cwd(), "")
	local chunks = M.split(relative_filepath, "/")
	chunks[vim.fn.len(chunks)] = ""

	local dir = M.join(chunks, "/")
	if dir == "" then
		return "."
	end
	return dir
end

return M
