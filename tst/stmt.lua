-- LUA_PATH="/x/atmos/src/?.lua;" lua5.4 stmt.lua

require "lexer"
require "parser"
require "tosource"

print '--- CALL / FUNC / NATIVE ---'

do
    local src = "f(x,y)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{es={{tag=acc, tk={lin=1, sep=1, str=x, tag=id}}, {tag=acc, tk={lin=1, sep=1, str=y, tag=id}}}, f={tag=acc, tk={lin=1, sep=1, str=f, tag=id}}, tag=call}")

    local src = "func f (v) { val x }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{dsts={{tag=acc, tk={lin=1, sep=1, str=f, tag=id}}}, src={blk={es={{ids={{lin=1, sep=1, str=x, tag=id}}, tag=dcl, tk={lin=1, sep=1, str=val, tag=key}}}, tag=block}, dots=false, pars={{lin=1, sep=1, str=v, tag=id}}, tag=func}, tag=set}")

    local src = [[
        val e = @{}
        (f)()
    ]]
    print("Testing...", "call 1")
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser_main()
    assertx(tosource(s), trim [[
        do {
            val e = @{}
            (f)()
        }
    ]])

    local src = [[
        func f {        ;; TODO: implicit it?
            print(it)
        }
    ]]
    print("Testing...", "func 1")
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser_main)
    assertx(msg, "anon : line 1 : near '{' : expected '('")

    local src = "`print('ok')`"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assertx(tosource(s), "`print('ok')`")
end

print '--- FUNC / DEF / M.F / o::f ---'

do
    local src = "func M.f (v) {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{dsts={{idx={tag=str, tk={lin=1, sep=1, str=f, tag=id}}, t={tag=acc, tk={lin=1, sep=1, str=M, tag=id}}, tag=index}}, src={blk={es={}, tag=block}, dots=false, pars={{lin=1, sep=1, str=v, tag=id}}, tag=func}, tag=set}")
    assertx(trim(tosource(s)), trim [[
        set M["f"] = func (v) {
        }
    ]])

    local src = "func M.o::f (v) {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        set M["o"]["f"] = func (self, v) {
        }
    ]])
end

-- BLOCK / DO / ESCAPE / DEFER / SEQ / ; / MAIN

do
    local src = "a b"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local _,msg = pcall(parser_main)
    assertx(msg, "anon : line 1 : near 'b' : sequence error : expected ';' or new line")

    local src = "do {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assertx(stringify(s), "{blk={es={}, tag=block}, tag=do}")

    local src = "do { var x }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(tosource(s) == trim [[
        do {
            var x
        }
    ]])

    local src = "catch :X { throw :X@{} }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local _,msg = pcall(parser_main)
    assertx(msg, "anon : line 1 : near '@{' : sequence error : expected ';' or new line")

    local src = "catch :X { throw :X;@{} }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assertx(tosource(s), trim [[
        catch :X {
            throw(:X)
            @{}
        }
    ]])
    --local ok, msg = pcall(parser_main)
    --assertx(msg, "anon : line 1 : near ':X' : expected '('")

    local src = "do :X { escape(:X) }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), trim [[
        do :X {
            escape(:X)
        }
    ]])

    local src = "defer { var x ; f(1) }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(tosource(s) == trim [[
        defer {
            var x
            f(1)
        }
    ]])

    local src = "defer { var x ; f(1) }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(tosource(s) == trim [[
        defer {
            var x
            f(1)
        }
    ]])

    local src = "; f () ; g ();h()\ni() ;\n;"
    print("Testing...", "seq 1")
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser_main()
    assert(tosource(s) == trim [[
        do {
            f()
            g()
            h()
            i()
        }
    ]])

    local src = "var v2 ; @{tp,v1,v2} ; nil"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser_main()
    assertx(tosource(s), trim [[
        do {
            var v2
            @{[1]=tp, [2]=v1, [3]=v2}
            nil
        }
    ]])
    --local ok, msg = pcall(parser_main)
    --assertx(msg, "anon : line 1 : near '[' : expected statement")

    local src = "var v2 ; @{tp,v1,v2}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser_main()
    assertx(trim(tosource(s)), trim [[
        do {
            var v2
            @{[1]=tp, [2]=v1, [3]=v2}
        }
    ]])

    local src = "val x = do {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    --local ok, msg = pcall(parser_main)
    --assert(not ok and msg=="anon : line 1 : near 'do' : expected tagged block")
    local s = parser_main()
    assertx(trim(tosource(s)), trim [[
        do {
            val x = do {
            }
        }
    ]])

    local src = "val x = do :X { escape(:X @{10}) }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), trim [[
        val x = do :X {
            escape(atm_tag_do(:X, @{[1]=10}))
        }
    ]])

    local src = "do { 1 ; 2 }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), trim [[
        do {
            1
            2
        }
    ]])

    local src = "do { do(1) ; 2 }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), trim [[
        do {
            do {
                1
            }
            2
        }
    ]])
