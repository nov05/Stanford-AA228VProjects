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

global SEED = sum(Int.(collect("AA228V Project 2"))) # Cheeky seed value :)

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
    "Metapod 🌜",
    "Butterfree 🦋",
    "Weedle 🐛",
    "Kakuna 🪳",
    "Beedrill 🐝",
    "Pidgey 🐣",
    "Pidgeotto 🐥",
    "Pidgeot 🦅",
    "Rattata 🐁",
    "Raticate 🐀",
])

function aggregate_error(alg::Function, sys, ψ; seeds=1:num_seeds(sys))
	errors = []
    pfail_true = get_true_pfail(sys, ψ)
	for seed in seeds
		Random.seed!(seed)
		pfail = alg(sys, ψ)
		push!(errors, abs(pfail - pfail_true))
	end
	return mean_and_std(errors)
end

run_aggregate_baseline_TEST(sys,ψ) = aggregate_error(estimate_probability_baseline, sys, ψ; seeds=🌱[1:num_seeds(sys)])

run_aggregate_baseline(sys,ψ) = aggregate_performance(estimate_probability_baseline, sys, ψ; seeds=🌱[1:num_seeds(sys)])

function most_likely_failure_baseline(sys, ψ; n=max_steps(sys), full=false)
	d = get_depth(sys)
	m = floor(Int, n / d)                              # Get num. rollouts (n ÷ d)
	pτ = NominalTrajectoryDistribution(sys, d)         # Trajectory distribution
	τs = [rollout(sys, pτ; d) for _ in 1:m]            # Rollout with pτ, n*d steps
	τs_failures = filter(τ->isfailure(ψ, τ), τs)       # Filter to get failure trajs.
	τ_most_likely = argmax(τ->logpdf(pτ, τ), τs_failures) # Most-likely failure traj
	return full ? (τ_most_likely, τs) : τ_most_likely     # Return MLF, or all trajs.
end

function run_baseline_mlf(sys::System, ψ; n, seed=4)
	Random.seed!(seed)
	τ, τs = most_likely_failure_baseline(sys, ψ; n, full=true)
	d = get_depth(sys)
	p = NominalTrajectoryDistribution(sys, d)
	ℓ = logpdf(p, τ)
	n = stepcount()
	return (τ=τ, τs=τs, ℓ=ℓ, n=n) # return these variables as a NamedTuple
end

