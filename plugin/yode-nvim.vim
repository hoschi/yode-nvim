if exists('g:loaded_yode_nvim') | finish | endif

" expose vim commands and interface here
" nnoremap <Plug>PlugCommand :lua require(...).plug_command()<CR>
command! YodeNvim lua require'yode-nvim'.yodeNvim()

let s:save_cpo = &cpo
set cpo&vim

" FIXME yode-nvim was an error
let g:loaded_yode_nvim = 1

let &cpo = s:save_cpo
unlet s:save_cpo
