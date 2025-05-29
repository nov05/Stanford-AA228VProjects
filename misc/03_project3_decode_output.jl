########################################################
#======================================================#
#——————————————————————————————————————————————————————#
#                                                      #
# NOTE: LOOKING FURTHER IS A VIOLATION OF THE HONOR CODE
#                                                      #
#——————————————————————————————————————————————————————#
#======================================================#
########################################################

Div = PlutoUI.ExperimentalLayout.Div
divcenter = Dict("display"=>"flex", "justify-content"=>"center")
centered(content) = Div(content; style=divcenter)

global SEED = sum(Int.(collect("AA228V Project 3"))) # Cheeky seed value :)

str2int(s::String) = eval(Meta.parse(join(Int.(collect(s)))))

🌱 = map(seed->str2int(seed), [
	"Bulbasaur 🍃",
	"Ivysaur 🌿",
	"Venusaur 🌷",
	"Charmander 🔥",
	"Charmeleon 🧨",
	"Charizard 🦎",
	"Squirtle 💧",
	"Wartortle 🐢",
	"Blastoise 🌊",
	"Caterpie 🐛",
])

const ℛmax_small  = Hyperrectangle([0.0, 0.0], [0.6, 0.6])
const ℛmax_medium = Hyperrectangle([0.0, 0.0], [1.2, 1.2])
const ℛmax_large  = Hyperrectangle([5.0, 5.0], [5.5, 5.5])

# To determine optimal linear reachability set for SmallSystem
function ta_get_matrices(sys)
    return Ts(sys.env), Ta(sys.env), Πo(sys.agent), Os(sys.sensor)
end

function ta_linear_set_propagation(sys, 𝒮, 𝒳)
    Ts, Ta, Πo, Os = ta_get_matrices(sys)
    return (Ts + Ta * Πo * Os) * 𝒮 ⊕ Ta * Πo * 𝒳.xo ⊕ Ta * 𝒳.xa ⊕ 𝒳.xs
end

abstract type TAReachabilityAlgorithm end

struct TASetPropagation <: TAReachabilityAlgorithm
    h # time horizon
end

function reachable(alg::TASetPropagation, sys)
    h = alg.h
    𝒮, 𝒳 = 𝒮₁(sys.env), disturbance_set(sys)
    ℛ = 𝒮
    for t in 1:h
        𝒮 = ta_linear_set_propagation(sys, 𝒮, 𝒳)
        ℛ = ℛ ∪ 𝒮
    end
    return ℛ
end

function small_system_linear_reachability(sys::SmallSystem)
    d = get_depth(sys)
    alg = TASetPropagation(d)
    ℛ = reachable(alg, sys)
    return ℛ
end

