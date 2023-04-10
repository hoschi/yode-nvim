local M = {
    log = {},
    handlers = {
        onSeditorBufCal = function()
            vim.cmd([[
                nmap <buffer> <leader>bll :YodeGoToAlternateBuffer<cr>
                imap <buffer> <leader>bll <esc>:YodeGoToAlternateBuffer<cr>
                nmap <buffer> <leader>blt :YodeGoToAlternateBuffer t<cr>
                imap <buffer> <leader>blt <esc>:YodeGoToAlternateBuffer t<cr>
                nmap <buffer> <leader>blz :YodeGoToAlternateBuffer z<cr>
                imap <buffer> <leader>blz <esc>:YodeGoToAlternateBuffer z<cr>
                nmap <buffer> <leader>blb :YodeGoToAlternateBuffer b<cr>
                imap <buffer> <leader>blb <esc>:YodeGoToAlternateBuffer b<cr>
            ]])
        end,
    },
}

M.log.level = 'warn'

return M
