" oldfilesearch.vim -- search and edit a file from the :oldfiles list
" Date: 2016-01-02
" Maintainer: Pavol Juhas <pavol.juhas@gmail.com>
" URL: https://github.com/pavoljuhas/oldfilesearch.vim
"
" Usage:
"
"   :OldFileSearch pattern1 [pattern2 ...]
"
"   Display a numbered list of oldfiles filtered to match regular-expressions
"   and prompt for a number to be edited.  Edit the file immediately if there
"   is only one match.  For each matching file display its oldfile index #<n
"   or the buffer number #n if it is already loaded.  An old file is considered
"   a match if all patterns match somewhere in its full path and at least one
"   pattern matches in its tail component.  This search is case insensitive
"   unless there is an upper-case character in some pattern.
"
" Notes:
"
"   To access more old files increase the ' argument of the 'viminfo' option.
"   As an example to change the default ' value to 500 use
"
"       let &viminfo = substitute(&viminfo, "'[^,]*", "'500", "")
"

if exists("loaded_oldfilesearch") || &cp
    finish
endif
let loaded_oldfilesearch = 1

command! -nargs=+ -complete=customlist,s:OldFileComplete
\ OldFileSearch call s:OldFileSearch([<f-args>])

function! s:OldFileSearch(patterns)
    let result = s:GetOldFiles(a:patterns)
    call s:FilterTailMatches(result)
    if empty(result.candidates)
        echo "No matching old file."
        return
    elseif len(result.candidates) == 1
        edit `=result.candidates[0]`
    else
        let fmtexpr = '(v:key + 1) . ") " . ('
                    \ . '(bufnr(v:val) > 0) ? bufnr(v:val) : "<" . result.oldindex[v:val])'
                    \ . ' . " " . fnamemodify(v:val, ":~:.")'
        let choicelines = map(copy(result.candidates), fmtexpr)
        let idx = inputlist(['Select old file:'] + choicelines) - 1
        if idx < 0 || idx >= len(result.candidates)
            return
        endif
        edit `=result.candidates[idx]`
    endif
endfunction

function! s:OldFileComplete(arglead, cmdline, cursorpos)
    let args = split(substitute(a:cmdline, '^OldFileSearch\s\+', '', ''))
    return s:GetOldFiles(args).candidates
endfunction

function! s:GetOldFiles(patterns)
    " build a unique list of candidate old files
    let candidates = []
    let oldindex = {}
    let oidx = 0
    for l:f in v:oldfiles
        let oidx += 1
        let ffull = substitute(l:f, '^[~]/', expand('~/'), '')
        call add(candidates, ffull)
        let oldindex[ffull] = oidx
    endfor
    " Use smart-case matching.
    " (1) All patterns must match the full path.
    let hasupcase = !empty(filter(copy(a:patterns), 'v:val =~ "[[:upper:]]"'))
    let rxcmp = hasupcase ? '=~#' : '=~?'
    let l:nomagic_patterns = map(copy(a:patterns), '"\\M" . v:val')
    for l:p in l:nomagic_patterns
        call filter(candidates, 'v:val ' . rxcmp . ' l:p')
    endfor
    " (2) Discard non-existing files.
    call filter(candidates, 'filereadable(v:val)')
    let candidates = candidates[:(&lines - 1)]
    return {
    \   'oldindex': oldindex,
    \   'hasupcase': hasupcase,
    \   'nomagic_patterns': nomagic_patterns,
    \   'candidates': candidates
    \}
endfunction

" At least one pattern must match the tail component of the path.
" NOTE: This function destroys a:result.candidates
function! s:FilterTailMatches(result)
    let tailmatches = {}
    for l:f in a:result.candidates
        let ft = fnamemodify(l:f, ':t')
        for l:p in a:result.nomagic_patterns
            " Check for a simple match of the tail component.  Also check for
            " patterns with path separator that span over the tail path.
            let l:pf = l:p . '\m[^/\\]*$'
            let l:ismatch = a:result.hasupcase ?
                        \ (ft =~# l:p || l:f =~# l:pf) :
                        \ (ft =~? l:p || l:f =~? l:pf)
            if l:ismatch
                let tailmatches[l:f] = 1
                break
            endif
        endfor
    endfor
    call filter(a:result.candidates, 'has_key(tailmatches, v:val)')
endfunction
