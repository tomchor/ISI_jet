using ArgParse
using Printf
using Oceananigans; oc = Oceananigans
using Oceananigans.Utils
using Oceananigans.Units
using Oceananigans.Advection: UpwindBiasedThirdOrder, WENO5
using Oceananigans.OutputWriters, Oceananigans.Fields
using SpecialFunctions: erf


# Parse initial arguments
#++++
"Returns a dictionary of command line arguments."
function parse_command_line_arguments()
    settings = ArgParseSettings()
    @add_arg_table! settings begin

        "--factor"
            help = "Factor to divide Nh and Nz for"
            default = 32
            arg_type = Int

        "--arch"
            help = "CPU or GPU"
            default = "CPU"
            arg_type = String

        "--jet"
            help = "Name of jet in jetinfo.jl"
            default = :SIjet2
            arg_type = Symbol
    end
    return parse_args(settings)
end
args = parse_command_line_arguments()
factor = args["factor"]
arch = eval(Meta.parse(args["arch"]*"()"))
jet = args["jet"]


@printf("Starting Oc with jet %s, a dividing factor of %d and a %s architecture\n", 
        args["jet"],
        factor,
        arch,)
#-----


# Get simulation parameters
#++++
as_background=false
include("jetinfo.jl")

simulation_nml = getproperty(SurfaceJetSimulations(Ny=400*2^4, Nz=2^7), jet)
@unpack name, f0, u₀, N2_inf, N2_pyc, Ny, Nz, Ly, Lz, σy, σz, y₀, z₀, νh, νz, sponge_frac = simulation_nml

simname = @sprintf("PNN_TEST1%s", name)
pickup = any(startswith("chk.$simname"), readdir("data"))
#-----


# Calculate secondary parameters
#++++
b₀ = u₀ * f0
ρ₀ = 1027
T_inertial = 2*π/f0
y_r = y₀ + √2/4 * σy
z_r = 0
Ro_r = - √2 * u₀ * (z₀/σz-1) * exp(-1/8) / (2*f0*σy)
Ri_r = N2_inf * σz^2 * exp(1/4) / u₀^2

secondary_params = merge((u_0=u₀, y_0=y₀, z_0=z₀, b0=b₀), 
                         (;y_r, z_r, Ro_r, Ri_r, T_inertial))

global_attributes = merge(simulation_nml, secondary_params)
println("\n", global_attributes, "\n")
#-----


# Set GRID
#++++  GRID
Nx = Ny÷64
Lx = (Ly / Ny) * Nx
topology = (Periodic, Bounded, Bounded)
grid = RegularRectilinearGrid(size=(Nx÷factor, Ny÷factor, Nz÷factor),
                              x=(0, Lx),
                              y=(0, Ly),
                              z=(-Lz, 0), 
                              topology=topology)
println("\n", grid, "\n")
#-----


# Set up Geostrophic flow
#++++++
const n2_inf = N2_inf
const n2_pyc = N2_pyc
const Hz = grid.Lz
const Hy = grid.Ly
const sig_z = σz
const sig_y = σy
const u_0 = u₀
const y_0 = y₀
const z_0 = z₀
const z_c = -40
const z_m = z_c - n2_pyc/n2_inf*(z_c+Hz)
const f_0 = f0
fy(ψ) = exp(-ψ^2)
intgaussian(ψ) = √π/2 * (erf(ψ) + 1)
umask(Y, Z) = Z * fy(Y)
bmask(Y, Z) = (1/sig_z) * (sig_y * intgaussian(Y))

u_g(x, y, z, t) = +u_0 * umask((y-y_0)/sig_y, ((z-z_0)/sig_z +1))
background_strat(z) = ifelse(z < z_c, 
                             n2_pyc * (z+Hz),
                             n2_inf * (z-z_m))
b_g(x, y, z, t) = -f_0 * u_0 * bmask((y-y_0)/sig_y, ((z-z_0)/sig_z +1)) + background_strat(z)
dudz_g(x, y, z, t) = +u_0 * (1/sig_z) * fy((y-y_0)/sig_y)
#-----

# Setting BCs
#++++
if as_background
    @inline surface_grad(x, y, t) = -dudz_g(x, y, 0, t)
    @inline bottom_grad(x, y, t) = -dudz_g(x, y, -Hz, t)
    U_top_bc = GradientBoundaryCondition(surface_grad)
    U_bot_bc = GradientBoundaryCondition(bottom_grad)
    B_bc = GradientBoundaryCondition(0)
else
    U_top_bc = FluxBoundaryCondition(0)
    U_bot_bc = FluxBoundaryCondition(0)
    B_bc = GradientBoundaryCondition(N2_inf)
end

ubc = UVelocityBoundaryConditions(grid, 
                                  top = U_top_bc,
                                  bottom = U_bot_bc,
                                  )
vbc = VVelocityBoundaryConditions(grid, 
                                  top = FluxBoundaryCondition(0),
                                  bottom = FluxBoundaryCondition(0),
                                 )
wbc = WVelocityBoundaryConditions(grid, 
                                 )
bbc = TracerBoundaryConditions(grid, 
                               bottom = B_bc,
                               top = B_bc,
                               )
#-----


# Set-up sponge layer
#++++
@inline heaviside(X) = ifelse(X < 0, zero(X), one(X))
@inline mask2nd(X) = heaviside(X) * X^2
@inline mask3rd(X) = heaviside(X) * (-2*X^3 + 3*X^2)
const frac = sponge_frac

function bottom_mask(x, y, z)
    z₁ = -Hz; z₀ = z₁ + Hz*frac
    return mask2nd((z - z₀)/(z₁ - z₀))
