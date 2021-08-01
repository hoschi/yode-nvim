" FIXME reload doesn't work!
function! Reload() abort
	lua for k in pairs(package.loaded) do if k:match("^yode-nvim") then package.loaded[k] = nil end end
	lua require("yode-nvim")
endfunction

nnoremap rr :call Reload()<CR>
