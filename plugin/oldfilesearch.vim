" :OldFileSearch pattern1 [pattern2 ...]
"
" DEBUG: unlet! loaded_oldfilesearch

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
        let ffull = fnamemodify(l:f, ':p')
        if !has_key(oldindex, ffull)
            call add(candidates, ffull)
            let oldindex[ffull] = oidx
        endif
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
    let choicelines = map(copy(candidates),
                \ '(v:key + 1) . ") " . fnamemodify(v:val, ":~:.")')
    if len(candidates) > 1
        let idx = inputlist(['Select old file:'] + choicelines) - 1
        if idx < 0 || idx >= len(candidates)
            return
        endif
        let target = candidates[idx]
    endif
    edit `=target`
endfunction
