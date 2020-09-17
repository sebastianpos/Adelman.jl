new_types_wrap_cat( "Rows", CAP.IsCategoryOfRowsObject, CAP.IsCategoryOfRowsMorphism, CAP.IsCategoryOfRows )

new_types_wrap_cat( "Freyd", CAP.IsFreydCategoryObject, CAP.IsFreydCategoryMorphism, CAP.IsFreydCategory )

new_types_wrap_cat( "QuiverRows", CAP.IsQuiverRowsObject, CAP.IsQuiverRowsMorphism, CAP.IsQuiverRowsCategory )

# convenience constructors

function /(t::Array{<:Any,1}, Q::AbstractQuiverRowsCat)
    qrows = GapObj( Q )
    isempty(t) && return QuiverRowsObj( CAP.ZeroObject( qrows ) )
    return QuiverRowsObj( CAP.DirectSum( broadcast( x -> Base.getproperty( qrows, x ), t )... ) )
end

/(t::AbstractString, Q::AbstractQuiverRowsCat) = [t]/Q

function QuiverRowsMor( s::AbstractQuiverRowsObj, m, r::AbstractQuiverRowsObj )
    nr_rows = gap_to_julia( CAP.NrSummands( GapObj(s) ) )
    nr_cols = gap_to_julia( CAP.NrSummands( GapObj(r) ) )
    
    if nr_rows == 0 || nr_cols == 0
        mat = julia_to_gap( [] )
    else
        qrows = CAP.CapCategory( GapObj( s ) )
        global path_algebra = CAP.UnderlyingQuiverAlgebra( qrows )
        mat = reshape( m, nr_rows, nr_cols )
        mat = broadcast( prepare_relations_str_for_eval, mat )
        mat = broadcast( x -> eval( Meta.parse( x ) ), mat )
        mat = julia_to_gap( mat )
    end
    
    return QuiverRowsMor( CAP.QuiverRowsMorphism( GapObj( s ), mat, GapObj( r ) ) )
end