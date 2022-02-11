if !empty($YODE)
    execute 'CocDisable'
    "let g:neomake_verbose = 2
    "let g:neomake_logfile = './neomake.log'
endif
let g:neomake_javascript_enabled_makers = ['eslintGeneralEditor']
call neomake#configure#automake('nriw', 100)
au! BufWritePost,BufWinEnter *.js Neomake

" change write logic
map <Leader>ww		:w<CR>
imap <Leader>ww		<Esc>:w<CR>

map <Leader>wf		:YodeFormatWrite<CR>
imap <Leader>wf		<Esc>:YodeFormatWrite<CR>

map <Leader>yi      :YodeNvim<CR>

map <Leader>yc      :YodeCreateSeditorFloating<CR>
map <Leader>yr      :YodeCreateSeditorReplace<CR>
nmap <Leader>bd :YodeBufferDelete<cr>
imap <Leader>bd <esc>:YodeBufferDelete<cr>

map <C-W>r :YodeLayoutShiftWinDown<CR>
map <C-W>R :YodeLayoutShiftWinUp<CR>
map <C-W>J :YodeLayoutShiftWinBottom<CR>
map <C-W>K :YodeLayoutShiftWinTop<CR>
set showtabline=2
