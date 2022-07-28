module julials
using Pkg
using LanguageServer, SymbolServer
using Comonicon

# shamelessly borrowed from https://github.com/ExpandingMan/LSPNeovim.jl, which is no longer maintained

const PKGDIR = joinpath(@__DIR__,"..")

function activate()
    @info("Activating LSP environment")
    Pkg.activate(PKGDIR)
end

depotpath() = get(ENV, "JULIA_DEPOT_PATH", Pkg.depots1())

_defaultenvpath() = dirname(Base.load_path_expand("@v#.#"))

"""
    hasmanifest(dir)
    hasmanifest()

Checks whether there is a valid `Manifest.toml` in directory `dir`.  If no argument is given, it
will check for the `Manifest.toml` in the `LSPNeovim` environment.
"""
hasmanifest(dir::AbstractString) = isfile(joinpath(dir,"Manifest.toml"))
hasmanifest() = hasmanifest(PKGDIR)

_juliaproject() = get(ENV, "JULIA_PROJECT", nothing)
_juliaprojectbase() = Base.current_project()

function resolve_julia_project()
    project = _juliaproject()
    project_base = _juliaprojectbase()
    if !isnothing(project)
        return project
    end
    if !isnothing(project_base)
        return project_base
    end
end



"""
    envpath()

Picks an appropriate environment path based on the present working directory.
A valid environment for LanguageServer must contain an `Manifest.toml`.  Directories will be checked
in the following order
1. The present working directory.
2. The immediate parent of the present working directory.
3. The default environment directory.

The first of these to contain a `Manifest.toml` will be the environment used for LanguageServer.
"""
function envpath(dirs=[pwd(), joinpath(pwd(),".."), _defaultenvpath()])
    project = resolve_julia_project()
    if !isnothing(project)
        return project
    end
    dirs = filter(hasmanifest, dirs)
    if isempty(dirs)
        @warn("Failed to find a usable environment with valid Manifest.toml.  Checked:", dirs)
        return ""
    end
    return first(dirs)
end

"""
Run the `LanguageServerInstance`.  This will also activate the `LSPNeovim` environment.
By default, this will attempt to determine an appropriate environment, see `envpath`.
"""
@main function run(env=envpath(), depot=depotpath(); input::IO=stdin, output::IO=stdout)
    activate()
    @info("Initializing Language Server", pwd(), env, depot)
    s = LanguageServer.LanguageServerInstance(input, output, env, depot)
    s.runlinter = true
    LanguageServer.run(s)
end
end # module