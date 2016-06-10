" oldfilesearch.vim -- search and edit a file from the :oldfiles list
" Date: 2016-01-02
" Maintainer: Pavol Juhas <pavol.juhas@gmail.com>
" URL: https://github.com/pavoljuhas/oldfilesearch.vim
"
" Usage:
"
"   :OldFileSearch pattern1 [pattern2 ...]
"
"   Display a numbered list of oldfiles that match regular-expression patterns
"   and prompt for a number to be edited.  Edit the file immediately if there
"   is only one match.  For each matching file show its oldfile index #<n or
"   the buffer number #n if already loaded.  A file is considered a match
"   if all of the patterns match in its full path and at least one matches
"   the tail component.  The search is case insensitive unless there is an
"   upper-case character in any of the specified patterns.

if exists("loaded_oldfilesearch") || &cp
    finish
endif
let loaded_oldfilesearch = 1

command! -nargs=+ OldFileSearch call s:OldFileSearch([<f-args>])

function! s:OldFileSearch(patterns)
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
    let rxcmp = hasupcase ? '=~?' : '=~#'
    for l:p in a:patterns
        call filter(candidates, 'v:val ' . rxcmp . ' l:p')
    endfor
    " (2) At least one pattern must match the tail component of the path.
    let tailmatches = {}
    for l:f in candidates
        let ft = fnamemodify(l:f, ':t')
        for l:p in a:patterns
            if (hasupcase ? ft =~# l:p : ft =~? l:p)
                let tailmatches[l:f] = 1
                break
            endif
        endfor
    endfor
    call filter(candidates, 'has_key(tailmatches, v:val)')
    " (3) Discard non-existing files.
    call filter(candidates, 'filereadable(v:val)')
    let candidates = candidates[:(&lines - 1)]
    if empty(candidates)
        echo "No matching old file."
        return
    endif
    let target = candidates[0]
    let fmtexpr = '(v:key + 1) . ") " . ('
                \ . '(bufnr(v:val) > 0) ? bufnr(v:val) : "<" . oldindex[v:val])'
                \ . ' . " " . fnamemodify(v:val, ":~:.")'
    let choicelines = map(copy(candidates), fmtexpr)
    if len(candidates) > 1
        let idx = inputlist(['Select old file:'] + choicelines) - 1
        if idx < 0 || idx >= len(candidates)
            return
        endif
        let target = candidates[idx]
    endif
    edit `=target`
endfunction
