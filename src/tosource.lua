function tosource_stmts (es)
    return join('\n', map(es,tosource)) ..'\n'
end

function tosource_block (e)
    return '{\n' .. join('\n', map(e.es,tosource)) .. '\n}'
end

function tosource_args (es)
    return join(', ', map(es,tosource))
end

function tosource (e)
    if e.tag=='nil' or e.tag=='bool' or e.tag=='tag' or e.tag=='num' or e.tag=='acc' or e.tag=='dots' then
        return e.tk.str
    elseif e.tag == 'str' then
        return '"' .. e.tk.str .. '"'
    elseif e.tag == 'nat' then
        return '`' .. e.tk.str .. '`'
    elseif e.tag == 'uno' then
        return '(' .. e.op.str .. tosource(e.e) .. ')'
    elseif e.tag == 'bin' then
        return '('..tosource(e.e1)..' '..e.op.str..' '..tosource(e.e2)..')'
    elseif e.tag == 'index' then
        return tosource(e.t)..'['..tosource(e.idx)..']'
    elseif e.tag == 'table' then
        local es = join(", ", map(e.es, function (t)
            return '['..tosource(t.k)..']='..tosource(t.v)
        end))
        return '@{' .. es .. '}'
    elseif e.tag == 'vector' then
        return '#{' .. tosource_args(e.es) .. '}'
    elseif e.tag == 'es' then
        return '(' .. tosource_args(e.es) .. ')'
    elseif e.tag == 'parens' then
        local e = tosource(e.e)
        if e:sub(1,1)=='(' and e:sub(#e,#e)==')' then
            return e
        else
            return '(' .. e .. ')'
        end
    elseif e.tag == 'call' then
        return tosource(e.f) .. '(' .. tosource_args(e.es) .. ')'
    elseif e.tag == 'met' then
        return tosource(e.o) .. '::' .. e.met.str
    elseif e.tag == 'func' then
        local pars = join(', ', map(e.pars, function (id) return id.str end))
        local dots = ''; do
            if e.dots then
                if #e.pars == 0 then
                    dots = '...'
                else
                    dots = ', ...'
                end
            end
        end
        return "func (" .. pars .. dots .. ") " .. tosource_block(e.blk)

    elseif e.tag == 'dcl' then
        local ids = join(', ', map(e.ids,  function(id) return id.str end))
        local set = e.set and (' = '..tosource(e.set)) or ''
        return e.tk.str .. " " .. ids .. set
    elseif e.tag == 'set' then
        return "set " .. tosource_args(e.dsts) .. " = " .. tosource(e.src)
    elseif e.tag == 'block' then
        return tosource_block(e)
    elseif e.tag == 'do' then
        return "do " .. (e.esc and e.esc.str.." " or "") .. tosource(e.blk)
    elseif e.tag == 'defer' then
        return "defer " .. tosource_block(e.blk)
    elseif e.tag == 'ifs' then
        local function f (t,i)
            local cnd, x = table.unpack(t)
            if cnd ~= "else" then
                cnd = tosource(cnd)
            end
            return cnd .. " => " .. tosource(x) .. '\n'
        end
        local head = ' '
        if e.head then
            head = ' ' .. tosource(e.head) .. ' '
        end
        return "ifs" .. head .. "{\n" .. join('',map(e.cases,f)) .. "}"
    elseif e.tag == 'loop' then
        local ids = e.ids and (' '..join(', ', map(e.ids, function(id) return id.str end))) or ''
        local itr = e.itr and (' in '..tosource(e.itr)) or ''
        return "loop" .. ids .. itr .. ' ' .. tosource_block(e.blk)
    elseif e.tag == 'catch' then
        local esc = e.esc and (e.esc.str..' ') or ''
        local xf = e.cnd.f and (', '..tosource(e.cnd.f)) or ''
        return "catch " .. tosource(e.cnd.e) .. xf .. " " .. tosource_block(e.blk)
    else
        print(e.tag)
        error("TODO")
    end
end
