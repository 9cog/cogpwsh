<#
.SYNOPSIS
    OpenCog Atom types implementation in PowerShell
    
.DESCRIPTION
    Implements the fundamental Atom types for OpenCog cognitive architecture:
    - Atom (base class)
    - Node (named atoms)
    - Link (relational atoms connecting other atoms)
    - TruthValue (probabilistic truth values)
    
.NOTES
    Part of OpenCog PowerShell implementation
#>

# Atom Type Enumeration
enum AtomType {
    Atom
    Node
    Link
    ConceptNode
    PredicateNode
    VariableNode
    ListLink
    InheritanceLink
    SimilarityLink
    EvaluationLink
    ImplicationLink
    AndLink
    OrLink
    NotLink
}

<#
.SYNOPSIS
    Truth Value representation with strength and confidence
#>
class TruthValue {
    [double]$Strength
    [double]$Confidence
    
    TruthValue([double]$strength, [double]$confidence) {
        if ($strength -lt 0 -or $strength -gt 1) {
            throw "Strength must be between 0 and 1"
        }
        if ($confidence -lt 0 -or $confidence -gt 1) {
            throw "Confidence must be between 0 and 1"
        }
        $this.Strength = $strength
        $this.Confidence = $confidence
    }
    
    [string] ToString() {
        return "(TV {0:F3} {1:F3})" -f $this.Strength, $this.Confidence
    }
    
    [bool] Equals([object]$other) {
        if ($null -eq $other -or $other -isnot [TruthValue]) {
            return $false
        }
        return [Math]::Abs($this.Strength - $other.Strength) -lt 0.001 -and
               [Math]::Abs($this.Confidence - $other.Confidence) -lt 0.001
    }
    
    # Simple Bayesian revision
    [TruthValue] Merge([TruthValue]$other) {
        $totalConf = $this.Confidence + $other.Confidence
        if ($totalConf -eq 0) {
            return [TruthValue]::new(0.5, 0.0)
        }
        
        $newStrength = ($this.Strength * $this.Confidence + 
                       $other.Strength * $other.Confidence) / $totalConf
        $newConfidence = [Math]::Min(1.0, $totalConf)
        
        return [TruthValue]::new($newStrength, $newConfidence)
    }
}

<#
.SYNOPSIS
    Base Atom class - fundamental unit in OpenCog
#>
class Atom {
    [guid]$Handle
    [AtomType]$Type
    [TruthValue]$TV
    [hashtable]$Metadata
    
    Atom([AtomType]$type) {
        $this.Handle = [guid]::NewGuid()
        $this.Type = $type
        $this.TV = [TruthValue]::new(1.0, 1.0)
        $this.Metadata = @{}
    }
    
    [string] ToString() {
        return "({0} {1})" -f $this.Type, $this.Handle
    }
    
    [void] SetTruthValue([double]$strength, [double]$confidence) {
        $this.TV = [TruthValue]::new($strength, $confidence)
    }
    
    [TruthValue] GetTruthValue() {
        return $this.TV
    }
    
    [guid] GetHandle() {
        return $this.Handle
    }
    
    [AtomType] GetAtomType() {
        return $this.Type
    }
    
    [void] SetMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }
    
    [object] GetMetadata([string]$key) {
        return $this.Metadata[$key]
    }
    
    [bool] Equals([object]$other) {
        if ($null -eq $other -or $other -isnot [Atom]) {
            return $false
        }
        return $this.Handle -eq $other.Handle
    }
    
    [int] GetHashCode() {
        return $this.Handle.GetHashCode()
    }
}

<#
.SYNOPSIS
    Node - Named atom representing concepts, predicates, or variables
#>
class Node : Atom {
    [string]$Name
    
    Node([AtomType]$type, [string]$name) : base($type) {
        $this.Name = $name
    }
    
