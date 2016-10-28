
if exists("loaded_oldfilesearch") || &cp
    finish
endif
let loaded_oldfilesearch = 1

command! -nargs=+ -complete=customlist,oldfilesearch#Complete
            \ OldFileSearch call oldfilesearch#Search([<f-args>])
