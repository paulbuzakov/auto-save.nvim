local opts = require("autosave.config").options

local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

local M = {}

local function table_has_value(tbl, value)
    for key, value in pairs(tbl) do
        if (tbl[key] == value) then
            return true
        end
    end

    return false
end

local function set_modified(value)
    modified = value
end

local function get_modified()
    return modified
end

local function do_save()
    if (opts["save_only_if_exists"] == true) then
        if (fn.filereadable(fn.expand("%:p")) == 1) then
            if not (next(opts["excluded_filetypes"]) == nil) then
                if not (table_has_value(opts["excluded_filetypes"], api.nvim_eval([[&filetype]]))) then
					-- might use  update, but in that case it can't be checekd if a file was modified and so it will always
					-- print opts["execution_message"]
                    if (api.nvim_eval([[&modified]]) == 1) then
						cmd("write")
						if (get_modified() == nil) then set_modified(true) end
                    end
                end
            end
        end
    end
end

local function save()
    if (opts["write_all_buffers"] == true) then
        cmd([[call g:AutoSaveBufDo("lua require'autosave.modules.autocmds'.do_save()")]])
    else
        do_save()
    end

    if (opts["execution_message"] ~= "" and get_modified() == true) then
        print(opts["execution_message"])
    end
end

local function parse_events()
    local events = ""

    if (next(opts["events"]) == nil) then
        events = "InsertLeave"
    else
        for event, _ in pairs(opts["events"]) do
            events = events .. opts["events"][event] .. ","
        end
    end

    return events
end

function M.load_autocommands()

	print("Parsed events = " .. tostring(parse_events()))

    api.nvim_exec(
        [[
		augroup autosave_save
			autocmd!
			autocmd ]] ..
            parse_events() .. [[ * execute "lua require'autosave.modules.autocmds'.save()"
		augroup END
	]],
        false
    )
end

function M.unload_autocommands()
    api.nvim_exec([[
		augroup autosave_save
			autocmd!
		augroup END
	]], false)
end

return M
