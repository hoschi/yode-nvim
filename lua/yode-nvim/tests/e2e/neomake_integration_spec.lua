describe('Neomake integration -', function()
    pending('entering buffer with error should have Neomake signs')
    pending(
        'solving error in file buffer should remove Neomake sign from it and all visible seditors containing that line'
    )
    pending(
        'solving error in seditor should remove Neomake sign from it and all visible seditors containing that line and visible file buffer'
    )
    pending(
        'solving error in seditor with file editor in another tab should remove signs when visiting it afterwards'
    )
    pending('same for adding error in file buffer again and going back to seditor tab')
    pending(
        "solve erron in seditor, should solve in in file buffer as well. Don't delete the line with the error! Example: the error is an unused variable. Add another line to use the variable. There was a bug where old signs weren't removed from file buffer when error was solved in seditor."
    )
end)
