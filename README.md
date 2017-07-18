# oldfilesearch.vim

Add `:OldFileSearch` command to filter a list of `:oldfiles` and
regular buffers and display a selection menu to open one of them.
The displayed files must exist and must match all patterns in their
full paths and at least one pattern in their tail name.  The patterns
are matched as 'nomagic' regular expressions.  The search is case
insensitive unless there is an upper-case character in the pattern.
The matching files are displayed together with their oldfile index
`#<n` or with buffer number `#n` when already loaded in the editor.

**Note:** As of Vim 8 a similar selection can be accomplished using
the built-in command `:filter /pattern/ browse oldfiles`.  In a subtle
difference the `:OldFileSearch` command presents only the existing
files, makes it easier to use several patterns and allows to match
a plain `/` or `.` without backslash quoting.


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


## License

Copyright (c) Pavol Juhas.  Distributed under the same terms as Vim itself
(see `:help license`).
