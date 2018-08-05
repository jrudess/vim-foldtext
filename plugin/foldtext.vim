if has('multi_byte')
    let defaults = {'placeholder': '⋯',   'line': '▤', 'multiplication': '×' }
else
    let defaults = {'placeholder': '...', 'line': 'L', 'multiplication': '*' }
endif

let g:FoldText_placeholder    = get(g:, 'FoldText_placeholder',    defaults['placeholder'])
let g:FoldText_line           = get(g:, 'FoldText_line',           defaults['line'])
let g:FoldText_multiplication = get(g:, 'FoldText_multiplication', defaults['multiplication'])
let g:FoldText_gap            = get(g:, 'FoldText_gap',            4)
let g:FoldText_info           = get(g:, 'FoldText_info',           1)

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
    let endCommentRegex = '\s*\*/$'
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

    let foldColumnWidth = (&foldcolumn ? &foldcolumn : 0) + (get(g:, 'gitgutter_enabled', 0) ? 3 : 0)
    let numberColumnWidth = &number ? strwidth(line('$')) : 0
    let width = winwidth(0) - foldColumnWidth - numberColumnWidth - g:FoldText_gap

    let ending = ""
    if g:FoldText_info
        let foldSize = 1 + v:foldend - v:foldstart
        let ending = printf("%s%s", g:FoldText_multiplication, foldSize)
        let ending = printf("%s%-6s", g:FoldText_line, ending)

        if strwidth(line . foldEnding . ending) >= width
            let line = strpart(line, 0, width - strwidth(foldEnding . ending))
        endif
    endif

    let expansionStr = repeat(" ", g:FoldText_gap + width - strwidth(line . foldEnding . ending))
    return line . foldEnding . expansionStr . ending
endfunction

set foldtext=FoldText()
