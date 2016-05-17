# The Water Demand component
#
# Combines all of the sources of water demand.

using Mimi
using DataFrames

@defcomp WaterDemand begin
    regions = Index()

    # External
    # Irrigation water (1000 m^3)
    totalirrigation = Parameter(index=[regions, time], unit="1000 m^3")
    # Combined water use for domestic sinks (1000 m^3)
    domesticuse = Parameter(index=[regions, time], unit="1000 m^3")
    # Industrial and mining demand, self supplied
    industrialuse = Parameter(index=[regions,time],unit="1000 m^3")
    urbanuse = Parameter(index=[regions,time], unit="1000 m^3")
    # Demand for thermoelectric power (1000 m^3)
    thermoelectricuse = Parameter(index=[regions, time], unit="1000 m^3")
    # Combined water use for domestic sinks (1000 m^3)
    livestockuse = Parameter(index=[regions, time], unit="1000 m^3")

    # Internal
    # Total water demand (1000 m^3)
    totaldemand = Variable(index=[regions, time], unit="1000 m^3")
end

"""
Compute the amount extracted and the cost for doing it.
"""
function timestep(c::WaterDemand, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        # Sum all demands
        v.totaldemand[rr, tt] = p.totalirrigation[rr, tt] + p.domesticuse[rr, tt] + p.industrialuse[rr, tt] + p.urbanuse[rr, tt] + p.thermoelectricuse[rr, tt] + p.livestockuse[rr, tt]
    end
end

"""
Add a WaterDemand component to the model.
"""
function initwaterdemand(m::Model)
    waterdemand = addcomponent(m, WaterDemand);

    # Set optimized parameters to 0

    #waterdemand[:totalirrigation] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    #waterdemand[:industrialuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    #waterdemand[:urbanuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    #waterdemand[:domesticuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time])

    waterdemand[:totalirrigation] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    waterdemand[:industrialuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    waterdemand[:urbanuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    waterdemand[:domesticuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    waterdemand[:livestockuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);
    waterdemand[:thermoelectricuse] = zeros(m.indices_counts[:regions], m.indices_counts[:time]);

    waterdemand
end

function grad_waterdemand_swbalance_totalirrigation(m::Model)
    roomdiagonal(m, :WaterDemand, :swbalance, :totalirrigation, (rr, tt) -> 1.)
end

