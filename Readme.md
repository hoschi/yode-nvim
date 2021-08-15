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
* format all files: `stylua lua/yode-nvim/*.lua lua/yode-nvim/redux/**.lua`
