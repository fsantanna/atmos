FILE = nil
LEX  = nil
TK0  = nil
TK1  = nil
LIN  = nil
_n_  = nil
_l_  = nil

function init ()
    _n_ = 0
    _l_ = 1
end

KEYS = {
    'await', --[['break',]] 'catch', --[['coro',]] 'defer', 'do', 'else', 'emit', --[['escape',]]
    'every', 'false', 'func', 'if', 'ifs', 'in', 'loop', 'match', 'nil', 'par',
    'par_and', 'par_or', 'pin', 'resume', --[['return',]] 'set', 'spawn', --[['task',]]
    'tasks', 'test', --[['throw',]] 'true', --[['until',]] 'val', 'var', --[['yield',]]
    'watching', 'with', 'where', --[['while',]]
}

OPS = {
    cs = { '+', '-', '*', '/', '%', '>', '<', '=', '|', '&', '?', '!' ,'#', '~' },
    vs = {
        '#',
        '=', '=>',
        '==', '!=',
        '>', '<', '>=', '<=',
        '||', '&&',
        '+', '-', '*', '/', '%',
        '!',
        '++',
        '~~', '!~',
        '??', '!?',
        '?>', '<?', '!>', '<!',
        '->', '-->', '<-', '<--',
    },
    unos = {
        '-', '#', '!'
    },
    bins = {
        '==', '!=',
        '>', '<', '>=', '<=',
        '||', '&&',
        '+', '-', '*', '/', '%',
        '++',
        '~~', '!~',
        '??', '!?',
        '?>', '<?', '!>', '<!',
    },
    lua = {
        ['!']  = 'not',
        ['!='] = '~=',
        ['||'] = 'or',
        ['&&'] = 'and',
    }
}
