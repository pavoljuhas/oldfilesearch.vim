# oldfilesearch.vim

This plugin provides the `:OldFileSearch` command for filtering the
`:oldfiles` list of files and displaying selection menu to open one
of them.  The displayed files must match all patterns in their
full paths and at least one pattern in their tail names.  The patterns
are matched as 'nomagic' regular expressions and the search is case
insensitive unless there is an upper-case character in the pattern.
The matching files are displayed with their oldfile index `#<n` or
with buffer number `#n` if already loaded in the editor.

**Note:** Since Vim 8 a similar menu can be displayed using a built-in
`:filter /pattern/ browse oldfiles` command.  The `:OldFileSearch` makes
it bit easier to use several patterns and also to match `/` without
an extra quoting.


## Tips

* To access more old files increase the `'` entry in the `'viminfo'`
  option.  For example to remember the last 500 edited files, add the
  following line to your .vimrc

  ```VimL
  let &viminfo = substitute(&viminfo, "'\\zs\\d*", "500", "")
  ```

* The `:OldFileSearch` command also supports `<Tab>` completion
  which allows to cycle over the matching files.

  ```VimL
  :OldFileSearch plugin/ .vim<Tab>
  ```


## Examples

* Select old files that contain `vimrc` in their name:

  ```VimL
  :OldFileSearch vimrc
  ```

* Select oldfiles that contain both `ftpl` and `python.vim` in their
  full path.  This should match `~/.vim/ftplugin/python.vim` if present
  in `:oldfiles`.

  ```VimL
  :OldFileSearch ftpl python.vim
  ```

* Select oldfiles that reside in some `bin` directory:

  ```VimL
  :OldFileSearch /bin/
  ```

* Select oldfiles that reside under the `.vim` directory.
  Here the `$` pattern is always a match within file tail
  therefore `.vim/` may match anywhere in its full path.

  ```VimL
  :OldFileSearch .vim/ $
  ```