# SmallSystem only
function Distributions.cdf(ψ::LTLSpecification)
    if ψ.formula.ϕ isa PredicateWrapper
        c = ψ.formula.ϕ.c_encoded(String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE=")))
        predicate_type = ψ.formula.ϕ.predicate_type
    else
        c = ψ.formula.ϕ.c
        predicate_type = typeof(ψ.formula.ϕ)
    end
	if predicate_type == FlippedPredicate
		return 1 - cdf(Normal(0,1), c)
    elseif predicate_type == Predicate
		return cdf(Normal(0,1), c)
	end
end


get_true_pfail(::SmallSystem, ψ) = cdf(ψ)
get_true_pfail(sys::MediumSystem, ψ) = 0.00815588
get_true_pfail(sys::LargeSystem, ψ) = 0.00018285333333333334


function save_estimates(sys::System, 𝐏;
                        project::Module,
                        counts,
                        err,
                        baseline_err,
                        filename=get_filename(sys, project),
                        reran=true)
    filepath = abspath(filename)
    if reran
        filehash = hash(filename)
        c𝐏 = base64encode("𝐏" * string(filehash, base=16))
        c𝐏 = replace(c𝐏, "="=>"")
        ccounts = base64encode("counts" * string(filehash, base=16))
        ccounts = replace(ccounts, "="=>"")
        cerr = base64encode("err" * string(filehash, base=16))
        cerr = replace(cerr, "="=>"")
        cbaseline_err = base64encode("baseline_err" * string(filehash, base=16))
        cbaseline_err = replace(cbaseline_err, "="=>"")
        e𝐏 = 𝐛𝐲𝐞(𝐏, 3, c𝐏)
        ecounts = 𝐛𝐲𝐞(counts, 3, ccounts)
        eerr = 𝐛𝐲𝐞(err, 3, cerr)
        ebaseline_err = 𝐛𝐲𝐞(baseline_err, 3, cbaseline_err)
        results = Dict(
            :𝐏 => e𝐏,
            :counts => ecounts,
            :err => eerr,
            :baseline_err => ebaseline_err)
        BSON.@save filepath results
    end
    savelog = """
    _**Results saved for $(env_name(sys)):**_\n `$filepath`

    📩 **Please submit the file listed above to Gradescope.**"""
    return savelog
end


function run_pfail(sys, ψ; f, seeds=missing, show_progress=true)
    𝐏 = []
    counts = []
    if ismissing(seeds)
        seeds = 🌱[1:num_seeds(sys)]
    end
    @conditional_progress show_progress name="$(length(seeds)) RNG seeds" for seed in seeds
        Random.seed!(seed)
        n = max_steps(sys)
        𝑃 = f(sys, ψ; n=n)
        push!(𝐏, 𝑃)
        count = stepcount()
        push!(counts, count)
    end
    return 𝐏, counts
end


function check_is_failure(sys::System, ψ, τ; include_plot=true)
    if isfailure(ψ, τ)
        return true
    else
        title = "$(env_name(sys)) tests failed."
        plt = ""
        try
            if include_plot
                plt = plot(sys, ψ, τ; title="Non-failure found", size=(620,350))
            end
        catch end
        return almost(Markdown.MD(Markdown.parse("""
    **The trajectory for `$(system_name(sys))` was not a failure.**

    **Tip**: Filter failures over a vector of rollouts `τs` like so:
    ```julia
    τs_failures = filter(τ->isfailure(ψ, τ), τs)
    ```"""), md"$plt"))
    end
end


function check_max_steps(sys::System, ψ, 𝐏, counts::Vector;
                         reran=false,
                         save=true,
                         latextras="",
                         include_plot=true,
                         baseline::Vector,
                         project::Module)
    d = get_depth(sys)
    p = NominalTrajectoryDistribution(sys, d)
    pfail_true = get_true_pfail(sys, ψ)
    estimate_error = mean(abs.(𝐏 .- pfail_true))
    baseline_error = mean(abs.(baseline .- pfail_true))
    better_than_baseline::Bool = estimate_error < baseline_error
    same_as_baseline::Bool = estimate_error == baseline_error
    n_max = max_steps(sys)
    reran_comment = reran ? "" : "**Note: Results loaded from file. 📁**"
	quad = " "

    plt = ""

    try
        if include_plot
            # plt = plot_pfail_histogram(sys, ψ, 𝐏; f_truth=get_true_pfail, baseline=baseline_error)  ## changed by nov05
            plt = plot_pfail_histogram(sys, ψ, 𝐏; f_truth=get_true_pfail, baseline=mean(baseline))    ## changed by nov05
            if sys isa SmallSystem
                plt = let
                    plt = plot!(title="Estimates", leftmargin=8Plots.mm)

                    plt_sys = plot(sys, ψ; bghexalpha="66", linecolor=:black)
                    plot!(title="Tested system",
                          titlefontsize=10,
                          legend_foreground_color=:black,
                          foreground_color_border=:black,
                          foreground_color_axis=:black,
                          labelfontsize=8,
                          tickfontsize=6,
                          legendfontsize=6,
                          xlabel="""

                          state \$s\$""",
                          gridalpha=0.1,
                          legend=:topleft,
                          size=(300,200))
                    ylims!(ylims()[1], ylims()[2]*1.4)
                    set_aspect_ratio!()

                    plot(plt_sys, plt, layout=(1,2), size=(560,270))
                end
            end
        end
    catch end

    max_count = maximum(counts)

    within_max_steps = max_count ≤ n_max

    if within_max_steps
        if better_than_baseline
            status_comment = "You found a **better estimate** than the baseline!"
        elseif same_as_baseline
            status_comment = "Your estimate was **_equal to_** the baseline (should be better)."
        else
            status_comment = "Your estimate was **worse than** than the baseline."
        end
        if save && better_than_baseline
            savelog = save_estimates(sys, 𝐏; counts, err=estimate_error, baseline_err=baseline_error, reran=reran, project)
            title = "$(env_name(sys)) tests passed!"
        elseif save && !better_than_baseline
            savelog = "**Results _not_ saved to file.**"
            title = "$(env_name(sys)) aggregate statistics."
        else
            savelog = "**Results _not_ saved—this is just a local test.**"
            title = "$(env_name(sys)) aggregate statistics."
        end
        if !better_than_baseline
            title = string("Warning! ", title)
        end
    else
        savelog = "_Results not saved to file._"
        title = "Warning! Exceeded step counts."
        status_comment = Markdown.parse("""
        **Your total steps of \$$(format(max_count; latex=true))\$ exceeded the allotted maximum of \$$(format(n_max; latex=true))\$.**

        This takes the maximum `step` count over the tested seeds.""")
    end

    if isempty(latextras)
        extra = ""
        newline = ""
    else
        extra = "\$\$$latextras \\tag{tested specification}\$\$"
        newline = """

        $quad
        """
    end

    if sys isa SmallSystem
        text = Markdown.MD(
        Markdown.parse("""
        $reran_comment

        $status_comment

        $extra

        \$\$\\max_k(n_\\text{steps}) = $(format(max_count; latex=true)) \\tag{maximum \\texttt{step} count}\$\$
        $newline
        """),
        Markdown.parse("""
        | Algorithm | Variable | Estimate |
        | :-------- | :------- | :------- |
        | Yours | \$\$\\mathbb{E}_k\\left[\\hat{P}_\\text{fail}^k\\right]\$\$ | \$\$$(expnum(mean(𝐏))) \\pm $(expnum(std(𝐏)))\$\$ |
        | Baseline | \$\$\\mathbb{E}_k\\left[\\hat{P}_\\text{fail}^{(\\text{baseline}_k)}\\right]\$\$ | \$\$$(expnum(mean(baseline))) \\pm $(expnum(std(baseline)))\$\$ |
        | Truth | \$\$P_\\text{fail}^{(\\text{true})}\$\$ | \$\$$(expnum(pfail_true))\$\$ |

        $quad

        | Metric | Variable | Error |
        | :---- | :------- | :---- |
        | Estimate Error | \$\$\\text{err} = \\mathbb{E}_k\\left[\\Big\\vert \\hat{P}_\\text{fail}^k - P_\\text{fail}^{(\\text{true})} \\Big\\vert\\right]\$\$ | \$\$$(expnum(estimate_error))\$\$ |
        | Baseline Error | \$\$\\text{err}_\\text{baseline} = \\mathbb{E}_k\\left[\\Big\\vert \\hat{P}_\\text{fail}^{(\\text{baseline}_k)} - P_\\text{fail}^{(\\text{true})} \\Big\\vert\\right]\$\$ | \$\$$(expnum(baseline_error))\$\$ |
        | Better? | \$\$\\text{err} < \\text{err}_\\text{baseline}\$\$ | $better_than_baseline |
        $newline
        Over \$K = $(num_seeds(sys))\$ random number generator seeds.
        """),
        isempty(plt) ? plt : Markdown.MD(
            Markdown.parse(quad),
            centered(plt),
            Markdown.parse(quad)),
        html"<b>Note</b>: This histogram on the right is the distribution of your estimates. <i>Your goal is for the <b style='color: tan;'>yellow</b> line to align more closely with the <b style='color: red;'>red</b> line than the <b style='color: teal;'>teal</b> line does.</i>",
        Markdown.parse(savelog))
    else
        # Hide full set of stats for the medium/large systems.
        text = Markdown.MD(
        Markdown.parse("""
        $reran_comment

        $status_comment

        \$\$\\max_k(n_\\text{steps}) = $(format(max_count; latex=true)) \\tag{maximum \\texttt{step} count}\$\$
        $newline
        """),
        Markdown.parse("""
        | Error | Variable | Value |
        | :---- | :------- | :---- |
        | Estimate Error | \$\$\\text{err} = \\mathbb{E}_k\\left[\\Big\\vert \\hat{P}_\\text{fail}^k - P_\\text{fail}^{(\\text{true})} \\Big\\vert\\right]\$\$ | \$\$$(expnum(estimate_error))\$\$ |
        | Baseline Error | \$\$\\text{err}_\\text{baseline} = \\mathbb{E}_k\\left[\\Big\\vert \\hat{P}_\\text{fail}^{(\\text{baseline}_k)} - P_\\text{fail}^{(\\text{true})} \\Big\\vert\\right]\$\$ | \$\$$(expnum(baseline_error))\$\$ |
        | Better? | \$\$\\text{err} < \\text{err}_\\text{baseline}\$\$ | $better_than_baseline |

        $quad

        """),
        Markdown.parse(savelog))
    end

    fully_passed = better_than_baseline && within_max_steps
    block = fully_passed ? correct : almost
    return fully_passed, block(text; title), estimate_error
end


function test_pfail(sys::System, ψ;
                  f::Function,
                  𝐏=missing,
                  counts=fill(Inf, num_seeds(sys)),
                  nofile=false,
                  save=true,
                  latextras="",
                  include_plot=true,
                  show_progress=true,
                  seeds=missing,
                  baseline::Vector,
                  project::Module)
    err = Inf
    if nofile && save
        pass = false
        𝐏 = nothing
        log = info(Markdown.parse("""
        Please fill in the following function:
        ```julia
        estimate_probability(sys::$(system_name(sys)), ψ)
        ```
        **If you've already written this function, click the checkbox above to run the test.**"""))
    else
        if ismissing(𝐏)
            𝐏, counts = run_pfail(sys, ψ; f, seeds, show_progress)
            reran = true
        else
            reran = false
        end

        if 𝐏[1] isa Float64
            failure_check = true
            # check_is_failure(sys, ψ, 𝐏; include_plot)
            if failure_check == true # could be Markdown
                max_steps_check, max_steps_log, err = check_max_steps(sys, ψ, 𝐏, counts; reran, save, latextras, include_plot, baseline, project)
                log = max_steps_log
                pass = max_steps_check
            else
                pass = false
                log = failure_check
            end
        else
            pass = false
            log = almost(Markdown.parse("""
            Make sure the following returns an estimated failure probability, i.e., a `Float64` type:
            ```julia
            estimate_probability(sys::$(system_name(sys)), ψ)
            ```
            **Currently returning**: `$(typeof(𝐏[1]))`"""))
        end
    end
    return 𝐏, counts, log, pass, err
end


function rerun(sys::System, ψ;
               f,
               baseline::Vector,
               project::Module,
               run=false,
               save=true,
               latextras="",
               include_plot=true,
               show_progress=true,
               seeds=missing)
    if run && save
        𝐏, counts, log, passed, err = test_pfail(sys, ψ; f, include_plot, show_progress, seeds, baseline, project)
    else
        filename = get_filename(sys, project)
        filepath = abspath(filename)
        filehash = hash(filename)
        if isfile(filepath) && save
            local 𝐏, counts, err
            try
                results = BSON.load(filepath)[:results]
                c𝐏 = base64encode("𝐏" * string(filehash, base=16))
                c𝐏 = replace(c𝐏, "="=>"")
                ccounts = base64encode("counts" * string(filehash, base=16))
                ccounts = replace(ccounts, "="=>"")
                cerr = base64encode("err" * string(filehash, base=16))
                cerr = replace(cerr, "="=>"")
                cbaseline_err = base64encode("baseline_err" * string(filehash, base=16))
                cbaseline_err = replace(cbaseline_err, "="=>"")
                e𝐏 = results[:𝐏]
                𝐏 = eval(Meta.parse(𝐡𝐢(e𝐏, 3, c𝐏)))
                ecounts = results[:counts]
                counts = eval(Meta.parse(𝐡𝐢(ecounts, 3, ccounts)))
                eerr = results[:err]
                err = eval(Meta.parse(𝐡𝐢(eerr, 3, cerr)))
                ebaseline_err = results[:baseline_err]
                baseline_err = eval(Meta.parse(𝐡𝐢(ebaseline_err, 3, cbaseline_err)))
                # TODO: Use `baseline_err`
            catch caught_err
                if caught_err isa ArgumentError
                    error("Malformed file. Please do not edit the results file directly: $filename")
                else
                    rethrow(caught_err)
                end
            end
            𝐏, counts, log, passed, err = test_pfail(sys, ψ; f, 𝐏, counts, latextras, include_plot, show_progress, seeds, baseline, project)
        else
            𝐏, counts, log, passed, err = test_pfail(sys, ψ; f, nofile=true, save, latextras, include_plot, show_progress, seeds, baseline, project)
        end
    end
    return 𝐏, counts, log, passed, passed ? err : Inf
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


cs = let 𝐜 = [-2, 2, -3.52992, 2.2025, -3.14159] # small test thresholds
    𝐛𝐲𝐞("$𝐜", 1, replace(base64encode("AA228V Secret"), "="=>""))
end


struct PredicateWrapper <: StanfordAA228V.Formula
    μ::Function
    c_encoded
    predicate_type
end


function (ϕenc::PredicateWrapper)(x)
    μ = ϕenc.μ
    c = ϕenc.c_encoded(String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE=")))
    ϕ = ϕenc.predicate_type(μ, c)
    return ϕ(x)
end


function StanfordAA228V.SignalTemporalLogic.ρ(x, ϕenc::PredicateWrapper)
    μ = ϕenc.μ
    c = ϕenc.c_encoded(String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE=")))
    ϕ = ϕenc.predicate_type(μ, c)
    return StanfordAA228V.SignalTemporalLogic.ρ(x, ϕ)
end


function StanfordAA228V.SignalTemporalLogic.ρ̃(x, ϕenc::PredicateWrapper; kwargs...)
    μ = ϕenc.μ
    c = ϕenc.c_encoded(String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE=")))
    ϕ = ϕenc.predicate_type(μ, c)
    return StanfordAA228V.SignalTemporalLogic.ρ̃(x, ϕ; kwargs...)
end


function get_c(password="")
    __password__ = String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE="))
    #############################################################
    #=                                                         =#
    #= NOTE: CONTINUING HERE IS A VIOLATION OF THE HONOR CODE. =#
    #=                                                         =#
    #############################################################
    if password != __password__
        error("""
        Please do not access the ψ threshold value. In the real world for more complex problems, you would not have direct access to failure region. Even though the simple Gaussian problem is just that, simple, you should not look at this.
        ╔════════════════════════════════════════════════════════════╗
        ║ Continuing further will be a violation of the Honor Code. ║
        ╚════════════════════════════════════════════════════════════╝""")
    else
        return true
    end
end


function randn_rejection(threshold::Number)
    while true
        x = randn()
        if abs(x) ≥ threshold
            return x
        end
    end
end


function create_specification(c=missing; hidden=false)
    I = missing
    c = ismissing(c) ? randn_rejection(2) : c
    flip = c > 0
    predicate_type = flip ? FlippedPredicate : Predicate
    if hidden
        ϕ = let _c = c
            function c_encoded(password="")
                #############################################################
                #############################################################
                #= NOTE: CONTINUING HERE IS A VIOLATION OF THE HONOR CODE. =#
                if get_c(password)
                    return _c
                end
            end
            Always(PredicateWrapper(s->s, c_encoded, predicate_type), I)
        end
    else
        ϕ = Always(predicate_type(s->s, c), I)
    end
    return LTLSpecification(ϕ)
end


function ψ2latex(::SmallSystem, ψ; sigdigits=3)
    if ψ.formula.ϕ isa PredicateWrapper
        #= NOTE: CONTINUING HERE IS A VIOLATION OF THE HONOR CODE. =#
        c = round(ψ.formula.ϕ.c_encoded(String(base64decode("QUEyMjhWL0NTMjM4ViBQcmVkaWNhdGVXcmFwcGVyIFNlY3JldCE="))); sigdigits)
        ~ = ψ.formula.ϕ.predicate_type == Predicate ? ">" : "<"
    else
        c = round(ψ.formula.ϕ.c; sigdigits)
        ~ = ψ.formula.ϕ isa Predicate ? ">" : "<"
    end
    return "\\psi(\\tau) = \\square(s $(~) $c)"
end


function run_pfail_multiple(sys::SmallSystem;
                            f::Function,
                            fbaseline::Function,
                            project::Module,
                            cs=cs,
                            run=true)
    ismissing(cs) && error("Please provide failure thresholds")
    cs = eval(Meta.parse(𝐡𝐢(cs, 1, replace(base64encode("AA228V Secret"), "="=>""))))
    filename = get_filename(sys, project)
    if run
        𝐏s = []
        errors = []
        baseline_errors = []
        passes = []
        max_counts = []
        seeds = 🌱[1:num_seeds(sys)]
        @progress name="$(length(cs)) different ψ specifications,\n$(num_seeds(sys)) seeds each." for (i,c) in enumerate(cs)
            ψ = create_specification(c; hidden=true)
            baseline = fbaseline(sys, ψ, seeds)
            𝐏, counts, log, pass = rerun(sys, ψ; f, run, save=false, include_plot=false, show_progress=false, baseline, project)
            push!(𝐏s, 𝐏)
            if !(𝐏[1] isa Float64)
                break
            end
            push!(passes, pass)
            push!(max_counts, maximum(counts))
            pfail_truth = get_true_pfail(sys, ψ)
            err = mean(abs.(𝐏 .- pfail_truth))
            push!(errors, err)
            err_baseline = mean(abs.(baseline .- pfail_truth))
            push!(baseline_errors, err_baseline)
        end
        if isempty(errors)
            err = Inf
            baseline_err = 0
        else
            err = mean(errors)
            baseline_err = mean(baseline_errors)
        end
    else
        passes = trues(length(cs)) # saved file indicates all passed
        local 𝐏s, max_counts, err, baseline_err
        filehash = hash(filename)
        filepath = abspath(filename)
        try
            results = BSON.load(filepath)[:results]
            c𝐏s = base64encode("𝐏" * string(filehash, base=16))
            c𝐏s = replace(c𝐏s, "="=>"")
            cmax_counts = base64encode("counts" * string(filehash, base=16))
            cmax_counts = replace(cmax_counts, "="=>"")
            cerr = base64encode("err" * string(filehash, base=16))
            cerr = replace(cerr, "="=>"")
            cbaseline_err = base64encode("baseline_err" * string(filehash, base=16))
            cbaseline_err = replace(cbaseline_err, "="=>"")
            e𝐏s = results[:𝐏]
            𝐏s = eval(Meta.parse(𝐡𝐢(e𝐏s, 3, c𝐏s)))
            emax_counts = results[:counts]
            max_counts = eval(Meta.parse(𝐡𝐢(emax_counts, 3, cmax_counts)))
            eerr = results[:err]
            err = eval(Meta.parse(𝐡𝐢(eerr, 3, cerr)))
            ebaseline_err = results[:baseline_err]
            baseline_err = eval(Meta.parse(𝐡𝐢(ebaseline_err, 3, cbaseline_err)))
        catch caught_err
            if caught_err isa ArgumentError
                error("Malformed file. Please do not edit the results file directly: $filename")
            else
                rethrow(caught_err)
            end
        end
    end
    return 𝐏s, passes, max_counts, err, baseline_err
end


function rerun_multiple(sys::SmallSystem;
                        f,
                        project::Module,
                        run=true,
                        fbaseline::Function=(sys,ψ,seeds)->error("Please include an fbaseline function: (sys,ψ,seeds)->(::Vector{Float}, ::Vector{Float64})"))
    filename = get_filename(sys, project)
    filepath = abspath(filename)
    reeval = run || !isfile(filepath)
    file_missing = !isfile(filepath)
    mean_err = Inf
    mean_baseline_err = 0

    if file_missing && !run
        𝐏s = [[nothing]]
    else
        𝐏s, passes, counts, mean_err, mean_baseline_err = run_pfail_multiple(sys; f, run, fbaseline, project)
    end

    sysname = system_name(sys)
    n_max = max_steps(sys)
    reran_comment = run ? "" : "**Note: Results loaded from file. 📁**"

    if all(isnothing.(𝐏s[1])) && file_missing && !run
        pass = false
        log = info(Markdown.parse("""
    Please fill in the following function:
    ```julia
    estimate_probability(sys::$sysname, ψ)
    ```
    **If you've already written this function, click the checkbox above to run the test.**"""))
    elseif any(𝑃->!(𝑃 isa Float64), 𝐏s[1])
        pass = false
        log = almost(Markdown.parse("""
        Make sure the following returns an estimated failure probability, i.e., a `Float64` type:
        ```julia
        estimate_probability(sys::$sysname, ψ)
        ```
        **Currently returning (for the first test)**: `$(typeof(𝐏s[1][1]))`"""))
    else
        better_than_baseline = mean_err < mean_baseline_err
        same_as_baseline = mean_err == mean_baseline_err
        if any(count->count > n_max, counts)
            pass = false
            log = almost(Markdown.MD(
                Markdown.parse("""
                **Your total steps of \$$(format(maximum(counts); latex=true))\$ exceeded the allotted maximum of \$$(format(n_max; latex=true))\$.**

                This takes the maximum `step` count over the tested seeds and tested \$\\psi\$ settings."""),
                md"Here's your mean error over each $i$th test compared to the baseline (for debugging).",
                Markdown.parse("""
                \$\$\\begin{align}
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(i,k)} - P_\\text{fail}^{(\\text{true}_i)} \\Big\\vert \\bigg] &= $(expnum(mean_err)) \\\\
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(\\text{baseline}_{i,k})} - P_\\text{fail}^{(\\text{true}_{i})} \\Big\\vert \\bigg] &= $(expnum(mean_baseline_err))
                \\end{align}\$\$
                """),
                md"""_Results not saved to file._"""))
        elseif better_than_baseline
            pass = true
            log = correct(Markdown.MD(
                Markdown.parse(reran_comment),
                md"Passed! Your mean error over each $i$th test was better than the baseline.",
                Markdown.parse("""
                \$\$\\begin{align}
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(i,k)} - P_\\text{fail}^{(\\text{true}_i)} \\Big\\vert \\bigg] &= $(expnum(mean_err)) \\\\
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(\\text{baseline}_{i,k})} - P_\\text{fail}^{(\\text{true}_{i})} \\Big\\vert \\bigg] &= $(expnum(mean_baseline_err))
                \\end{align}\$\$
                """),
                Markdown.parse(save_estimates(sys, 𝐏s; counts, err=mean_err, baseline_err=mean_baseline_err, project)),
            ); title="All $sysname tests passed!")
        else
            same_or_worse = same_as_baseline ? "equal to" : "worse than"
            pass = false
            log = almost(
                Markdown.MD(
                md"Try something else! Your mean error over each $i$th test was **$same_or_worse** the baseline.",
                Markdown.parse("""
                \$\$\\begin{align}
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(i,k)} - P_\\text{fail}^{(\\text{true}_i)} \\Big\\vert \\bigg] &= $(expnum(mean_err)) \\\\
                \\mathbb{E}_{i,k} \\bigg[ \\Big\\vert \\hat{P}_\\text{fail}^{(\\text{baseline}_{i,k})} - P_\\text{fail}^{(\\text{true}_{i})} \\Big\\vert \\bigg] &= $(expnum(mean_baseline_err))
                \\end{align}\$\$
                """),
                # md"**Your average failure probability estimate was worse than the baseline:**",
                #     Markdown.parse("""
                #     **Results**: $(sum(.!passes)) out of $(length(passes)) tests were worse than (or the same as) the baseline.
                #     """),
                Markdown.parse("""_**Note**: True values of_ $("\$P_\\text{fail}^{(\\text{true})}\$") _are not revealed._""")
                )
            )
        end
    end

    return 𝐏s, log, pass, pass ? mean_err : Inf
end


# For seeding control
function Random.seed!(seed=nothing)
    check_stacktrace_for_invalids(InvalidSeeders.invalids())
    Random.seed!(Random.default_rng(), seed)
    copy!(Random.get_tls_seed(), Random.default_rng())
    Random.default_rng()
end
