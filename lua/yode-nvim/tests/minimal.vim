set rtp +=.
set rtp +=../plenary.nvim/

"lua vim.fn.setenv("DEBUG_PLENARY", true)
runtime! plugin/plenary.vim
runtime! plugin/yode-nvim.vim

set noswapfile
set nobackup
set nowritebackup

set hidden
color peachpuff

lua << EOF
local isDebug = require('yode-nvim.isDebug')
require('yode-nvim').setup({
    log = {
        use_console = false,
        highlights = false,
        use_file = isDebug,
    },
})
EOF
