function! Format()
    Neoformat
    w
endfunction

if !empty($YODE)
    execute 'CocDisable'
    "let g:neomake_verbose = 2
    "let g:neomake_logfile = './neomake.log'
    let g:neomake_javascript_enabled_makers = ['eslintGeneralEditorYode']
    "call neomake#configure#automake('nriw', 100)
    "au! BufWritePost,BufWinEnter *.js Neomake
else
    "let g:neomake_javascript_enabled_makers = ['eslintGeneralEditor']
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

" overwrite vim-test mappings as it doesn't support Plenary test system
"nmap <silent> <leader>ten :call RunTest('TestNearest')<CR><Esc>
nmap <silent> <leader>tef :PlenaryBustedDirectory %:p {minimal_init = 'lua/yode-nvim/tests/minimal.vim'}<cr>
nmap <silent> <leader>tea :PlenaryBustedDirectory ./lua/yode-nvim/tests/ {minimal_init = 'lua/yode-nvim/tests/minimal.vim'}<cr>
"nmap <silent> <leader>tea :call RunTest('TestSuite')<CR><Esc>
"nmap <silent> <leader>tel :call RunTest('TestLast')<CR><Esc>
"nmap <silent> <leader>tev :call RunTest('TestVisit')<CR><Esc>

function! YFormat()
    YodeFormat
    w
endfunction

map <Leader>yc      :YodeCreateSeditorFloating<CR>
map <Leader>yr      :YodeCreateSeditorReplace<CR>
map <Leader>yt      :YodeNvim<CR>
map <Leader>yf      :call YFormat()<CR>
imap <Leader>yf     <Esc>:call YFormat()<CR>
