function Start()
    local recy = BuildObject("ivrecy_nr", 1, GetPositionNear(GetPosition("Recycler"), 20, 50))
    SetBestGroup(recy)
end

function Update()
end