## Supertype of all n-cells and categories
abstract type CAPType end

## Supertype of all n-cells and categories which rely on an underlying GAP object
abstract type CAPTypeGapWrapper <: CAPType end

gapwrap( x :: CAPTypeGapWrapper ) = x

GapObj( x :: CAPTypeGapWrapper ) = gapwrap(x).gap_obj

GapObj( x :: Array{ <:CAPTypeGapWrapper, 1 } ) = julia_to_gap( [ GapObj( elem ) for elem in x ] )

function Base.show(io::IO, ::MIME"text/latex", x::CAPTypeGapWrapper )
    print( io, "\$" * gap_to_julia( CAP.LaTeXOutput( GapObj( x ) ) ) * "\$" )
end

##
abstract type AbstractCat <: CAPTypeGapWrapper end

abstract type AbstractObj <: CAPTypeGapWrapper end

abstract type AbstractMor <: CAPTypeGapWrapper end

struct Cat <: AbstractCat
    gap_obj::GapObj
end

struct Obj <: AbstractObj
    gap_obj::GapObj
end

struct Mor <: AbstractMor
    gap_obj::GapObj
end

export Source, Range

for t = (Obj, Mor, Cat)
    @eval gapwrap( a :: $t ) = a
end

for t = (Obj, Mor, Cat, Array{Obj,1}, Array{Mor,1}, Array{Cat,1})
    @eval objtype( a :: $t ) = Obj
    @eval mortype( a :: $t ) = Mor
end

Source( a :: AbstractMor ) = objtype(a)(CAP.Source( GapObj( a ) ))
Range( a :: AbstractMor ) = objtype(a)(CAP.Range( GapObj( a ) ))

##

## global variable storing pairs [ GAPFilter, corresponding Julia Type ]
otherobjlist = []
othermorlist = []
othercatlist = []

function otherobjtype( x::GapObj )
    
    for pair in otherobjlist
        pair[1](x) && return pair[2](x)
    end
    
    return Obj( x )
end

function othermortype( x::GapObj )
    
    for pair in othermorlist
        pair[1](x) && return pair[2](x)
    end
    
    return Mor( x )
end

function othercattype( x::GapObj )
    
    for pair in othercatlist
        pair[1](x) && return pair[2](x)
    end
    
    return Cat( x )
end

function new_types_wrap_cat( str::AbstractString, gap_filter_obj::GapObj, gap_filter_mor::GapObj, gap_filter_cat::GapObj )
    new_types_wrap_cat(
        Meta.parse( "Abstract" * str * "Cat" ),
        Meta.parse( "Abstract" * str * "Obj" ),
        Meta.parse( "Abstract" * str * "Mor" ),
        Meta.parse( str * "Cat" ),
        Meta.parse( str * "Obj" ),
        Meta.parse( str * "Mor" ),
        gap_filter_obj,
        gap_filter_mor,
        gap_filter_cat
    )
end

function new_types_wrap_cat( acatsym::Symbol, aobjsym::Symbol, amorsym::Symbol, catsym::Symbol, objsym::Symbol, morsym::Symbol, gap_filter_obj::GapObj, gap_filter_mor::GapObj, gap_filter_cat::GapObj )
    
    exp =
        quote
            
            export $acatsym, $aobjsym, $amorsym, $catsym, $objsym, $morsym
            
            abstract type $acatsym <: AbstractCat end
            
            abstract type $aobjsym <: AbstractObj end
            
            abstract type $amorsym <: AbstractMor end
            
            struct $catsym <: $acatsym
                cat::AbstractCat
            end
            
            struct $objsym <: $aobjsym
                obj::AbstractObj
            end
            
            struct $morsym <: $amorsym
                mor::AbstractMor
            end
            
            gapwrap( a :: $objsym ) = a.obj
            gapwrap( a :: $morsym ) = a.mor
            gapwrap( a :: $catsym ) = a.cat

            ($objsym)( g :: GapObj ) = ($objsym)( Obj( g ) )
            ($morsym)( g :: GapObj ) = ($morsym)( Mor( g ) )
            ($catsym)( g :: GapObj ) = ($catsym)( Cat( g ) )
            
            for t = ($objsym, $morsym, $catsym, Array{$objsym,1}, Array{$morsym,1}, Array{$catsym,1})
                exp_inner =
                    quote
                        objtype( a :: $t ) = ($$objsym)
                        mortype( a :: $t ) = ($$morsym)
                    end
                
                eval( exp_inner )
                
            end
            
            push!( otherobjlist, [ $gap_filter_obj, $objsym ] )
            push!( othermorlist, [ $gap_filter_mor, $morsym ] )
            push!( othercatlist, [ $gap_filter_cat, $catsym ] )
            
        end
    
    eval( exp )
    
