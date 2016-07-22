using OptiMimi
include("../src/lib/readconfig.jl")
config = readconfig("../configs/standard-1year.yml")

include("../src/model.jl")

@time room1 = grad_reservoir_storage_captures(model)

indices = Dict{Symbol, Any}(:time => collect(parsemonth(config["startmonth"]):config["timestep"]:parsemonth(config["endmonth"])), :reservoirs => collect(1:numreservoirs))
@time room2 = grad_component(indices, initreservoir, :storage, :captures)


@time room1 = grad_waterdemand_swdemandbalance_totalirrigation(model)
@time room2 = grad_component(model, :WaterDemand, :totaldemand, :totalirrigation)


room1 = grad_agriculture_production_irrigatedareas(model)
room2 = grad_component(model, :Agriculture, :production, :irrigatedareas)
room3 = grad_component({:regions => collect(mastercounties[:fips]), :crops => crops},
                       initagriculture, :production, :irrigatedareas)
