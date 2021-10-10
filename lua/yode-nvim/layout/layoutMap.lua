local R = require('yode-nvim.deps.lamda.dist.lamda')

local layouts = {
    require('yode-nvim.layout.layoutMosaic'),
}
return R.zipObj(R.pluck('name', layouts), layouts)
