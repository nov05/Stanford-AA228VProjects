# AA228V Programming Project FAQs

_This list continuously grows to reflect common queries made on Ed. You may find your query answered here without even needing to wait on Ed!_

## All Projects

1. **The notebook has errors everywhere!**

    - Wait until the notebook finishes loading, but if the errors still persist then you can update the StanfordAA228V package within the notebook by following the [instructions here](https://github.com/sisl/AA228VProjects/blob/main/media/update-package.gif).

## Project 1

1. **What's the code for the `SmallSystem`?**
    <details>
    <summary>Expand for the code.</summary>

    <hr>

    ```julia
    ## Agent
    struct NoAgent <: Agent end
    (c::NoAgent)(s, a=missing) = nothing
    Distributions.pdf(c::NoAgent, s, x) = 1.0

    ## Environment
    struct SimpleGaussian <: Environment end
    (env::SimpleGaussian)(s, a, xs=missing) = s
    Ps(env::SimpleGaussian) = Normal(0, 1) # Initial state distribution

    ## Sensor
    struct IdealSensor <: Sensor end

    (sensor::IdealSensor)(s) = s
    (sensor::IdealSensor)(s, x) = sensor(s)

    Distributions.pdf(sensor::IdealSensor, s, xₛ) = 1.0
    ```
    <hr>
    </details>

2. **I can't figure out the disturbance distribution for the `SmallSystem`.**
    <details>
    <summary>Expand for a <i>hint</i>.</summary>

    <hr>

    You'll first want to define some custom struct:
    ```julia
    struct YourSmallFuzzingDistribution <: TrajectoryDistribution
        # some parameters
    end
    ```

    If you're trying fuzzing, the `disturbance_distribution` for the `SmallSystem` does not apply:

    ```julia
    function StanfordAA228V.disturbance_distribution(p::YourSmallFuzzingDistribution, t)
        D = DisturbanceDistribution((o)->Deterministic(),
                                    (s,a)->Deterministic(),
                                    (s)->Deterministic())
        return D
    end
    ```

    where

    ```julia
    struct DisturbanceDistribution
        Da # agent disturbance distribution
        Ds # environment disturbance distribution
        Do # sensor disturbance distribution
    end
    ```

    **(you don't need to redefine the `DisturbanceDistribution` struct)**

    But the `initial_state_distribution` should be changed:

    ```julia
    function StanfordAA228V.initial_state_distribution(p::YourSmallFuzzingDistribution)
        return Normal(SOME_MEAN, SOME_STD)
    end
    ```
    And don't forget the `depth` function as well!
    ```julia
    StanfordAA228V.depth(p::YourSmallFuzzingDistribution) = get_depth(sys_small)
    ```

    This can then be instantiated (similar to the `NominalTrajectoryDistribution`) like so:
    ```julia
    qτ = YourSmallFuzzingDistribution(your_parameters_as_input_here)
    ```

    And used in the rollout function:
    ```julia
    rollout(sys, qτ; d)
    ```

    **Note**: You should evaluate the `logpdf` using the _nominal_ trajectory distribution:
    ```julia
    pτ = NominalTrajectoryDistribution(sys, d)
    # use pτ when you call logpdf(pτ, τ)
    ```

    See _Example 4.3_ in the textbook for how this is applied to the pendulum.
    <hr>
    </details>

4. **What's the code for the `MediumSystem`?**
    <details>
    <summary>Expand for the code.</summary>

    <hr>

    ```julia
    ## Agent
    struct ProportionalController <: Agent
        k
    end

    (c::ProportionalController)(s, a=missing) = c.k' * s

    ## Environment
    @with_kw struct InvertedPendulum <: Environment
        m::Float64 = 1.0
        l::Float64 = 1.0
        g::Float64 = 10.0
        dt::Float64 = 0.05
        ω_max::Float64 = 8.0
        a_max::Float64 = 2.0
    end

    function (env::InvertedPendulum)(s, a, xs=missing)
        θ, ω = s[1], s[2]
        dt, g, m, l = env.dt, env.g, env.m, env.l

        a = clamp(a, -env.a_max, env.a_max)

        ω = ω + (3g / (2 * l) * sin(θ) + 3 * a / (m * l^2)) * dt
        θ = θ + ω * dt
        ω = clamp(ω, -env.ω_max, env.ω_max)

        return [θ, ω]
    end

    # Initial state distribution
    Ps(env::InvertedPendulum) = MvNormal(zeros(2), diagm([(π/32)^2, 0.5^2]))

    ## Sensor
    struct AdditiveNoiseSensor <: Sensor
        Do
    end

    (sensor::AdditiveNoiseSensor)(s) = sensor(s, rand(Do(sensor, s)))
    (sensor::AdditiveNoiseSensor)(s, x) = s + x

    Do(sensor::AdditiveNoiseSensor, s) = sensor.Do

    Os(sensor::AdditiveNoiseSensor) = I
    ```
    <hr>
    </details>

5. **I can't figure out the disturbance distribution for the `MediumSystem`.**
    <details>
    <summary>Expand for a <i>hint</i>.</summary>

    <hr>

    You'll first want to define some custom struct:
    ```julia
    struct YourMediumFuzzingDistribution <: TrajectoryDistribution
        # some parameters
    end
    ```
    
    If you're trying fuzzing, the `disturbance_distribution` for the `MediumSystem` applies disturbances to the _sensor_:

    ```julia
    function StanfordAA228V.disturbance_distribution(p::YourMediumFuzzingDistribution, t)
        D = DisturbanceDistribution((o)->Deterministic(),
                                    (s,a)->Deterministic(),
                                    (s)->MvNormal(SOME_MEAN_VECTOR, SOME_COVARIANCE))
        return D
    end
    ```

    where

    ```julia
    struct DisturbanceDistribution
        Da # agent disturbance distribution
        Ds # environment disturbance distribution
        Do # sensor disturbance distribution
    end
    ```
   
    **(you don't need to redefine the `DisturbanceDistribution` struct)**

    The `initial_state_distribution` could be the nominal (shown below) or you could change it:
    ```julia
    function StanfordAA228V.initial_state_distribution(p::YourMediumFuzzingDistribution)
        return MvNormal(zeros(2), diagm([(π/32)^2, 0.5^2]))
    end
    ```

    And don't forget the `depth` function as well!
    ```julia
    StanfordAA228V.depth(p::YourMediumFuzzingDistribution) = get_depth(sys_medium)
    ```
   
    This can then be instantiated (similar to the `NominalTrajectoryDistribution`) like so:
    ```julia
    qτ = YourMediumFuzzingDistribution(your_parameters_as_input_here)
    ```

    And used in the rollout function:
    ```julia
    rollout(sys, qτ; d)
    ```

    **Note**: You should evaluate the `logpdf` using the _nominal_ trajectory distribution:
    ```julia
    pτ = NominalTrajectoryDistribution(sys, d)
    # use pτ when you call logpdf(pτ, τ)
    ```

    See _Example 4.3_ in the textbook.
    <hr>
    </details>

6. **What's the code for the `LargeSystem`?**
    <details>
    <summary>Expand for the code.</summary>

    <hr>

    ```julia
    ## Agent
    struct InterpAgent <: Agent
        grid::RectangleGrid
        Q
    end

    (c::InterpAgent)(s) = argmax([interpolate(c.grid, q, s) for q in c.Q])
    (c::InterpAgent)(s, x) = c(s)

    Distributions.pdf(c::InterpAgent, o, xₐ) = 1.0

    ## Environment
    @with_kw struct CollisionAvoidance <: Environment
        ddh_max::Float64 = 1.0 # [m/s²]
        𝒜::Vector{Float64} = [-5.0, 0.0, 5.0] # [m/s]
        Ds::Sampleable = Normal(0, 1.5)
    end

    # NominalTrajectoryDistribution on the environment (D.Ds)
    Ds(env::CollisionAvoidance, s, a) = env.Ds

    function (env::CollisionAvoidance)(s, a, x)
        a = env.𝒜[a]

        h, dh, a_prev, τ = s

        h = h + dh

        if a != 0.0
            if abs(a - dh) < env.ddh_max
                dh += a
            else
                dh += sign(a - dh) * env.ddh_max
            end
        end

        a_prev = a
        τ = max(τ - 1.0, -1.0)

        return [h, dh + x, a_prev, τ]
    end

    (env::CollisionAvoidance)(s, a) = env(s, a, rand(Ds(env, s, a)))

    # Initial state distribution
    Ps(env::CollisionAvoidance) = product_distribution(
        Uniform(-100, 100),                # Initial h
        Uniform(-10, 10),                  # Initial dh
        DiscreteNonParametric([0], [1.0]), # Initial a_prev
        DiscreteNonParametric([40], [1.0]) # Initial τ
    )

    ## Sensor
    struct IdealSensor <: Sensor end

    (sensor::IdealSensor)(s) = s
    (sensor::IdealSensor)(s, x) = sensor(s)

    Distributions.pdf(sensor::IdealSensor, s, xₛ) = 1.0
    ```
    <hr>
    </details>


7. **I can't figure out the disturbance distribution for the `LargeSystem`.**
    <details>
    <summary>Expand for a <i>hint</i>.</summary>

    <hr>
    
    You'll first want to define some custom struct:
    ```julia
    struct YourLargeFuzzingDistribution <: TrajectoryDistribution
        # some parameters
    end
    ```
    
    If you're trying fuzzing, the `disturbance_distribution` for the `LargeSystem` applies disturbances to the _environment_:

    ```julia
    function StanfordAA228V.disturbance_distribution(p::YourLargeFuzzingDistribution, t)
        D = DisturbanceDistribution((o)->Deterministic(),
                                    (s,a)->Normal(SOME_MEAN, SOME_STD),
                                    (s)->Deterministic())
        return D
    end
    ```

    where

    ```julia
    struct DisturbanceDistribution
        Da # agent disturbance distribution
        Ds # environment disturbance distribution
        Do # sensor disturbance distribution
    end
    ```

    **(you don't need to redefine the `DisturbanceDistribution` struct)**


    The `initial_state_distribution` could be the nominal (shown below) or you could change it:
    ```julia
    function StanfordAA228V.initial_state_distribution(p::YourLargeFuzzingDistribution)
    	return product_distribution(
    		Uniform(-100, 100),
    		Uniform(-10, 10),
    		DiscreteNonParametric([0], [1.0]),
    		DiscreteNonParametric([40], [1.0])
    	)
    end
    ```

    And don't forget the `depth` function as well!
    ```julia
    StanfordAA228V.depth(p::YourLargeFuzzingDistribution) = get_depth(sys_large)
    ```

    This can then be instantiated (similar to the `NominalTrajectoryDistribution`) like so:
    ```julia
    qτ = YourLargeFuzzingDistribution(your_parameters_as_input_here)
    ```

    And used in the rollout function:
    ```julia
    rollout(sys, qτ; d)
    ```

    **Note**: You should evaluate the `logpdf` using the _nominal_ trajectory distribution:
    ```julia
    pτ = NominalTrajectoryDistribution(sys, d)
    # use pτ when you call logpdf(pτ, τ)
    ```

    See _Example 4.3_ in the textbook for how this is applied to the pendulum.
    <hr>
    </details>

9. **I'm getting an error saying something like "No method `length` for `MyFuzzingDistribution` type" or "UndefKeywordError: keyword argument `d` not assigned."**
    <details>
    <summary>Expand for answer.</summary>

    <hr>

    You're likely forgetting to include the `<: TrajectoryDistribution` to the `struct` definition of your custom `MyFuzzingDistribution`

    ```julia
    struct MyFuzzingDistribution <: TrajectoryDistribution
       # some parameters
    end     
    ```

    <hr>

    </details>
10. **What are the `rollout` function signatures?**
    <details>
    <summary>Expand for answer.</summary>

    <hr>

    The textbook and the `StanfordAA228V.jl` package define a few `rollout` functions.

    You can see the `src/system.jl` file in the `StanfordAA228V.jl` repo, which defines these `rollout` functions with the following input signatures:

    ```julia
    rollout(sys::System; d=1)
    rollout(sys::System, s; d)
    rollout(sys::System, s, 𝐱; d=length(𝐱))
    rollout(sys::System, s, p::TrajectoryDistribution; d=depth(p))
    rollout(sys::System, p::TrajectoryDistribution; d=depth(p))
    ```

    <hr>

    </details>
