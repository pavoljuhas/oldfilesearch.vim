" oldfilesearch.vim -- search and edit a file from the :oldfiles list
" Date: 2018-01-25
" Maintainer: Pavol Juhas <pavol.juhas@gmail.com>
" Contributor: Takuya Fujiwara <tyru.exe@gmail.com>
" URL: https://github.com/pavoljuhas/oldfilesearch.vim
" License: Distributable under the same terms as Vim itself (see :help license).
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
"   pattern matches in its tail component.  The search is case insensitive
"   unless there is an upper-case character in the pattern.
"
" Notes:
"
"   To access more old files increase the ' argument of the 'viminfo' option.
"   As an example to change the default ' value to 500 use
"
"       let &viminfo = substitute(&viminfo, "'\\zs\\d*", "500", "")
"
"   The response time of the first call of :OldFileSearch can be improved using
"
"       let g:oldfilesearch_enable_warm_up = 1
"
"   which checks existence of old files in a background after vim startup.
"   This makes a notable difference when old files reside on network drive or
"   low-latency devices.  The response is also improved for the fzf :History
"   command.

if exists('g:loaded_oldfilesearch') || &cp
    finish
endif
let g:loaded_oldfilesearch = 1

command! -nargs=+ -complete=customlist,s:OldFileComplete
            \ OldFileSearch call s:OldFileSearch([<f-args>], <q-mods>)

if exists('g:oldfilesearch_enable_warm_up') && g:oldfilesearch_enable_warm_up
    autocmd VimEnter * ++once call s:WarmUpOldFiles()
endif


function! s:OldFileSearch(patterns, mods)
    let [oldindex, candidates] = s:GetOldFiles(a:patterns)
    let idx = 0
    if empty(candidates)
        echo "No matching old file."
        return
    elseif len(candidates) > 1
        let fmtexpr = '(v:key + 1) . ") " . ('
                    \ . 'oldindex[v:val] ? "<" . oldindex[v:val] : bufnr(v:val))'
                    \ . ' . " " . fnamemodify(v:val, ":~:.")'
        let choicelines = map(copy(candidates), fmtexpr)
        let idx = inputlist(['Select old file:'] + choicelines) - 1
        if idx < 0 || idx >= len(candidates)
            return
        endif
    endif
    let ecmd = empty(a:mods) ? 'edit' : 'split'
    execute a:mods ecmd '`=candidates[idx]`'
endfunction


function! s:OldFileComplete(arglead, cmdline, cursorpos)
    let start = matchend(a:cmdline, 'Ol\%[dFileSearch]\s*')
    let cmdargs = split(a:cmdline[start:], '\s\+')
    let patterns = empty(a:arglead) ? (cmdargs + ['']) : cmdargs
    let [oldindex, candidates] = s:GetOldFiles(patterns)
    return candidates
endfunction


function! s:GetOldFiles(patterns) abort
    " Build a list of candidates.  Start with old files that are not open.
    let candidates = []
    let oldindex = {}
    " Prepend all regular buffers to the begining of the candidate list.
    for l:b in range(1, bufnr('$'))
        " skip non-existing, unnamed and special buffers.
        if empty(bufname(l:b)) || !empty(getbufvar(l:b, '&buftype'))
            continue
        endif
        let bfull = fnamemodify(bufname(l:b), ':p')
        " use old-index zero for existing buffers
        let oldindex[bfull] = 0
        call add(candidates, bfull)
    endfor
    " Now add expanded oldfiles that are not yet in candidates
    let oidx = 0
    for ffull in s:ExpandOldFiles()
        let oidx += 1
        " skip old files that are already in candidates
        if has_key(oldindex, ffull)
            continue
        endif
        let oldindex[ffull] = oidx
        call add(candidates, ffull)
    endfor
    let l:negative_patterns = []
    let l:scnomagic_patterns = []
    for l:p in a:patterns
        if l:p =~ '\v^!.'
            call add(l:negative_patterns, l:p[1:])
        else
            call add(l:scnomagic_patterns, l:p)
        endif
    endfor
    if empty(l:scnomagic_patterns)
        call add(l:scnomagic_patterns, '$')
    endif
    " Adjust patterns to perform smart-case, nomagic matching.
    let toscnm = '((v:val =~ "[[:upper:]]") ? "\\C" : "\\c") . "\\M" . v:val'
    call map(l:negative_patterns, toscnm)
    call map(l:scnomagic_patterns, toscnm)
    " (1) Apply negative patterns
    for l:p in l:negative_patterns
        call filter(candidates, 'v:val !~ l:p')
    endfor
    " (2) All patterns must match the full path.
    for l:p in l:scnomagic_patterns
        call filter(candidates, 'v:val =~ l:p')
    endfor
    " (3) At least one pattern must match the tail component of the path.
    let tailmatches = {}
    for l:f in candidates
        let ft = fnamemodify(l:f, ':t')
        for l:p in l:scnomagic_patterns
            " Check for a simple match of the tail component.  Also check for
            " patterns that span the tail path allowing for the `$` " anchor.
            let l:pf = l:p . '\m[^/\\]*$'
            if ft =~ l:p || matchend(l:f, l:p) == strlen(l:f) || l:f =~ l:pf
                let tailmatches[l:f] = 1
                break
            endif
        endfor
    endfor
    call filter(candidates, 'has_key(tailmatches, v:val)')
    " (3) Discard non-existing files.
    call filter(candidates, 'filereadable(v:val)')
    return [oldindex, candidates]
endfunction


function! s:ExpandOldFiles()
    let homeslash = expand('~/')
    return map(copy(v:oldfiles), "substitute(v:val, '\\m^[~]/', homeslash, '')")
endfunction


function! s:WarmUpOldFiles()
    if has('job') && !empty(v:oldfiles) && executable('/bin/ls') == 1
        let jobcmdargs = ['/bin/ls', '-d', '--'] + s:ExpandOldFiles()
        call job_start(jobcmdargs,
                    \ {"in_io": "null", "out_io": "null", "err_io": "null"})
    endif
endfunction
