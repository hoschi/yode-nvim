if exists('g:loaded_yode_nvim') | finish | endif

" expose vim commands and interface here
" nnoremap <Plug>PlugCommand :lua require(...).plug_command()<CR>
command! YodeNvim lua require'yode-nvim'.yodeNvim()
command! -range YodeCreateSeditorFloating call luaeval("require('yode-nvim').createSeditorFloating(_A[1], _A[2])", [<line1>, <line2>])
command! -range YodeCreateSeditorReplace call luaeval("require('yode-nvim').createSeditorReplace(_A[1], _A[2])", [<line1>, <line2>])
command! YodeGoToAlternateBuffer lua require'yode-nvim'.goToAlternateBuffer()
command! YodeCloneCurrentIntoFloat lua require'yode-nvim'.cloneCurrentIntoFloat()

command! YodeLayoutShiftWinDown lua require'yode-nvim'.layoutShiftWinDown()
command! YodeLayoutShiftWinUp lua require'yode-nvim'.layoutShiftWinUp()
command! YodeLayoutShiftWinBottom lua require'yode-nvim'.layoutShiftWinBottom()
command! YodeLayoutShiftWinTop lua require'yode-nvim'.layoutShiftWinTop()

augroup YodeNvim
    autocmd!
    autocmd BufEnter * lua require'yode-nvim.changeSyncing'.subscribeToBuffer()
    autocmd BufDelete * call luaeval("require'yode-nvim.changeSyncing'.unsubscribeFromBuffer(tonumber(_A))", expand('<abuf>'))
    autocmd BufWriteCmd yode://* lua require'yode-nvim.seditor'.writeSeditor()
    autocmd BufWritePost * lua require'yode-nvim.fileEditor'.writeFileEditor()
    autocmd BufWinEnter * lua require'yode-nvim'.onBufWinEnter()

    autocmd WinClosed * call luaeval("require'yode-nvim'.onWindowClosed(tonumber(_A))", expand('<afile>'))
    autocmd VimResized * lua require'yode-nvim'.onVimResized()
augroup END

" " FIXME put this is my vimrc and add it to Readme. Command should do what it
" says only if window is floating. if not floating, use `wincmd` to do vims
" normal thing
" FIXME <C-W>r YodeLayoutShiftWinDown
" FIXME <C-W>R YodeLayoutShiftWinUp
" FIXME <C-W>J YodeLayoutShiftWinBottom
" FIXME <C-W>K YodeLayoutShiftWinTop

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_yode_nvim = 1

let &cpo = s:save_cpo
unlet s:save_cpo
