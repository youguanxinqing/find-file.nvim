local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local sorters = require("telescope.sorters")
local conf = require("telescope.config").values
local global_state = require("telescope.state")

local utils = require("find-file.utils")

local M = {}

local FIND_FILES_PROMPT_KEY = "find-files-prompt"

local function create_file_or_dir()
	local path = global_state.get_global_key(FIND_FILES_PROMPT_KEY)
	if vim.fn.exists(path) == 1 then
		return
	end

	local y_or_n = vim.fn.input(string.format("'%s' is not existed, would you create it? y/N: ", path))
	y_or_n = string.lower(vim.fn.trim(y_or_n))
	if y_or_n ~= "y" then
		return
	end

	-- create directory if endswith '/' character
	-- otherwise create file
	if string.sub(path, -1) == "/" then
		vim.system({ "mkdir", "-p", path })
	else
		vim.system({ "touch", path })
	end

	print("create ok!")
end

function M.find_file_from_here()
	local files_from_here = utils.get_cur_buf_dir()
	if string.sub(files_from_here, 1, 1) ~= "." then
		files_from_here = "./" .. files_from_here
	end

	local live_grepper = finders.new_job(function(prompt)
		prompt = vim.fn.trim(prompt)
		global_state.set_global_key(FIND_FILES_PROMPT_KEY, prompt)

		local dir = nil
		if string.match(prompt, "%s+") ~= nil then
			local chunks = utils.splitn(prompt, " ", 2)
			if vim.fn.len(chunks) >= 2 then
				dir, prompt = vim.fn.trim(chunks[1]), vim.fn.trim(chunks[2])
			else
				dir, prompt = prompt, ""
			end
		else
			dir, prompt = prompt, ""
		end

		local is_dir = vim.fn.isdirectory(dir)
		if is_dir == 0 then
			local chunks = utils.split(dir, "/")
			prompt = chunks[vim.fn.len(chunks)]
			chunks[vim.fn.len(chunks)] = ""
			dir = utils.join(chunks, "/")
		end

		if string.sub(dir, 1, 1) ~= "." then
			dir = "./" .. dir
		end

		local notice = string.format("dir:%s,prompt:%s", dir, prompt)
		print(notice)
		print(vim.inspect(utils.flatten({
			{ "rg", "--files", "--color", "never" },
			"--",
			prompt,
			dir,
		})))
		return utils.flatten({ { "rg", "--files", "--color", "never" }, "--", prompt, dir })
	end, make_entry.gen_from_file())

	local opt = {}
	pickers
		.new(opt, {
			prompt_title = "Find File From Here",
			__locations_input = true,
			finder = live_grepper,
			previewer = conf.grep_previewer(opt),
			sorter = sorters.get_fuzzy_file(opt),
			default_text = files_from_here,
			attach_mappings = function(_, keymaps)
				keymaps({ "i", "n" }, "<c-a>", create_file_or_dir)
				return true
			end,
		})
		:find()
end

return M
