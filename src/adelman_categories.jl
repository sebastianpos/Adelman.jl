new_types_wrap_cat( "Adel", CAP.IsAdelmanCategoryObject, CAP.IsAdelmanCategoryMorphism )

## Convenience constructors

function /(str::AbstractString, A::AbstractAdelCat)
    gA = GapObj( A )
    cell = Base.getproperty( CAP.UnderlyingCategory( gA ), str )/gA
    CAP.IsCapCategoryObject( cell ) && return AdelObj( cell )
    CAP.IsCapCategoryMorphism( cell ) && return AdelMor( cell )
end

function /(t::Tuple{<:AbstractString,<:AbstractString}, A::AbstractAdelCat)
    gA = GapObj( A )
    
    rel = Base.getproperty( CAP.UnderlyingCategory( gA ), t[1] )
    CAP.IsCapCategoryObject( rel ) && ( rel = CAP.IdentityMorphism( rel ) )
    
    corel = Base.getproperty( CAP.UnderlyingCategory( gA ), t[2] )
    CAP.IsCapCategoryObject( corel ) && ( corel = CAP.IdentityMorphism( corel ) )
    
    cell = CAP.AdelmanCategoryObject( rel, corel )
    return AdelObj( cell )
end

global quiver
global ℚ
global path_algebra

function AdelmanCategory( quiver_str::AbstractString, relations_str::AbstractString )
    global quiver = CAP.RightQuiver( julia_to_gap( quiver_str ) )
    global ℚ = CAP.HomalgFieldOfRationals()
    global path_algebra = CAP.PathAlgebra( ℚ, quiver )
    
    ## String manipulation for the relations
    char_test( x :: AbstractChar ) = !isspace(x) && !(x in ('[',']') )
    str = relations_str
    str = filter( x -> char_test( x ), str )
    str = "," * str
    ialg = "path_algebra."
    reg = r"(?<coeff>([\,\+\-])+(\d)*(\*)?)(?<path>[^(\d)\*\-\+])"
    sstr = SubstitutionString( "\\g<coeff>$(ialg)\\g<path>" )
    str = replace( str, reg => sstr )
    str = "[" * str[2:end] * "]"
    
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