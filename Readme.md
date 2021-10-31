# yode-nvim

Yode plugin for Neovim.

## interim help

**TODO** move this to Vim help syntax `./doc/yode-nvim.txt`.
[kdheepak/panvimdoc: Write documentation in pandoc markdown. Generate documentation in vimdoc.](https://github.com/kdheepak/panvimdoc)

* install
    * clone with submodules: `git clone --recurse-submodules git@github.com:hoschi/yode-nvim.git`
* log is written to cache dir of stdpaths
    * the default level is 'warn', but can be configured. Level can also be
      overwritten with an environment variable, see the Development section for
      more info.
    * TODO link here how to echo this dir
    * e.g. `~/myuser/.cache/nvim/yode-nvim.log`
* example setup:

```viml
" toggle between last buffer, matches buffer mappings of seditors
nmap <Leader>bll <C-^>
imap <Leader>bll <esc><C-^>

lua require('yode-nvim').setup({})
map <Leader>yc :YodeCreateSeditorFloating<CR>
map <Leader>yr :YodeCreateSeditorReplace<CR>
nmap <Leader>bd :YodeBufferDelete<cr>
imap <Leader>bd <esc>:YodeBufferDelete<cr>
" these commands fall back to overwritten keys when cursor is in split window
map <C-W>r :YodeLayoutShiftWinDown<CR>
map <C-W>R :YodeLayoutShiftWinUp<CR>
map <C-W>J :YodeLayoutShiftWinBottom<CR>
map <C-W>K :YodeLayoutShiftWinTop<CR>
" at the moment this is needed to have no gap for floating windows
set showtabline=2
```

## Development

* [Lamda module help](https://moriyalb.github.io/lamda/)
* start Neovim with `DEBUG_YODE='debug' nvim` to set log level
    * TODO link to modes
    * "trace" shows state changes as well
* see log file:
    * `tail -f ~/.cache/nvim/yode-nvim.log | grep -v "^\["`
    * last part removes the file name lines
* format files
    * install `stylua`
    * `make format`
* see `local.vimrc` for enhancements
    * rename to `.local.vimrc` to use it
    * [install nvim plugin for it](https://github.com/thinca/vim-localrc)
    * start Neovim with `YODE=true DEBUG_YODE='debug' nvim` to enable special parts for testing
* install local Lua
    * install [Hererocks](https://github.com/mpeterv/hererocks)
    * setup environment with `hererocks env -l5.1 -rlatest`
    * source environment with `source env/bin/activate`
    * install packages you want to use in repl, e.g. `luarocks install inspect`
* repl
    * source environment as showed above
    * `cd lua` to go into the same path Neovim saves Lua files
    * start a REPL with `lua`
    * require installed luarocks packages, e.g. `inspect = require('inspect')`
    * require local deps by copy/paste from source, e.g. `R = require('yode-nvim.deps.lamda.dist.lamda')`
    * require source code, e.g. `h = require('yode-nvim.helper')`
    * play with the code which works, everything using `vim.XYZ` will fail
* test JS development
    * `npm ci` to install dependencies
    * now you can setup Neomake for the JS files in `testData/`
* run tests:
    * running tests requires
      [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) to be checked
      out in the parent directory of *this* repository
    * run all tests: `make test`
    * run single test: `nvim --headless -c "PlenaryBustedDirectory lua/yode-nvim/tests/e2e/seditor_to_file_editor_sync_spec.lua {minimal_init = 'lua/yode-nvim/tests/minimal.vim'}"`
    * [more infos, see Plenary docs here](https://github.com/nvim-lua/plenary.nvim#plenarytest_harness)
    * run all tests on file changes `nodemon -e lua,vim --exec 'make test'`
    * run single test on file changes `nodemon -e lua,vim --exec "nvim --headless -c \"PlenaryBustedDirectory lua/yode-nvim/tests/e2e/basic_mosaic_layout_spec.lua {minimal_init = 'lua/yode-nvim/tests/minimal.vim'}\" "`
