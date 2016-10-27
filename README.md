# oldfilesearch.vim

Add `:OldFileSearch` command for searching the `:oldfiles` list
and displaying input menu to edit one file.  The found files must
match all patterns provided on the command line and also one pattern
within their tail-components.


## Tips

* To access more old files increase the `'` entry in the `'viminfo'`
  option.  For example to remember last 500 edited files, add the
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
