new_types_wrap_cat( "Adel", CAP.IsAdelmanCategoryObject, CAP.IsAdelmanCategoryMorphism, CAP.IsAdelmanCategory )

## Convenience constructors

function /(str::AbstractString, A::AbstractAdelCat)
    gA = GapObj( A )
    cell = Base.getproperty( CAP.UnderlyingCategory( gA ), str )/gA
    CAP.IsCapCategoryObject( cell ) && return AdelObj( cell )
    CAP.IsCapCategoryMorphism( cell ) && return AdelMor( cell )
end

##

function /(t::Tuple{<:AbstractString,<:AbstractString}, A::AbstractAdelCat)
    rel = t[1]
    corel = t[2]
    
    gA = GapObj( A )
    qrows = CAP.UnderlyingCategory( gA )
    global path_algebra = CAP.UnderlyingQuiverAlgebra( qrows )
    
    rel = prepare_relations_str_for_eval( rel )
    corel = prepare_relations_str_for_eval( corel )
    
    rel = eval( Meta.parse( rel ) )
    corel = eval( Meta.parse( corel ) )
    
    rel = CAP.AsQuiverRowsMorphism( rel, qrows )
    corel = CAP.AsQuiverRowsMorphism( corel, qrows )
    
    cell = CAP.AdelmanCategoryObject( rel, corel )
    return AdelObj( cell )
end

function AdelmanCategory( quiver_str::AbstractString, relations_str::AbstractString )
    global quiver = CAP.RightQuiver( julia_to_gap( quiver_str ) )
    global ℚ = CAP.HomalgFieldOfRationals()
    global path_algebra = CAP.PathAlgebra( ℚ, quiver )
    
    str = prepare_relations_str_for_eval( relations_str )
    str = "[" * str * "]"
    eval_str = julia_to_gap( eval( Meta.parse( str ) ) )
    quotient_alg = CAP.QuotientOfPathAlgebra( path_algebra, eval_str )
    return AdelCat( CAP.AdelmanCategory( CAP.QuiverRowsDescentToZDefinedByBasisPaths( quotient_alg ) ) )
end

function Base.show(io::IO, ::MIME"text/latex", x::AbstractAdelCat )
    print( io, "Adelman category" )
end

export HomGens

## warning: only works properly if the HomStructure of Adel is a Freyd category
function HomGens( a :: AbstractAdelObj, b :: AbstractAdelObj )
    hom = Hom( a, b )
    iso = SimplifyObject_IsoToInputObject( hom, ∞ )
    iso_gap = GapObj( iso )
    gens = CAP.FREYD_CATEGORIES_GENERATORS_OF_FREYD_OBJECT_OVER_ROWS( CAP.Source( iso_gap ) );
    return [ AdelMor( CAP.HomStructure( GapObj( a ), GapObj( b ), CAP.PreCompose( gens[i], iso_gap ) ) ) for i in 1:CAP.Length( gens ) ]
end

export UnderlyingCategory

UnderlyingCategory( a::AbstractAdelCat ) = othercattype( CAP.UnderlyingCategory( GapObj(a) ) )
