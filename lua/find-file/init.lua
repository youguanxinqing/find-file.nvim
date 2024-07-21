local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local sorters = require("telescope.sorters")
local conf = require("telescope.config").values

local utils = require("find-file.utils")

local M = {}

function M.find_file_from_here()
	local files_from_here = utils.get_cur_buf_dir()

	local live_grepper = finders.new_job(function(prompt)
		prompt = vim.fn.trim(prompt)

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
		})
		:find()
end

return M
