<#
.SYNOPSIS
    OpenCog Cognitive Architecture in PowerShell
    
.DESCRIPTION
    A pure PowerShell implementation of OpenCog's core cognitive architecture components:
    - Atoms: Nodes and Links forming a hypergraph
    - AtomSpace: Knowledge representation and storage
    - Pattern Matching: Query and unification engine
    - Truth Values: Probabilistic truth value system
    - Extended Atom Types: Advanced links, type system, value atoms (Phase 2)
    
.NOTES
    Author: OpenCog PowerShell Project
    Version: 1.2.0 (Phase 3 - Advanced Pattern Matching)
    
.LINK
    https://opencog.org
#>

# Import core modules
$CorePath = Join-Path $PSScriptRoot "Core"

# Core modules (Phase 1 + Phase 2 integrated)
Import-Module (Join-Path $CorePath "Atoms.psm1") -Force
Import-Module (Join-Path $CorePath "AtomSpace.psm1") -Force
Import-Module (Join-Path $CorePath "PatternMatcher.psm1") -Force

# Phase 3 - Advanced Pattern Matching
Import-Module (Join-Path $CorePath "AdvancedPatternMatcher.psm1") -Force

# Re-export all functions from core modules
$ExportedFunctions = @(
    # Phase 1 - Core Atom creation functions
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
    
    # Phase 1 - AtomSpace functions
    'New-AtomSpace',
    'Add-Atom',
    'Get-Atom',
    'Get-AtomsByType',
    'Get-Node',
    'Get-IncomingSet',
    'Remove-Atom',
    'Clear-AtomSpace',
    'Get-AtomSpaceStatistics',
    'Export-AtomSpace',
    
    # Phase 1 - Pattern matching functions
    'New-PatternMatcher',
    'Find-Pattern',
    'New-QueryBuilder',
    'Find-AtomsByPredicate',
    'Get-MatchResults',
    'Invoke-Query',
    
    # Phase 2 - Advanced Link Types
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
    'Test-AtomType',
    
    # Phase 2 Extended - Additional Value Atoms
    'New-FloatValue',
    'New-LinkValue',
    
    # Phase 2 Extended - Type System Extensions
    'New-TypeChoice',
    'New-TypeIntersection',
    
    # Phase 2 Extended - Additional Links
    'New-ImplicationScopeLink',
    'New-PresentLink',
    
    # Phase 2 Extended - Value Extractors
    'Get-TruthValueOf',
    'Get-StrengthOf',
    'Get-ConfidenceOf',
    
    # Phase 2 Extended - Type System Helpers
    'Test-TypeCompatibility',
    'Get-TypeHierarchy',
    
    # Phase 3 - Advanced Pattern Matching
    'New-GetLink',
    'New-BindLink',
    'New-SatisfactionLink',
    'New-DualLink',
    'New-ChoiceLink',
    'New-SequentialOrLink',
    'New-AbsentLink',
    'New-AdvancedPatternMatcher',
    'Invoke-AdvancedPattern'
)

Export-ModuleMember -Function $ExportedFunctions

# Module initialization
Write-Verbose "OpenCog PowerShell module loaded"
Write-Verbose "Core components: Atoms, AtomSpace, PatternMatcher"
Write-Verbose "Phase 2 features: Advanced Links, Type System, Value Atoms (Extended)"
Write-Verbose "Phase 3 features: Advanced Pattern Matching (GetLink, BindLink, etc.)"
Write-Verbose "Total functions exported: $($ExportedFunctions.Count)"
