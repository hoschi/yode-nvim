function! Format()
    Neoformat
    w
endfunction

if !empty($YODE)
    execute 'CocDisable'
    let g:neomake_verbose = 3
    let g:neomake_logfile = './neomake.log'
    let g:neomake_javascript_enabled_makers = ['eslintGeneralEditorYode']
else
    "let g:neomake_javascript_enabled_makers = ['eslintGeneralEditor']
    "call neomake#configure#automake('nriw', 100)
    "au! BufWritePost,BufWinEnter *.js Neomake
endif

let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_enabled_lua = ['stylua']

" change write logic
map <Leader>ww		:w<CR>
imap <Leader>ww		<Esc>:w<CR>

map <Leader>wf		:call Format()<CR>
imap <Leader>wf		<Esc>:call Format()<CR>

map <Leader>wa		:wa<CR>
imap <Leader>wa		<Esc>:wa<CR>

map <Leader>ff		:Neoformat<CR>
imap <Leader>ff		<Esc>:Neoformat<CR>

function! YFormat()
    YodeFormat
    w
endfunction

map <Leader>yy      :YodeNvim<CR>
map <Leader>yr      :lua require('yode-nvim').yodeRedux()<CR>
map <Leader>yt      :lua require('yode-nvim').yodeTesting()<CR>
map <Leader>yf      :call YFormat()<CR>
imap <Leader>yf     <Esc>:call YFormat()<CR>