end

# create methods for all gap wrapped categories

struct CAPBasicOperationMetaData
    install_name
    gap_name
    input_type
    output_type
    output_type_pos
end

CAPBasicOperationMetaData( install_name, gap_name, input_type, output_type ) = CAPBasicOperationMetaData( install_name, gap_name, input_type, output_type, 1 )
CAPBasicOperationMetaData( install_name, input_type, output_type ) = CAPBasicOperationMetaData( install_name, install_name, input_type, output_type )

input_type_dict = 
    Dict( 
        "morphism" => "AbstractMor",
        "mor" => "AbstractMor",
        "AbstractMor" => "AbstractMor",
        "object" => "AbstractObj",
        "obj" => "AbstractObj",
        "AbstractObj" => "AbstractObj",
        "category" => "AbstractCat",
        "list_of_objects" => "Array{ <:AbstractObj, 1 }",
        "list_of_morphisms" => "Array{ <:AbstractMor, 1 }",
        "integer" => "Integer",
        "other_object" => "AbstractObj",
        "other_morphism" => "AbstractMor",
        "any" => "Any"
    )

output_type_dict = 
    Dict( 
        "obj" => "objtype",
        "object" => "objtype",
        "objtype" => "objtype",
        "mor" => "mortype",
        "morphism" => "mortype",
        "mortype" => "mortype",
        "bool" => "identity",
        "morphism_or_fail" => "mortype",
        "object_or_fail" => "objtype",
        "other_object" => "otherobjtype",
        "other_morphism" => "othermortype"
    )

function install_cap_basic_operation( data::CAPBasicOperationMetaData )
    
    l = length( data.input_type )
    vars = [ "INTERNAL_VAR_NAME" * string(i) for i in 1:l ]
    gap_obj_vars = [ Meta.parse( "GapObj( " * x * ")" ) for x in vars ]
    arguments = [ Meta.parse( vars[i] * "::" * input_type_dict[data.input_type[i]] ) for i in 1:l ]
    
    output_type = output_type_dict[data.output_type]
    
    if output_type == "mortype" || output_type == "objtype"
        constructor = Meta.parse( output_type * "(" * vars[data.output_type_pos] * ")" )
        
        if data.output_type == "morphism_or_fail" || data.output_type == "object_or_fail"
            constructor = :( x -> (x == gap_fail ? nothing : $(constructor)(x)) )
        end
    
    else
        constructor = Meta.parse( output_type )
    end
    
    @eval $(data.install_name)( $(arguments...) ) = $(constructor)( CAP.$(data.gap_name)($(gap_obj_vars...) ) )
    
end