end

-- DCL / VAL / VAR / SET

do
    local src = "val x"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(stringify(s) == "{ids={{lin=1, sep=1, str=x, tag=id}}, tag=dcl, tk={lin=1, sep=1, str=val, tag=key}}")

    local src = "set y = 10"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{dsts={{tag=acc, tk={lin=1, sep=1, str=y, tag=id}}}, src={tag=num, tk={lin=1, sep=1, str=10, tag=num}}, tag=set}")

    local src = "var y = 10"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(stringify(s) == "{ids={{lin=1, sep=1, str=y, tag=id}}, set={tag=num, tk={lin=1, sep=1, str=10, tag=num}}, tag=dcl, tk={lin=1, sep=1, str=var, tag=key}}")

    local src = "val [10]"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assert(not ok and msg=="anon : line 1 : near '[' : expected <id>")

    local src = "set 1 = 1"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assert(not ok and msg=="anon : line 1 : near '1' : expected assignable expression")

    local src = "val it = 1"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), "val it = 1")
    --local ok, msg = pcall(parser)
    --assert(not ok and msg=="anon : line 1 : near 'it' : expected <id>")

    local src = "set @{1} = 1"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assertx(msg, "anon : line 1 : near '@{' : expected assignable expression")

    local src = "set x, y, z = (10, 20)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(tosource(s) == "set x, y, z = (10, 20)")

    local src = "set x, y, z = 10, 20"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(not check('<eof>'))
    assert(TK1.str == ',')

    local src = "set x, t[1] = (10, 20)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(tosource(s) == "set x, t[1] = (10, 20)")
    --local _,msg = pcall(parser)
    --assertx(msg, "anon : line 1 : near '=' : invalid set : multiple assignment with index is not supported")

    local src = "val x, y = ((10, 20), 30)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(tosource(s) == "val x, y = ((10, 20), 30)")

    local src = "set #x = 1"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assert(not ok and msg=="anon : line 1 : near '#' : expected assignable expression")

    local src = "set pub = 10"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), 'set pub = 10')
end

-- IF-ELSE / IFS

