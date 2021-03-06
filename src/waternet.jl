using Mimi
using Graphs
using DataFrames

typealias RegionNetwork{R, E} IncidenceList{R, E}
typealias OverlaidRegionNetwork RegionNetwork{ExVertex, ExEdge}

filtersincludeupstream = false # true to include all upstream nodes during a filter

# Water network has OUT nodes to UPSTREAM

empty_extnetwork() = OverlaidRegionNetwork(true, ExVertex[], 0, Vector{Vector{ExEdge}}())

if isfile(datapath("cache/waternet$suffix.jld"))
    println("Loading from saved water network...")

    waternet = deserialize(open(datapath("cache/waternet$suffix.jld"), "r"));
    wateridverts = deserialize(open(datapath("cache/wateridverts$suffix.jld"), "r"));
    draws = deserialize(open(datapath("cache/waterdraws$suffix.jld"), "r"));
else
    # Load the network of counties
    if config["netset"] == "usa"
        waternetdata = read_rda(datapath("waternet.RData"), convertdataframes=true);
        drawsdata = read_rda(datapath("countydraws.RData"), convertdataframes=true);
    elseif config["netset"] == "three"
        waternetdata = Dict{Any, Any}("network" => DataFrame(collection=repmat(["three"], 3), colid=1:3, lat=repmat([0], 3), lon=-1:1, nextpt=@data([2, 3, NA]), dist=repmat([1], 3)))
        drawsdata = Dict{Any, Any}("draws" => DataFrame(fips=1:3, source=1:3, justif=repmat(["contains"], 3), downhill=repmat([0], 3), exdist=repmat([0.0], 3)))
    else
        waternetdata = read_rda(datapath("dummynet.RData"), convertdataframes=true);
        drawsdata = read_rda(datapath("dummydraws.RData"), convertdataframes=true);
    end

    netdata = waternetdata["network"];

    # Load the county-network connections
    draws = drawsdata["draws"];
    draws[:source] = round(Int64, draws[:source])
    # Label all with the node name
    draws[:gaugeid] = ""
    for ii in 1:nrow(draws)
        row = draws[ii, :source]
        draws[ii, :gaugeid] = "$(netdata[row, :collection]).$(netdata[row, :colid])"
    end

    if get(config, "filterstate", nothing) != nothing
        states = round(Int64, draws[:fips] / 1000)
        draws = draws[states .== parse(Int64, get(config, "filterstate", nothing)), :]

        includeds = falses(nrow(netdata))
        if filtersincludeupstream
            # Flag all upstream nodes
            checks = draws[:source]
            while length(checks) > 0
                includeds[checks] = true

                nexts = []
                for check in checks
                    nexts = [nexts; find(netdata[:nextpt] .== check)]
                end

                checks = nexts
            end
        else
            includeds[draws[:source]] = true
        end

        # Clean out the source column, so these no longer have meaning!
        draws[:source] = nothing
    else
        includeds = trues(nrow(netdata))
    end

    wateridverts = Dict{UTF8String, ExVertex}();
    waternet = empty_extnetwork();
    for row in 1:nrow(netdata)
        if !includeds[row]
            continue
        end

        println(row)
        nextpt = netdata[row, :nextpt]
        if isna(nextpt)
            continue
        end

        thisid = "$(netdata[row, :collection]).$(netdata[row, :colid])"
        nextid = "$(netdata[nextpt, :collection]).$(netdata[nextpt, :colid])"

        if thisid == nextid
            error("Same same!")
        end

        if thisid in keys(wateridverts) && nextid in keys(wateridverts) &&
            wateridverts[nextid] in out_neighbors(wateridverts[thisid], waternet)
            # error("No backsies!")
            continue
        end

        if !(thisid in keys(wateridverts))
            wateridverts[thisid] = ExVertex(length(wateridverts)+1, thisid)
            add_vertex!(waternet, wateridverts[thisid])
        end

        if !(nextid in keys(wateridverts))
            wateridverts[nextid] = ExVertex(length(wateridverts)+1, nextid)
            add_vertex!(waternet, wateridverts[nextid])
        end

        add_edge!(waternet, wateridverts[nextid], wateridverts[thisid])

        #if test_cyclic_by_dfs(waternet)
        #    error("Cycles off the road!")
        #end
    end

    # Construct the network
    serialize(open(datapath("cache/waternet$suffix.jld"), "w"), waternet)
    serialize(open(datapath("cache/wateridverts$suffix.jld"), "w"), wateridverts)
    serialize(open(datapath("cache/waterdraws$suffix.jld"), "w"), draws)
end

# Prepare the model
downstreamorder = topological_sort_by_dfs(waternet)[end:-1:1];

# Flag every gauge that's a reservoir
include("lib/reservoirs.jl")
reservoirs = getreservoirs(config)

# Zero if not a reservoir, else its index
isreservoir = zeros(length(wateridverts))

for ii in 1:nrow(reservoirs)
    resid = "$(reservoirs[ii, :collection]).$(reservoirs[ii, :colid])"
    if haskey(wateridverts, resid) # Not all reservoirs in network!
        isreservoir[vertex_index(wateridverts[resid])] = ii
    end
end