# missing: 
# - all with givens, I need to know their non-with given signature
# - 2 cells
# - filter list in IsCodominating, IsDominating, IsEqualAsFactorobjects, IsEqualAsSubobjects
# - MereExistenceOfSolutionOfLinearSystemInAbCategory
# - MorphismBetweenDirectSums
#  - MultiplyWithElementOfCommutativeRingForMorphisms
# - UniversalMorphismFromImage, UniversalMorphismIntoCoimage
opt_in_list = [
    :AdditionForMorphisms,
    :AdditiveInverseForMorphisms,
    :AstrictionToCoimage,
    :BiasedWeakFiberProduct,
    :BiasedWeakPushout,
    :CanonicalIdentificationFromCoimageToImageObject,
    :CanonicalIdentificationFromImageObjectToCoimage,
    :CoastrictionToImage,
    :Coequalizer,
    :Coimage,
    :CoimageProjection,
    :CokernelColift,
    :CokernelObject,
    :CokernelProjection,
    :Colift,
    :ColiftAlongEpimorphism,
    :ComponentOfMorphismFromDirectSum,
    :ComponentOfMorphismIntoDirectSum,
    :Coproduct,
    :DirectProduct,
    :DirectSum,
    :DirectSumCodiagonalDifference,
    :DirectSumDiagonalDifference,
    :DirectSumMorphismToWeakBiPushout,
    :DirectSumProjectionInPushout,
    :DistinguishedObjectOfHomomorphismStructure,
    :DualOnObjects,
    :EmbeddingOfEqualizer,
    :EpimorphismFromSomeProjectiveObject,
    :EpimorphismFromSomeProjectiveObjectForKernelObject,
    :Equalizer,
    :FiberProduct,
    :FiberProductEmbeddingInDirectSum,
    :HomologyObject,
    :HomomorphismStructureOnObjects,
    :IdentityMorphism,
    :ImageEmbedding,
    :ImageObject,
    :InitialObject,
    :InitialObjectFunctorial,
    :InjectionOfBiasedWeakPushout,
    :InjectionOfCofactorOfCoproduct,
    :InjectionOfCofactorOfDirectSum,
    :InjectionOfCofactorOfPushout,
    :InjectionOfFirstCofactorOfWeakBiPushout,
    :InjectionOfSecondCofactorOfWeakBiPushout,
    :InjectiveColift,
    :InternalHomOnObjects,
    :InternalHomToTensorProductAdjunctionMap,
    :InterpretMorphismAsMorphismFromDistinguishedObjectToHomomorphismStructure,
    :InterpretMorphismFromDistinguishedObjectToHomomorphismStructureAsMorphism,
    :InverseImmutable,
    :IsAutomorphism,
    :IsColiftable,
    :IsColiftableAlongEpimorphism,
    :IsCongruentForMorphisms,
    :IsEndomorphism,
    :IsEpimorphism,
    :IsEqualForCacheForMorphisms,
    :IsEqualForCacheForObjects,
    :IsEqualForMorphisms,
    :IsEqualForMorphismsOnMor,
    :IsEqualForObjects,
    :IsHomSetInhabited,
    :IsIdempotent,
    :IsIdenticalToIdentityMorphism,
    :IsIdenticalToZeroMorphism,
    :IsInitial,
    :IsInjective,
    :IsIsomorphism,
    :IsLiftable,
    :IsLiftableAlongMonomorphism,
    :IsMonomorphism,
    :IsOne,
    :IsProjective,
    :IsSplitEpimorphism,
    :IsSplitMonomorphism,
    :IsTerminal,
    :IsWellDefinedForMorphisms,
    :IsWellDefinedForObjects,
    :IsZeroForMorphisms,
    :IsZeroForObjects,
    :IsomorphismFromCoequalizerOfCoproductDiagramToPushout,
    :IsomorphismFromCoimageToCokernelOfKernel,
    :IsomorphismFromCokernelOfDiagonalDifferenceToPushout,
    :IsomorphismFromCokernelOfKernelToCoimage,
    :IsomorphismFromCoproductToDirectSum,
    :IsomorphismFromDirectProductToDirectSum,
    :IsomorphismFromDirectSumToCoproduct,
    :IsomorphismFromDirectSumToDirectProduct,
    :IsomorphismFromDualToInternalHom,
    :IsomorphismFromEqualizerOfDirectProductDiagramToFiberProduct,
    :IsomorphismFromFiberProductToEqualizerOfDirectProductDiagram,
    :IsomorphismFromFiberProductToKernelOfDiagonalDifference,
    :IsomorphismFromHomologyObjectToItsConstructionAsAnImageObject,
    :IsomorphismFromImageObjectToKernelOfCokernel,
    :IsomorphismFromInitialObjectToZeroObject,
    :IsomorphismFromInternalHomToDual,
    :IsomorphismFromInternalHomToTensorProduct,
    :IsomorphismFromItsConstructionAsAnImageObjectToHomologyObject,
    :IsomorphismFromKernelOfCokernelToImageObject,
    :IsomorphismFromKernelOfDiagonalDifferenceToFiberProduct,
    :IsomorphismFromPushoutToCoequalizerOfCoproductDiagram,
    :IsomorphismFromPushoutToCokernelOfDiagonalDifference,
    :IsomorphismFromTensorProductToInternalHom,
    :IsomorphismFromTerminalObjectToZeroObject,
    :IsomorphismFromZeroObjectToInitialObject,
    :IsomorphismFromZeroObjectToTerminalObject,
    :KernelEmbedding,
    :KernelLift,
    :KernelObject,
    :LambdaElimination,
    :LambdaIntroduction,
    :Lift,
    :LiftAlongMonomorphism,
    :MonomorphismIntoSomeInjectiveObject,
    :MonomorphismToSomeInjectiveObjectForCokernelObject,
    :MorphismFromEqualizerToSink,
    :MorphismFromFiberProductToSink,
    :MorphismFromKernelObjectToSink,
    :MorphismFromSourceToCoequalizer,
    :MorphismFromSourceToCokernelObject,
    :MorphismFromSourceToPushout,
    :PostCompose,
    :PreCompose,
    :ProjectionInFactorOfDirectProduct,
    :ProjectionInFactorOfDirectSum,
    :ProjectionInFactorOfFiberProduct,
    :ProjectionInFirstFactorOfWeakBiFiberProduct,
    :ProjectionInSecondFactorOfWeakBiFiberProduct,
    :ProjectionOfBiasedWeakFiberProduct,
    :ProjectionOntoCoequalizer,
    :ProjectiveLift,
    :Pushout,
    :RankMorphism,
    :SimplifyEndo,
    :SimplifyEndo_IsoFromInputObject,
    :SimplifyEndo_IsoToInputObject,
    :SimplifyMorphism,
    :SimplifyObject,
    :SimplifyObject_IsoFromInputObject,
    :SimplifyObject_IsoToInputObject,
    :SimplifyRange,
    :SimplifyRange_IsoFromInputObject,
    :SimplifyRange_IsoToInputObject,
    :SimplifySource,
    :SimplifySourceAndRange,
    :SimplifySourceAndRange_IsoFromInputRange,
    :SimplifySourceAndRange_IsoFromInputSource,
    :SimplifySourceAndRange_IsoToInputRange,
    :SimplifySourceAndRange_IsoToInputSource,
    :SimplifySource_IsoFromInputObject,
    :SimplifySource_IsoToInputObject,
    :SomeInjectiveObject,
    :SomeInjectiveObjectForCokernelObject,
    :SomeProjectiveObject,
    :SomeProjectiveObjectForKernelObject,
    :SomeReductionBySplitEpiSummand,
    :SomeReductionBySplitEpiSummand_MorphismFromInputRange,
    :SomeReductionBySplitEpiSummand_MorphismToInputRange,
    :SubtractionForMorphisms,
    :TensorProductOnObjects,
    :TensorProductToInternalHomAdjunctionMap,
    :TensorUnit,
    :TerminalObject,
    :TerminalObjectFunctorial,
    :TraceMap,
    :UniversalMorphismFromBiasedWeakPushout,
    :UniversalMorphismFromCoequalizer,
    :UniversalMorphismFromCoproduct,
    :UniversalMorphismFromDirectSum,
    :UniversalMorphismFromInitialObject,
    :UniversalMorphismFromPushout,
    :UniversalMorphismFromWeakBiPushout,
    :UniversalMorphismFromZeroObject,
    :UniversalMorphismIntoBiasedWeakFiberProduct,
    :UniversalMorphismIntoDirectProduct,
    :UniversalMorphismIntoDirectSum,
    :UniversalMorphismIntoEqualizer,
    :UniversalMorphismIntoFiberProduct,
    :UniversalMorphismIntoTerminalObject,
    :UniversalMorphismIntoWeakBiFiberProduct,
    :UniversalMorphismIntoZeroObject,
    :UniversalPropertyOfDual,
    :WeakBiFiberProduct,
    :WeakBiFiberProductMorphismToDirectSum,
    :WeakBiPushout,
    :WeakCokernelColift,
    :WeakCokernelObject,
    :WeakCokernelProjection,
    :WeakKernelEmbedding,
    :WeakKernelLift,
    :WeakKernelObject,
    :ZeroMorphism,
    :ZeroObject,
    :ZeroObjectFunctorial
]

