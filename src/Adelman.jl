module Adelman

export AdelmanCategory

# create a submodule for encapsulating all GAP/CAP commands
module CAP

export GAP

using CapAndHomalg
CapAndHomalg.LoadPackageAndExposeGlobals( "FreydCategoriesForCAP", CAP )

end # module CAP

using .CAP

using .CAP.GAP: GapObj, julia_to_gap, gap_to_julia, @gap

import Base: ∘, /, ==, +, -, *

gap_fail = @gap fail
gap_isbound( rec::GapObj, name::AbstractString ) = name in gap_to_julia( CAP.RecNames( rec ) )
gap_isint = @gap IsInt
gap_isstring = @gap IsString
gap_isobject = @gap IsObject
gap_iscyclotomic = @gap IsCyclotomic
∞ = @gap infinity

GapObj( x :: Integer ) = x
GapObj( x :: AbstractString ) = x

## String manipulation for the relations
char_test( x :: AbstractChar ) = !isspace(x) && !(x in ('[',']') )

global quiver
global ℚ
global path_algebra

function prepare_relations_str_for_eval( relations_str::AbstractString, ialg::AbstractString="path_algebra" )
    str = relations_str
    str = filter( x -> char_test( x ), str )
    str == "0" && return "CAP.Zero( $(ialg) )"
    str = "," * str * ","
    reg = r"(?<coeff>([\,\+\-])+(\d)*(\*)?)(?<path>[^\*\-\+\,]+(?=[\,\+\-]))"
    sstr = SubstitutionString( "\\g<coeff>Base.getproperty( $(ialg), \"\\g<path>\" )" )
    str = replace( str, reg => sstr )
    return str = str[2:end-1]
end

include("categories.jl")
include("freyd_categories.jl")
include("adelman_categories.jl")

end