do
    local src = "if cnd { } else { val f }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{cases={{{tag=acc, tk={lin=1, sep=1, str=cnd, tag=id}}, {es={}, tag=block}}, {else, {es={{ids={{lin=1, sep=1, str=f, tag=id}}, tag=dcl, tk={lin=1, sep=1, str=val, tag=key}}}, tag=block}}}, tag=ifs}")

    local src = "if true { }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{cases={{{tag=bool, tk={lin=1, sep=1, str=true, tag=key}}, {es={}, tag=block}}}, tag=ifs}")

    local src = "if f() { if (cnd) { val x } else { val y } }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs {
            f() => {
                ifs {
                    (cnd) => {
                        val x
                    }
                    else => {
                        val y
                    }
                }
            }
        }
    ]])

    local src = "break"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    --local ok, msg = pcall(parser_main)
    --assertx(msg, "anon : line 1 : near '<eof>' : expected '('")
    local s = parser()
    assert(check('<eof>'))
    --assertx(stringify(s), "{blk={es={{es={}, tag=break}}, tag=block}, tag=loop}")
    assertx(stringify(s), "{tag=acc, tk={lin=1, sep=1, str=break, tag=id}}")

    local src = "loop { break() }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    --assertx(stringify(s), "{blk={es={{es={}, tag=break}}, tag=block}, tag=loop}")
    assertx(stringify(s), "{blk={es={{es={}, f={tag=acc, tk={lin=1, sep=1, str=break, tag=id}}, tag=call}}, tag=block}, tag=loop}")

    local src = "loop x in f() {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        loop x in f() {
        }
    ]])

    local src = "loop in f() {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(trim(tosource(s)) == trim [[
        loop in f() {
        }
    ]])

    local src = "loop x {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assert(trim(tosource(s)) == trim [[
        loop x {
        }
    ]])

    local src = "loop { until x }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local _,msg = pcall(parser)
    assertx(msg, "anon : line 1 : near 'x' : sequence error : expected ';' or new line")

    local src = "loop { until;x }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        loop {
            until
            x
        }
    ]])

    local src = "loop { until(x) }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        loop {
            until(x)
        }
    ]])

    local src = "loop { while <- x }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        loop {
            while(x)
        }
    ]])

    local src = "ifs { a=>print(b) ; c => {} ; else => { f() } }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs {
            a => {
                print(b)
            }
            c => {
            }
            else => {
                f()
            }
        }
    ]])

    local src = "ifs {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    --local _,msg = pcall(parser_main)
    --assertx(msg, "anon : line 1 : near '{' : invalid ifs : expected case")
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs {
        }
    ]])

    local src = "ifs { nil }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser_main)
    assertx(msg, "anon : line 1 : near '}' : expected '=>'")

    local src = "ifs { f() => g() }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs {
            f() => {
                g()
            }
        }
    ]])

    local src = "match x { else=>{} }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs x {
            else => {
            }
        }
    ]])

    local src = [[
        match x {
            :X.Y => {}
            1 => {}
            else => x
        }
    ]]
    print("Testing...", "match 1")
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        ifs x {
            atm_is(it, :X.Y) => {
            }
            atm_is(it, 1) => {
            }
            else => {
                x
            }
        }
    ]])
end

-- CATCH

do
    local src = "catch :X { }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(stringify(s), "{blk={es={}, tag=block}, cnd={e={tag=tag, tk={lin=1, sep=1, str=:X, tag=tag}}}, tag=catch}")

    local src = "catch { }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser_main)
    --assertx(msg, "anon : line 1 : near '{' : unexpected '{'")
    --assertx(msg, "anon : line 1 : near '{' : expected <tag>")
    assert(not ok and msg=="anon : line 1 : near '{' : expected expression")

    local src = "catch true, err>0 { }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        catch true, func (err) {
            (err > 0)
        } {
        }
    ]])

    local src = "val x = catch :X { }"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        val x = catch :X {
        }
    ]])
end

-- TASK / TASKS

do
    local src = "spawn [ts] X()"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), "spawn(ts, X, false)")

    local src = "spawn T(1,2,3)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(tosource(s), "pin _ = spawn(nil, T, false, 1, 2, 3)")

    local src = "spawn (x+10)"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assert(not ok and msg=="anon : line 1 : near 'spawn' : expected call")

    local src = "val t = spawn T()"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assert(not ok and msg=="anon : line 1 : near 'spawn' : invalid spawn : expected pin declaraion")

    local src = "val t = tasks()"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local ok, msg = pcall(parser)
    assertx(msg, "anon : line 1 : near 'tasks' : invalid tasks : expected pin declaraion")
end

print '--- AWAIT / EVERY ---'

do
    local src = "every :X {}"
    print("Testing...", src)
    init()
    lexer_init("anon", src)
    lexer_next()
    local s = parser()
    assert(check('<eof>'))
    assertx(trim(tosource(s)), trim [[
        loop {
            val evt = await(:X)
        }
    ]])
end
