# yode-nvim

Yode plugin for Neovim.

## interim help

**TODO** move this to Vim help syntax `./doc/yode-nvim.txt`

* install
    * Unix: `bash install.sh`
    * Windows: please create PR or issue how to do this on Windows
    * long term idea is to use something like
      [packer.nvim](https://github.com/wbthomason/packer.nvim), but at the
      moment it is just too complicated
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