function gap_to_julia_filter( elem )
    ( gap_isstring( elem ) || gap_isint( elem ) ) && return gap_to_julia( elem )
    ( elem == gap_isint ) && return "integer"
    ( elem == gap_isobject ) && return "any"
end

gap_to_julia_filter_list( flist ) = [ gap_to_julia_filter( flist[i] ) for i in 1:CAP.Length( flist ) ]

l = length( opt_in_list )
data = Array{ CAPBasicOperationMetaData }(undef, l )
cap_method_record = CAP.CAP_INTERNAL_METHOD_NAME_RECORD

for i in 1:l
    method_rec_entry = eval( :( cap_method_record.$(opt_in_list[i]) ) )
    
    if gap_isbound( method_rec_entry, "argument_list" )
        input_type = gap_to_julia_filter_list( method_rec_entry.filter_list )[ gap_to_julia( method_rec_entry.argument_list ) ]
    else
        input_type = gap_to_julia_filter_list( method_rec_entry.filter_list )
    end
    
    output_type = gap_to_julia_filter( method_rec_entry.return_type )
    data[i] = CAPBasicOperationMetaData( opt_in_list[i], input_type, output_type )
end

## missing installations

conv_with_given = [
    CAPBasicOperationMetaData( :HomomorphismStructureOnMorphisms, [ "morphism", "morphism" ], "other_morphism" ),
    CAPBasicOperationMetaData( :KernelObjectFunctorial, [ "morphism", "morphism", "morphism" ], "morphism" ),
    CAPBasicOperationMetaData( :CokernelObjectFunctorial, [ "morphism", "morphism", "morphism" ], "morphism" ),
    CAPBasicOperationMetaData( :DirectSumFunctorial, [ "list_of_morphisms" ], "morphism" ),
    CAPBasicOperationMetaData( :HomologyObjectFunctorial, [ "morphism", "morphism", "morphism", "morphism", "morphism" ], "morphism" )
]

