using DrWatson
include(projectdir("intro.jl"))
using Agents
#using Base: is_interactive
using GLMakie
using InteractiveDynamics
using Random


##
space = GridSpace((10, 10); periodic = false)
mutable struct SchellingAgent <: AbstractAgent
    id::Int             # The identifier number of the agent
    pos::NTuple{2, Int} # The x, y location of the agent on a 2D grid
    mood::Bool          # Whether the agent is happy in its position. (true = happy)
    source::Int        # Whether the agent is a source.
    resources::Int      # The amount of resources collected.
end
properties = Dict(:min_to_be_happy => 3)
#schelling = ABM(SchellingAgent, space; properties)

function initialize(; numagents = 320, griddims = (50, 50), min_to_be_happy = 3, seed = 125,)
    space = GridSpace(griddims, periodic = false)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    rng = Random.MersenneTwister(seed)
    model = ABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.randomly
    )

    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:numagents
        agent = SchellingAgent(n, (1, 1), false, n < numagents / 3 ? 1 : 2,10)
        add_agent_single!(agent, model)
    end
    return model
end


function agent_step!(agent, model)
    minhappy = model.min_to_be_happy
    count_neighbors_same_group = 0
    # For each neighbor, get group and compare to current agent's group
    # and increment count_neighbors_same_group as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid point away, which are at most 8.
    for neighbor in nearby_agents(agent, model)
        if agent.source == 1
            resources_produced += 1
        end
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random position.
    if count_neighbors_same_group ≥ minhappy
        agent.mood = true
    else
        move_agent_single!(agent, model)
    end
    return
end

x(agent) = agent.pos[1]
model = initialize()
adata = [x, :mood, :group]
data, _ = run!(model, agent_step!, 5; adata)
data[1:10, :]
##
using Statistics: mean
model = initialize();
adata = [(:mood, sum), (x, mean)]
data, _ = run!(model, agent_step!, 5; adata)
data
##

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect
figure, _ = abm_plot(model; ac = groupcolor, am = groupmarker, as = 10)
#figure # returning the figure displays it
##
parange = Dict(:min_to_be_happy => 0:8)
adata = [(:mood, sum), (x, mean)]
alabels = ["happy", "avg. x"]
model = initialize(; numagents = 300) # fresh model, none happy
figure, adf, mdf = abm_data_exploration(
    model, agent_step!, dummystep, parange;
    ac = groupcolor, am = groupmarker, as = 10,
    adata, alabels
)