end
function top_mask(x, y, z)
    z₁ = +Hz; z₀ = z₁ - Hz*frac
    return mask2nd((z - z₀)/(z₁ - z₀))
end
function north_mask(x, y, z)
    y₁ = Hy; y₀ = y₁ - Hy*frac
    return mask2nd((y - y₀)/(y₁ - y₀))
end
function south_mask(x, y, z)
    y₁ = 0; y₀ = y₁ + Hy*frac
    return mask2nd((y - y₀)/(y₁ - y₀))
end

full_mask(x, y, z) = north_mask(x, y, z) + south_mask(x, y, z)# + bottom_mask(x, y, z)
if as_background
    full_sponge_0 = Relaxation(rate=1/10minute, mask=full_mask, target=0)
    forcing = (u=full_sponge_0, v=full_sponge_0, w=full_sponge_0)
else
    full_sponge_0 = Relaxation(rate=1/10minute, mask=full_mask, target=0)
    full_sponge_u = Relaxation(rate=1/10minute, mask=full_mask, target=u_g)
    full_sponge_b = Relaxation(rate=1/10minute, mask=full_mask, target=b_g)
    forcing = (u=full_sponge_u, v=full_sponge_0, w=full_sponge_0)
end
#-----


# Set up ICs and/or Background Fields
#++++
kick = 1e-6
if as_background
    println("\nSetting geostrophic jet as BACKGROUND\n")
    u_ic(x, y, z) = 0 #+ kick*randn()
    v_ic(x, y, z) = 0 #+ kick*randn()
    b_ic(x, y, z) = + 1e-8*randn()

    bg_fields = (u=u_g, b=b_g,)
else
    println("\nSetting geostrophic jet as an INITIAL CONDITION\n")
    u_ic(x, y, z) = u_g(x, y, z, 0) + kick*randn()
    v_ic(x, y, z) = + kick*randn()
    b_ic(x, y, z) = b_g(x, y, z, 0) + 1e-8*randn()

    bg_fields = NamedTuple()
end
#-----


# Define DNS model!
#++++
import Oceananigans.TurbulenceClosures: SmagorinskyLilly, AnisotropicMinimumDissipation
import Oceananigans.TurbulenceClosures: AnisotropicDiffusivity, IsotropicDiffusivity
closure_LES = SmagorinskyLilly(C=0.13)
#closure = AnisotropicMinimumDissipation()
closure_cns = AnisotropicDiffusivity(νh=νh, κh=νh, νz=νz, κz=νz)
model_kwargs = (architecture = arch,
                grid = grid,
                advection = WENO5(),
                timestepper = :RungeKutta3,
                coriolis = FPlane(f=f0),
                tracers = (:b,),
                buoyancy = BuoyancyTracer(),
                boundary_conditions = (b=bbc, u=ubc, v=vbc, w=wbc),
                #forcing = forcing,
                background_fields = bg_fields,
                )
model = IncompressibleModel(; model_kwargs..., closure=closure_LES)
println("\n", model, "\n")
#-----


# Adding the ICs
#++++
set!(model, u=u_ic, v=v_ic, b=b_ic)

v̄ = sum(model.velocities.v.data.parent) / (grid.Nx * grid.Ny * grid.Nz)
model.velocities.v.data.parent .-= v̄
#-----


# Define time-stepping and printing
#++++
u_scale = abs(u₀)
Δt = 1/5*min(grid.Δy, grid.Δz) / u_scale
wizard = TimeStepWizard(cfl=0.8,
                        diffusive_cfl=0.5,
                        Δt=Δt, max_change=1.02, min_change=0.2, max_Δt=Inf, min_Δt=0.1seconds)
cfl_changer(model) = model.clock.time<10hours ? 0.1 : 0.18
#----


# Finally define Simulation!
#++++
include("diagnostics.jl")
start_time = 1e-9*time_ns()
using Oceanostics: SingleLineProgressMessenger
simulation = Simulation(model, Δt=wizard, 
                        stop_time=10*T_inertial,
                        wall_time_limit=23.5hours,
                        iteration_interval=5,
                        progress=SingleLineProgressMessenger(LES=true, initial_wall_time_seconds=start_time),
                        stop_iteration=Inf,)
println("\n", simulation, "\n")
#-----


# START FIRST DIAGNOSTICS
#++++
const ρ0 = ρ₀
checkpointer = construct_outputs(model, simulation, LES=true, simname=simname, frac=frac)
#-----


# Run the simulation!
#+++++
println("\n", simulation,
        "\n",)

@printf("---> Starting run!\n")
run!(simulation, pickup=true)

using Oceananigans.OutputWriters: write_output!
write_output!(checkpointer, model)
pause
#-----




# Define time-stepping and printing
#++++
Δt = simulation.Δt.Δt/2
wizard = TimeStepWizard(cfl=0.4,
                        diffusive_cfl=0.1,
                        Δt=Δt, max_change=1.02, min_change=0.2, max_Δt=Inf, min_Δt=0.1seconds)

advCFL = oc.Diagnostics.AdvectiveCFL(wizard)
difCFL = oc.Diagnostics.DiffusiveCFL(wizard)
function progress(sim)
    wizard.cfl = cfl(sim.model.clock.time)
    msg = @printf("i: % 6d,    sim time: %10s,    wall time: %10s,    Δt: %10s,    diff CFL: %.2e,    adv CFL: %.2e\n",
                  sim.model.clock.iteration,
                  prettytime(sim.model.clock.time),
                  prettytime(1e-9 * (time_ns() - start_time)),
                  prettytime(sim.Δt.Δt),
                  difCFL(sim.model),
                  advCFL(sim.model),
                  )
    return msg
end
#-----

