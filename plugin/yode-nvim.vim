if exists('g:loaded_yode_nvim') | finish | endif

" expose vim commands and interface here
" nnoremap <Plug>PlugCommand :lua require(...).plug_command()<CR>
command! YodeNvim lua require'yode-nvim'.yodeNvim()
command! -range YodeCreateSeditorFloating call luaeval("require('yode-nvim').createSeditorFloating(_A[1], _A[2])", [<line1>, <line2>])
command! -range YodeCreateSeditorReplace call luaeval("require('yode-nvim').createSeditorReplace(_A[1], _A[2])", [<line1>, <line2>])
command! YodeGoToAlternateBuffer lua require'yode-nvim'.goToAlternateBuffer()

augroup YodeNvim
    autocmd!
    autocmd BufEnter * lua require'yode-nvim.changeSyncing'.subscribeToBuffer()
    autocmd BufDelete * call luaeval("require'yode-nvim.changeSyncing'.unsubscribeFromBuffer(tonumber(_A))", expand('<abuf>'))
    autocmd BufWriteCmd yode://* lua require'yode-nvim.seditor'.writeSeditor()
    autocmd BufWritePost * lua require'yode-nvim.fileEditor'.writeFileEditor()

    autocmd WinClosed * call luaeval("require'yode-nvim'.onWindowClosed(tonumber(_A))", expand('<afile>'))
augroup END

let s:save_cpo = &cpo
set cpo&vim

let g:loaded_yode_nvim = 1

let &cpo = s:save_cpo
unlet s:save_cpo