append!( data, conv_with_given ) 

## install

for d in data
    
    @eval export $(d.install_name)
    
    install_cap_basic_operation( d )
    
end

## convenience methods

export ⊕, ⋅, ∘, ==

⋅( a::AbstractMor, b::AbstractMor ) = PreCompose( a, b )
∘( a::AbstractMor, b::AbstractMor ) = PostCompose( a, b )

==( a::AbstractMor, b::AbstractMor ) = IsCongruentForMorphisms( a, b ) 
==( a::AbstractObj, b::AbstractObj ) = IsEqualForObjects( a, b ) # it would be better to have something like === here

Id( a::AbstractObj ) = IdentityMorphism( a )

DirectSum( x :: AbstractObj... ) = DirectSum( collect( x ) )
DirectSumFunctorial( x :: AbstractMor... ) = DirectSumFunctorial( collect( x ) )
⊕( a :: AbstractObj, b :: AbstractObj ) = DirectSum( a, b )
⊕( a :: AbstractMor, b :: AbstractMor ) = DirectSumFunctorial( a, b )
⊕( a :: AbstractObj, b :: AbstractMor ) = Id(a) ⊕ b
⊕( a :: AbstractMor, b :: AbstractObj ) = a ⊕ Id(b)

export Inverse, IsZero, Pullback, ProjectionInFactorOfPullback, UniversalMorphismIntoPullback, Hom, Id, Simplify

Inverse = InverseImmutable
Pullback = FiberProduct
ProjectionInFactorOfPullback = ProjectionInFactorOfFiberProduct
UniversalMorphismIntoPullback = UniversalMorphismIntoFiberProduct

IsZero( a::AbstractObj ) = IsZeroForObjects( a )
IsZero( a::AbstractMor ) = IsZeroForMorphisms( a )

Hom( a::AbstractObj, b::AbstractObj ) = HomomorphismStructureOnObjects( a, b )
Hom( a::AbstractMor, b::AbstractMor ) = HomomorphismStructureOnMorphisms( a, b )
Hom( a::AbstractObj, b::AbstractMor ) = Hom( Id( a ), b )
Hom( a::AbstractMor, b::AbstractObj ) = Hom( a, Id( b ) )
Hom( a::AbstractMor ) = InterpretMorphismAsMorphismFromDistinguishedObjectToHomomorphismStructure( a )
Hom( a::AbstractObj, b::AbstractObj, c::AbstractMor ) = InterpretMorphismFromDistinguishedObjectToHomomorphismStructureAsMorphism( a, b, c )
Hom( a::AbstractCat ) = DistinguishedObjectOfHomomorphismStructure( a )

Simplify( a::AbstractObj ) = SimplifyObject( a, ∞ )