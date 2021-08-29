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
require("yode-nvim").setup()
EOF
