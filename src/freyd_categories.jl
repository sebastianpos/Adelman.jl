new_types_wrap_cat( "Rows", CAP.IsCategoryOfRowsObject, CAP.IsCategoryOfRowsMorphism, CAP.IsCategoryOfRows )

new_types_wrap_cat( "Freyd", CAP.IsFreydCategoryObject, CAP.IsFreydCategoryMorphism, CAP.IsFreydCategory )

new_types_wrap_cat( "QuiverRows", CAP.IsQuiverRowsObject, CAP.IsQuiverRowsMorphism, CAP.IsQuiverRowsCategory )

# convenience constructors

function /(t::Array{<:AbstractString,1}, Q::AbstractQuiverRowsCat)
    qrows = GapObj( Q )
    isempty(t) && return QuiverRowsObj( CAP.ZeroObject( qrows ) )
    return QuiverRowsObj( CAP.DirectSum( broadcast( x -> Base.getproperty( qrows, x ), t )... ) )
end

/(t::AbstractString, Q::AbstractQuiverRowsCat) = [t]/Q

function QuiverRowsMor( s::QuiverRowsObj, m, r::QuiverRowsObj )
    qrows = CAP.CapCategory( GapObj( s ) )
    global path_algebra = CAP.UnderlyingQuiverAlgebra( qrows )
    
    mat = reshape( m, gap_to_julia( CAP.NrSummands( GapObj(s) ) ), gap_to_julia( CAP.NrSummands( GapObj(r) ) ) )
    mat = broadcast( prepare_relations_str_for_eval, mat )
    mat = broadcast( x -> eval( Meta.parse( x ) ), mat )
    mat = julia_to_gap( mat )
    
    return QuiverRowsMor( CAP.QuiverRowsMorphism( GapObj( s ), mat, GapObj( r ) ) )
end