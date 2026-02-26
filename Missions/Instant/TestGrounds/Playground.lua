function Start()
    BuildObject("ibrecy", 1, "Recycler")

    local scout = BuildObject("ivscout", 1, GetPositionNear("Recycler", 20, 40))
    SetAsUser(scout, 1)

    local apc = BuildObject("ivapc", 1, GetPositionNear("Recycler", 20, 40))
    local power = BuildObject("ibpgen", 5, "RecyclerEnemy")
    Attack(apc, power, 1)
end

function Update()

end