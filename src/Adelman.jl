module Adelman

export AdelmanCategory

# create a submodule for encapsulating all GAP/CAP commands
module CAP

export GAP

using HomalgProject
GAP.LoadPackageAndExposeGlobals( "FreydCategoriesForCAP", CAP, all_globals = true )

end # module CAP

using .CAP

using .CAP.GAP: GapObj, julia_to_gap, gap_to_julia, @gap

import Base: ∘, /, ==

gap_fail = @gap fail
gap_isbound( rec::GapObj, name::AbstractString ) = name in gap_to_julia( CAP.RecNames( rec ) )
gap_isint = @gap IsInt
gap_isstring = @gap IsString
gap_isobject = @gap IsObject
∞ = @gap infinity

GapObj( x :: Integer ) = x
GapObj( x :: AbstractString ) = x

include("categories.jl")
include("freyd_categories.jl")
include("adelman_categories.jl")

end
