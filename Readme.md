# yode-nvim

Yode plugin for Neovim.

## interim help

**TODO** move this to Vim help syntax `./doc/yode-nvim.txt`

* install
    * clone with submodules: `git clone --recurse-submodules git@github.com:hoschi/yode-nvim.git`
* log is written to cache dir of stdpaths
    * the default level is 'warn', but can be configured. Level can also be
      overwritten with an environment variable, see the Development section for
      more info.
    * TODO link here how to echo this dir
    * e.g. `~/myuser/.cache/nvim/yode-nvim.log`

## Development

* [Lamda module help](https://moriyalb.github.io/lamda/)
* start Neovim with `DEBUG_YODE='debug' nvim` to set log level
    * TODO link to modes
    * "trace" shows state changes as well
* see log file:
    * `tail -f ~/.cache/nvim/yode-nvim.log | grep -v "^\["`
    * last part removes the file name lines
* format all files: `stylua lua/yode-nvim/*.lua lua/yode-nvim/redux/**.lua`
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
    * play with the code which works, everything using `vim.XYZ` will fail
* test JS development
    * `npm ci` to install dependencies