    [string] ToString() {
        return "({0} `"{1}`" {2})" -f $this.Type, $this.Name, $this.TV
    }
    
    [string] GetName() {
        return $this.Name
    }
    
    [bool] Equals([object]$other) {
        if ($null -eq $other -or $other -isnot [Node]) {
            return $false
        }
        # Nodes are equal if they have same type and name
        return $this.Type -eq $other.Type -and $this.Name -eq $other.Name
    }
    
    [int] GetHashCode() {
        return ($this.Type.ToString() + $this.Name).GetHashCode()
    }
}

<#
.SYNOPSIS
    Link - Connects atoms together forming hypergraph relationships
#>
class Link : Atom {
    [System.Collections.Generic.List[Atom]]$Outgoing
    
    Link([AtomType]$type, [Atom[]]$outgoing) : base($type) {
        $this.Outgoing = [System.Collections.Generic.List[Atom]]::new()
        foreach ($atom in $outgoing) {
            if ($null -ne $atom) {
                $this.Outgoing.Add($atom)
            }
        }
    }
    
    [string] ToString() {
        $outStr = ($this.Outgoing | ForEach-Object { $_.ToString() }) -join " "
        return "({0} {1} {2})" -f $this.Type, $outStr, $this.TV
    }
    
    [System.Collections.Generic.List[Atom]] GetOutgoingSet() {
        return $this.Outgoing
    }
    
    [int] GetArity() {
        return $this.Outgoing.Count
    }
    
    [Atom] GetOutgoingAtom([int]$index) {
        if ($index -lt 0 -or $index -ge $this.Outgoing.Count) {
            throw "Index out of bounds"
        }
        return $this.Outgoing[$index]
    }
    
    [bool] Equals([object]$other) {
        if ($null -eq $other -or $other -isnot [Link]) {
            return $false
        }
        
        # Links are equal if they have same type and same outgoing atoms
        if ($this.Type -ne $other.Type -or $this.GetArity() -ne $other.GetArity()) {
            return $false
        }
        
        for ($i = 0; $i -lt $this.GetArity(); $i++) {
            if (-not $this.Outgoing[$i].Equals($other.Outgoing[$i])) {
                return $false
            }
        }
        
        return $true
    }
    
    [int] GetHashCode() {
        $hash = $this.Type.GetHashCode()
        foreach ($atom in $this.Outgoing) {
            $hash = $hash -bxor $atom.GetHashCode()
        }
        return $hash
    }
}

# Factory functions for creating specific atom types

function New-ConceptNode {
    <#
    .SYNOPSIS
        Creates a new ConceptNode
    .PARAMETER Name
        The name of the concept
    .PARAMETER Strength
        Truth value strength (0-1)
    .PARAMETER Confidence
        Truth value confidence (0-1)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $node = [Node]::new([AtomType]::ConceptNode, $Name)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-PredicateNode {
    <#
    .SYNOPSIS
        Creates a new PredicateNode
    .PARAMETER Name
        The name of the predicate
    .PARAMETER Strength
        Truth value strength (0-1)
    .PARAMETER Confidence
        Truth value confidence (0-1)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $node = [Node]::new([AtomType]::PredicateNode, $Name)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-VariableNode {
    <#
    .SYNOPSIS
        Creates a new VariableNode for pattern matching
    .PARAMETER Name
        The name of the variable (typically starts with $)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    return [Node]::new([AtomType]::VariableNode, $Name)
}

function New-InheritanceLink {
    <#
    .SYNOPSIS
        Creates an InheritanceLink between two atoms
    .PARAMETER Child
        The child (specific) atom
    .PARAMETER Parent
        The parent (general) atom
    .PARAMETER Strength
        Truth value strength (0-1)
    .PARAMETER Confidence
        Truth value confidence (0-1)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Child,
        
        [Parameter(Mandatory)]
        [Atom]$Parent,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::InheritanceLink, @($Child, $Parent))
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-SimilarityLink {
    <#
    .SYNOPSIS
        Creates a SimilarityLink between two atoms
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom1,
        
        [Parameter(Mandatory)]
        [Atom]$Atom2,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::SimilarityLink, @($Atom1, $Atom2))
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-EvaluationLink {
    <#
    .SYNOPSIS
        Creates an EvaluationLink (predicate applied to arguments)
    .PARAMETER Predicate
        The predicate atom
    .PARAMETER Arguments
        Array of argument atoms (typically in a ListLink)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Predicate,
        
        [Parameter(Mandatory)]
        [Atom[]]$Arguments,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    # Create ListLink for arguments if needed
    $listLink = [Link]::new([AtomType]::ListLink, $Arguments)
    $link = [Link]::new([AtomType]::EvaluationLink, @($Predicate, $listLink))
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-ListLink {
    <#
    .SYNOPSIS
        Creates a ListLink (ordered collection of atoms)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom[]]$Atoms
    )
    
    return [Link]::new([AtomType]::ListLink, $Atoms)
}

function New-AndLink {
    <#
    .SYNOPSIS
        Creates an AndLink (logical AND)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom[]]$Atoms,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::AndLink, $Atoms)
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-OrLink {
    <#
    .SYNOPSIS
        Creates an OrLink (logical OR)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom[]]$Atoms,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::OrLink, $Atoms)
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-ImplicationLink {
    <#
    .SYNOPSIS
        Creates an ImplicationLink (if-then relationship)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Antecedent,
        
        [Parameter(Mandatory)]
        [Atom]$Consequent,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::ImplicationLink, @($Antecedent, $Consequent))
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

#
# Phase 2 - Extended Atom Types
#

# Advanced Node Types

class NumberNode : Node {
    [double]$Value
    
    NumberNode([double]$value) : base([AtomType]::ConceptNode, $value.ToString()) {
        $this.Value = $value
        $this.SetMetadata('NodeSubType', 'NumberNode')
    }
    
    [double] GetValue() { return $this.Value }
}

class StringNode : Node {
    StringNode([string]$value) : base([AtomType]::ConceptNode, $value) {
        $this.SetMetadata('NodeSubType', 'StringNode')
    }
}

class TypeNode : Node {
    TypeNode([string]$typeName) : base([AtomType]::ConceptNode, $typeName) {
        $this.SetMetadata('NodeSubType', 'TypeNode')
        $this.SetMetadata('IsType', $true)
    }
}

# Phase 2 - Advanced Link Factory Functions

function New-ContextLink {
    <#
    .SYNOPSIS
        Creates a ContextLink for contextual relationships
    .PARAMETER Context
        The context atom
    .PARAMETER Atom
        The atom within this context
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Context,
        
        [Parameter(Mandatory)]
        [Atom]$Atom,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Context, $Atom))
    $link.SetMetadata('LinkSubType', 'ContextLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-MemberLink {
    <#
    .SYNOPSIS
        Creates a MemberLink for set membership
    .PARAMETER Element
        The element atom
    .PARAMETER Set
        The set atom
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Element,
        
        [Parameter(Mandatory)]
        [Atom]$Set,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Element, $Set))
    $link.SetMetadata('LinkSubType', 'MemberLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-SubsetLink {
    <#
    .SYNOPSIS
        Creates a SubsetLink for subset relationships
    .PARAMETER Subset
        The subset atom
    .PARAMETER Superset
        The superset atom
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Subset,
        
        [Parameter(Mandatory)]
        [Atom]$Superset,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Subset, $Superset))
    $link.SetMetadata('LinkSubType', 'SubsetLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-EquivalenceLink {
    <#
    .SYNOPSIS
        Creates an EquivalenceLink for bidirectional equivalence
    .PARAMETER Atom1
        First atom
    .PARAMETER Atom2
        Second atom
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom1,
        
        [Parameter(Mandatory)]
        [Atom]$Atom2,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Atom1, $Atom2))
    $link.SetMetadata('LinkSubType', 'EquivalenceLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-SequentialAndLink {
    <#
    .SYNOPSIS
        Creates a SequentialAndLink for ordered conjunctions
    .PARAMETER Atoms
        Array of atoms in sequence
    #>
    param(
        [Parameter(Mandatory)]
        [Atom[]]$Atoms,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::AndLink, $Atoms)
    $link.SetMetadata('LinkSubType', 'SequentialAndLink')
    $link.SetMetadata('Ordered', $true)
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

# Phase 2 - Value Atom Factory Functions

function New-NumberNode {
    <#
    .SYNOPSIS
        Creates a NumberNode for numeric values
    .PARAMETER Value
        The numeric value
    #>
    param(
        [Parameter(Mandatory)]
        [double]$Value,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $node = [NumberNode]::new($Value)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-StringNode {
    <#
    .SYNOPSIS
        Creates a StringNode for string values
    .PARAMETER Value
        The string value
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Value,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $node = [StringNode]::new($Value)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-TypeNode {
    <#
    .SYNOPSIS
        Creates a TypeNode for type definitions
    .PARAMETER TypeName
        The name of the type
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TypeName
    )
    
    return [TypeNode]::new($TypeName)
}

function New-TypedAtomLink {
    <#
    .SYNOPSIS
        Creates a TypedAtomLink to annotate an atom with its type
    .PARAMETER Atom
        The atom to type
    .PARAMETER Type
        The type (should be a TypeNode)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom,
        
        [Parameter(Mandatory)]
        [Atom]$Type,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Atom, $Type))
    $link.SetMetadata('LinkSubType', 'TypedAtomLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-SignatureLink {
    <#
    .SYNOPSIS
        Creates a SignatureLink for function signatures
    .PARAMETER Function
        The function atom
    .PARAMETER Signature
        The signature atom (typically an ArrowLink)
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Function,
        
        [Parameter(Mandatory)]
        [Atom]$Signature,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($Function, $Signature))
    $link.SetMetadata('LinkSubType', 'SignatureLink')
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

function New-ArrowLink {
    <#
    .SYNOPSIS
        Creates an ArrowLink for function types (Input -> Output)
    .PARAMETER InputTypes
        The input types (typically a ListLink)
    .PARAMETER OutputType
        The output type
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$InputTypes,
        
        [Parameter(Mandatory)]
        [Atom]$OutputType,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $link = [Link]::new([AtomType]::Link, @($InputTypes, $OutputType))
    $link.SetMetadata('LinkSubType', 'ArrowLink')
    $link.SetMetadata('IsFunctionType', $true)
    $link.SetTruthValue($Strength, $Confidence)
    return $link
}

# Phase 2 - Helper Functions

function Get-AtomValue {
    <#
    .SYNOPSIS
        Gets the value from a value atom (NumberNode, StringNode, etc.)
    #>
    param([Atom]$Atom)
    
    if ($Atom -is [NumberNode]) {
        return $Atom.GetValue()
    }
    if ($Atom -is [StringNode] -or $Atom -is [Node]) {
        return $Atom.Name
    }
    return $null
}

function Test-AtomType {
    <#
    .SYNOPSIS
        Tests if an atom matches a specific subtype
    .PARAMETER Atom
        The atom to test
    .PARAMETER SubType
        The subtype to check (e.g., 'NumberNode', 'MemberLink')
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom,
        
        [Parameter(Mandatory)]
        [string]$SubType
    )
    
    return $Atom.GetMetadata('NodeSubType') -eq $SubType -or 
           $Atom.GetMetadata('LinkSubType') -eq $SubType
}

# Export module members
Export-ModuleMember -Function @(
    # Phase 1 - Core functions
    'New-ConceptNode',
    'New-PredicateNode',
    'New-VariableNode',
    'New-InheritanceLink',
    'New-SimilarityLink',
    'New-EvaluationLink',
    'New-ListLink',
    'New-AndLink',
    'New-OrLink',
    'New-ImplicationLink',
    
    # Phase 2 - Advanced Links
    'New-ContextLink',
    'New-MemberLink',
    'New-SubsetLink',
    'New-EquivalenceLink',
    'New-SequentialAndLink',
    
    # Phase 2 - Value Atoms
    'New-NumberNode',
    'New-StringNode',
    
    # Phase 2 - Type System
    'New-TypeNode',
    'New-TypedAtomLink',
    'New-SignatureLink',
    'New-ArrowLink',
    
    # Phase 2 - Helpers
    'Get-AtomValue',
    'Test-AtomType'
) -Variable @() -Cmdlet @()
