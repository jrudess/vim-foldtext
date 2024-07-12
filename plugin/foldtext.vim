if has('multi_byte')
    let defaults = {'placeholder': '⋯',   'line': '▤', 'multiplication': '×' }
else
    let defaults = {'placeholder': '...', 'line': 'L', 'multiplication': '*' }
endif

let g:FoldText_placeholder    = get(g:, 'FoldText_placeholder',    defaults['placeholder'])
let g:FoldText_line           = get(g:, 'FoldText_line',           defaults['line'])
let g:FoldText_multiplication = get(g:, 'FoldText_multiplication', defaults['multiplication'])
let g:FoldText_info           = get(g:, 'FoldText_info',           1)
let g:FoldText_width          = get(g:, 'FoldText_width',          0)
let g:FoldText_expansion      = get(g:, 'FoldText_expansion',      "   ")

unlet defaults

function! FoldText()
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$'
        let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let spaces = repeat(' ', &tabstop)
        let line = substitute(getline(fs), '\t', spaces, 'g')
    endif

    let endBlockChars   = ['end', '}', ']', ')', '})', '},', '}}}']
    let endBlockRegex = printf('^\(\s*\|\s*\"\s*\)\(%s\);\?$', join(endBlockChars, '\|'))
    let endCommentRegex = '\s*\*/\s*$'
    let startCommentBlankRegex = '\v^\s*/\*!?\s*$'

    let foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    if foldEnding =~ endBlockRegex
        if foldEnding =~ '^\s*\"'
            let foldEnding = strpart(getline(v:foldend), indent(v:foldend)+2, 3)
        end
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    elseif foldEnding =~ endCommentRegex
        if getline(v:foldstart) =~ startCommentBlankRegex
            let nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            let line = line . nextLine
        endif
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    else
        let foldEnding = " " . g:FoldText_placeholder
    endif
    let foldEnding = substitute(foldEnding, '\s\+$', '', '')

    redir =>signs | exe "silent sign place buffer=".bufnr('') | redir end
    let signlist = split(signs, '\n')
    let foldColumnWidth = (&foldcolumn ? &foldcolumn : 0)
    let numberColumnWidth = &number ? strwidth(line('$')) : 0
    let signColumnWidth = len(signlist) >= 2 ? 2 : 0
    let width = winwidth(0) - foldColumnWidth - numberColumnWidth - signColumnWidth

    let ending = ""
    if g:FoldText_info
        if g:FoldText_width > 0 && g:FoldText_width < (width-6)
            let endsize = "%-" . string(width - g:FoldText_width + 4) . "s"
        else
            let endsize = "%-11s"
        end
        let foldSize = 1 + v:foldend - v:foldstart
        let ending = printf("%s%s%s", g:FoldText_line, g:FoldText_multiplication, foldSize)
        let ending = printf(endsize, ending)

        if strwidth(line . foldEnding . ending) >= width
            let line = strpart(line, 0, width - strwidth(foldEnding . ending) - 2)
        endif
    endif

    let expansionWidth = width - strwidth(line . foldEnding . ending)
    let expansionStr = repeat(" ", expansionWidth)
    if expansionWidth > 2
      let extensionCenterWidth = strwidth(g:FoldText_expansion[1:-2])
      let remainder = (expansionWidth - 2) % extensionCenterWidth
      let expansionStr = g:FoldText_expansion[0] . repeat(g:FoldText_expansion[1:-2], (expansionWidth - 2)/extensionCenterWidth) . repeat(g:FoldText_expansion[-2:-2], remainder) . g:FoldText_expansion[-1:]
    endif
    return line . foldEnding . expansionStr . ending
endfunction

set foldtext=FoldText()