function check_volume(sys::SmallSystem, ψ, ℛ;
					  ℛ_optimal=missing,
					  ℛ_optimal_over_time=missing,
					  t=missing,
					  τs=missing,
					  issound=missing,
					  outsiders=missing,
                      reran::Bool=false,
                      save::Bool=true,
                      tol_subseteq=1e-4,
                      project::Module)

    sysname = system_name(sys)
    newline = md" " # \quad
    d = get_depth(sys)

    if !(ℛ isa LazySet || (typeof(ℛ) <: Vector{<:LazySet} && length(ℛ) == d))
        pass = false

        if ℛ isa Nothing
            log = info(Markdown.parse("""
            Please fill in the following function:
            ```julia
            estimate_reachable_set(sys::$sysname, ψ)
            ```
            **If you've already written this function, click the checkbox above to run the test.**"""))
        else
            vec_length_desc = ""
            if ℛ isa Vector
                vec_length_desc = """
                $newline
                **Your vector/UnionSet has a length of:** \$$(length(ℛ))\$"""
            elseif ℛ isa UnionSet
                vec_length_desc = """
                $newline
                **Your vector/UnionSet has a length of:** \$$(length(fan_sets(ℛ)))\$"""
            end
            log = almost(Markdown.parse("""
            Make sure your function 
            ```julia
            ℛ = estimate_reachable_set(sys::$sysname, ψ)
            ```
            returns the estimated reachable sets of either of the following types:
            - `typeof(ℛ) <: UnionSet`
            - `typeof(ℛ) <: UnionSetArray`
            - `typeof(ℛ) <: Vector{<:LazySet}` (one element for each time step)
            **Current return type**: `typeof(ℛ) = $(typeof(ℛ))`$vec_length_desc"""))
        end
    else
        if ℛ isa UnionSet
            n_vertices = maximum(count_vertices(ℛ))
            hull = convex_hull(ℛ)
        elseif ℛ isa UnionSetArray
            n_vertices = maximum([count_vertices(r) for r in ℛ])
            hull = convex_hull(ℛ)
        elseif typeof(ℛ) <: Vector
            n_vertices = maximum([count_vertices(r) for r in ℛ])
            hull = convex_hull(UnionSetArray([ℛ...]))
        else
            pass = false
            log = almost(
                Markdown.parse("""
                Please return either a `UnionSet`, `UnionSetArray`, or a `Vector{<:LazySet}` as the `typeof(ℛ)`:
                ```julia
                ℛ = estimate_reachable_set(sys::$sysname, ψ)
                ```
                **Current return type**: `typeof(ℛ) = $(typeof(ℛ))`""")
            )
            return (; pass, log, vol=Inf)
        end


        hull_optimal = convex_hull(ℛ_optimal)
        any_intersect_failure::Bool = !is_intersection_empty(hull, ψ.set)
        all_subseteq, witness = ⊆(hull_optimal, hull, true)

        if !isempty(witness)
            # Check tolerance for ⊆
            all_subseteq = minimum(map(vert->norm(witness - vert), hull.vertices)) ≤ tol_subseteq
        end

        if !all(issound)
            all_subseteq = false
        end

        plt = plot(sys, ψ, ℛ;
            ℛ_linear=ℛ_optimal,
            ℛt=ℛ_optimal_over_time[t],
            return_time_plot=true,
            t=t,
            show_samples=true,
            issound,
            outsiders,
            τs,
        )

        md_plts = md"""
        $plt

        - _The convex hull of the union of your sets over time is shown as the outermost dashed set._
        - _The optimal reachable sets (no max vertices restrictions) are shown as the inner dashed sets._
        """

        if !all_subseteq
            pass = false
            vol = compute_volume(fan_sets(ℛ))
            log = almost(
                Markdown.MD(
                    Markdown.parse("""
                    The optimal set is **not a subset \$\\subseteq\$** of your approximation. The following should hold true for all \$t\$:

                    \$\$\\mathcal{R}^{(\\text{optimal})}_t \\subseteq \\mathcal{R}^{(\\text{yours})}_t\$\$
                    
                    This means your approximation is an _underapproximation_.

                    _Including the sum of volumes for debugging:_

                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    newline,
                    md_plts,
                    info(md"See `box_approximation` in the [LazySets docs](https://juliareach.github.io/LazySets.jl/dev/lib/approximations/box_approximation/)."; title="Tip"),
                    newline,
                    md"**Results _not_ saved to file.**",
                )
            )
        elseif any_intersect_failure
            pass = false
            vol = compute_volume(fan_sets(ℛ))
            log = almost(
                Markdown.MD(
                    Markdown.parse("""
                    The (union) set **intersects with the failure region**.
                    
                    This means the overapproximation is too conservative.

                    _Including the sum of volumes for debugging:_

                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    newline,
                    md_plts,
                    info(md"See `box_approximation` in the [LazySets docs](https://juliareach.github.io/LazySets.jl/dev/lib/approximations/box_approximation/)."; title="Tip"),
                    newline,
                    md"**Results _not_ saved to file.**",
                )
            )
        elseif n_vertices > 4
            pass = false
            vol = compute_volume(fan_sets(ℛ))
            log = almost(
                Markdown.MD(
                    Markdown.parse("""
                    The maximum number of vertices for your set is \$$(n_vertices)\$, which is greater than \$4\$.

                    _Including the sum of volumes for debugging:_

                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    newline,
                    md_plts,
                    info(md"See `box_approximation` in the [LazySets docs](https://juliareach.github.io/LazySets.jl/dev/lib/approximations/box_approximation/)."; title="Tip"),
                    newline,
                    md"**Results _not_ saved to file.**",
                )
            )
        else
            pass = true
            vol = compute_volume(fan_sets(ℛ))
            savelog = saveset(sys, ℛ; project, resave=save)
            reran_comment = reran ? "" : "**Note: Results loaded from file. 📁**"
            log = correct(
                Markdown.MD(
                    Markdown.parse("""
                    $reran_comment

                    You found reachable sets with a maximum of \$$(max_vertices(sys))\$ vertices (per time step)!
                    
                    Your sets have the following sum of volumes over time:
                    
                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    md_plts,
                    Markdown.parse(savelog),
                ); title="Test passed!"
            )
        end
    end

	return (; pass, log, vol=pass ? vol : Inf)
end

linear_interpolate(t; start=1, stop, max=1, min=0) = min + (max - min) * ((t - start) / (stop - start))

function check_volume(sys::Union{MediumSystem,LargeSystem}, ψ, ℛ;
					  t=missing,
					  τs,
					  issound,
					  outsiders,
                      ℛmax,
                      cmap=cgrad(:viridis),
                      reran::Bool=false,
                      save::Bool=true,
                      project::Module)

	sysname = system_name(sys)
	newline = md" " # \quad
    d = get_depth(sys)

    if !(ℛ isa LazySet || (typeof(ℛ) <: Vector{<:LazySet} && length(ℛ) == d))
        pass = false

        if ℛ isa Nothing
            log = info(Markdown.parse("""
            Please fill in the following function:
            ```julia
            estimate_reachable_set(sys::$sysname, ψ)
            ```
            **If you've already written this function, click the checkbox above to run the test.**"""))
        else
            vec_length_desc = ""
            if ℛ isa Vector
                vec_length_desc = """
                $newline
                **Your vector/UnionSet has a length of:** \$$(length(ℛ))\$"""
            elseif ℛ isa UnionSet
                vec_length_desc = """
                $newline
                **Your vector/UnionSet has a length of:** \$$(length(fan_sets(ℛ)))\$"""
            end
            log = almost(Markdown.parse("""
            Make sure your function 
            ```julia
            ℛ = estimate_reachable_set(sys::$sysname, ψ)
            ```
            returns the estimated reachable sets of either of the following types:
            - `typeof(ℛ) <: UnionSet`
            - `typeof(ℛ) <: UnionSetArray`
            - `typeof(ℛ) <: Vector{<:LazySet}` (one element for each time step)
            **Current return type**: `typeof(ℛ) = $(typeof(ℛ))`$vec_length_desc"""))
        end
    else
        title_all_time_steps = "Reachable sets per time step"
        if sys isa MediumSystem
    		plt1 = plot_pendulum_state(sys, ψ)
        elseif sys isa LargeSystem
            plt1 = plot_cw_reachability(sys, ψ, ℛ;
                t=t,
                τs=τs,
                cmap=cmap,
                ℛmax=ℛmax,
                issound=issound,
                title=title_all_time_steps,
                outsiders=outsiders)
        end

        for tᵢ in 1:d
			fillalpha = linear_interpolate(tᵢ; start=1, stop=d, min=0.05, max=0.1)
            if sys isa MediumSystem
    			plot_pendulum_solution!(sys, ψ, ℛ; t=tᵢ, lw=1, linealpha=0.2, fillalpha)
                plot!(title=title_all_time_steps, titlefontsize=10)
            elseif sys isa LargeSystem
                plot_cw_reachability(sys, ψ, ℛ;
                    t=t,
                    τs=τs,
                    cmap=cmap,
                    ℛmax=ℛmax,
                    issound=issound,
                    title=title_all_time_steps,
                    outsiders=outsiders)
            end
		end

        title_at_time = "Reachable set at time \$t = $t\$"
        if sys isa MediumSystem
    		plt2 = plot_pendulum_solution(sys, ψ, ℛ; t=t, τs)
            plot!(title=title_at_time, titlefontsize=10)
            if !all(issound)
                plotoutsiders!(sys, outsiders[t])
            end
        elseif sys isa LargeSystem
            plt2 = plot_cw_full_reachability(sys, ψ, τs, ℛ;
                cmap,
                issound,
                title=title_at_time,
                include_samples=false)
        end

        if sys isa MediumSystem
            plt = plot(plt1, plt2, layout=(1,2), bottommargin=5Plots.mm)
            plot!(size=(650,250))
            not_sound_info = info(md"See the nonlinear reachability algorithms in [chapter 9 of the textbook](https://algorithmsbook.com/validation/files/val.pdf)."; title="Tip")
        elseif sys isa LargeSystem
            plt = plot(plt1, plt2, layout=(2,1))
            plot!(size=(650,700))
            not_sound_info = info(md"Either try _natural inclusion_ or see the [_optional section_](neural-verification)."; title="Tip")
        end
		
        if !all(issound)
            pass = false
            vol = compute_volume(ℛ)
            log = almost(
                Markdown.MD(
                    Markdown.parse(
					"""
                    The reachable sets are **not sound**—meaning trajectory samples at some time \$t\$ fell outside the reachable set.

                    _Including the sum of volumes for debugging:_

                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    plt,
                    not_sound_info,
                    md"**Results _not_ saved to file.**",
                )
            )
        else
            pass = true
            vol = compute_volume(ℛ)
            savelog = saveset(sys, ℛ; project, resave=save)
            reran_comment = reran ? "" : "**Note: Results loaded from file. 📁**"
            log = correct(
                Markdown.MD(
                    Markdown.parse("""
                    $reran_comment

                    You found reachable sets with the following sum of volumes over time:

                    \$\$\\sum_{t=1}^d \\operatorname{vol}(\\mathcal{R}_t) = $vol\$\$"""),
                    plt,
                    Markdown.parse(savelog),
                ); title="Test passed!"
            )
        end
    end

	return (; pass, log, vol=pass ? vol : Inf)
end


function saveset(sys::System, ℛ;
                 project::Module,
                 filename=get_filename(sys, project),
                 resave=true)
    filepath = abspath(filename)
    if resave
        results = Dict(
            :ℛ => ℛ
        )
        BSON.@save filepath results
    end
    savelog = """
    _**Results saved for $(env_name(sys)):**_\n `$filepath`

    📩 **Please submit the file listed above to Gradescope.**"""
    return savelog
end


function loadset(sys::System, project::Module)
	filename = get_filename(sys, project)
	filepath = abspath(filename)
    if isfile(filename)
        local ℛ
        try
            results = BSON.load(filepath)[:results]
            ℛ = results[:ℛ]
            if ℛ isa Vector
                ℛ = convert(Vector{LazySet}, ℛ)
            end
        catch caught_err
            if caught_err isa ArgumentError
                error("Malformed file. Please do not edit the results file directly: $filename")
            else
                rethrow(caught_err)
            end
        end
        return ℛ
    else
        return nothing
    end
end


function test(sys::System, ψ, f::Function; ℛmax=missing, rerun::Bool=false, project::Module)
	if rerun
		ℛ = f(sys, ψ)
	else
		ℛ = loadset(sys, project)
	end
    try
        if !ismissing(ℛmax)
            ℛ = bounded_wrapper(ℛ, ℛmax)
        end
    catch end
	return ℛ
end


function 𝐛𝐲𝐞(x, n, c)
    y = string(x)
    for i in 1:n
        y = base64encode(y)
    end
    return string(c, y)
end


function remove(str::String, c::String)
    start_index = findfirst(c, str)
    if start_index === nothing
        return str
    else
        end_index = start_index.start + length(c) - 1
        return str[1:start_index.start-1] * str[end_index+1:end]
    end
end


function 𝐡𝐢(y, n, c)
    x = string(y)
    x = remove(x, c)
    for i in 1:n
        x = base64decode(x)
    end
    return String(x)
end


# For seeding control
function Random.seed!(seed=nothing)
    check_stacktrace_for_invalids(InvalidSeeders.invalids())
    Random.seed!(Random.default_rng(), seed)
    copy!(Random.get_tls_seed(), Random.default_rng())
    Random.default_rng()
end
