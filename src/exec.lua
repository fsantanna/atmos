function exec_string (file, src)
    init()
    lexer_string(file, src)
    parser()
    local ok, blk = pcall(parser_main)
    if not ok then
        return blk
    end

    local f = assert(io.open(file..".lua", "w"))
    f:write([[
        require 'aux'
        require 'runtime'
        return atm_exec (
            "]] .. file .. [[",
            ]] .. string.format('%q', coder_stmts(blk.ss)) .. [[
        )
    ]])
    f:close()

    local exe = assert(io.popen("lua5.4 "..file..".lua 2>&1", "r"))
    return exe:read("a")
end
