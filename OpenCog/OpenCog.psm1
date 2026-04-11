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
    - Advanced Pattern Matching: GetLink, BindLink, SatisfactionLink, etc. (Phase 3)
    - Exotic Atoms: Domain-specific and hierarchical atom types (Phase 3.5)
    - PLN: Probabilistic Logic Networks — extended truth values and deduction rules (Phase 4)
    
.NOTES
    Author: OpenCog PowerShell Project
    Version: 2.0.0 (Phase 4 - PLN Infrastructure)
    
.LINK
    https://opencog.org
#>

# Import core modules
$CorePath    = Join-Path $PSScriptRoot "Core"
$PLNPath     = Join-Path $PSScriptRoot "PLN"

# Core modules (Phase 1 + Phase 2 + Phase 3 integrated)
Import-Module (Join-Path $CorePath "Atoms.psm1") -Force
Import-Module (Join-Path $CorePath "AtomSpace.psm1") -Force
Import-Module (Join-Path $CorePath "PatternMatcher.psm1") -Force
Import-Module (Join-Path $CorePath "ExoticAtoms.psm1") -Force

# PLN modules (Phase 4 - Basic PLN Infrastructure)
Import-Module (Join-Path $PLNPath "TruthValues.psm1") -Force
Import-Module (Join-Path $PLNPath "DeductionRules.psm1") -Force

# PLN modules (Phase 5 - Advanced PLN Reasoning)
Import-Module (Join-Path $PLNPath "InductionAbduction.psm1") -Force
Import-Module (Join-Path $PLNPath "HigherOrderInference.psm1") -Force
Import-Module (Join-Path $PLNPath "TemporalReasoning.psm1") -Force

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
    'Invoke-AdvancedPattern',
    'Invoke-PatternInstantiation',
    
    # Phase 3.5 - Exotic Atom Types
    'New-ExoticNode',
    'New-AtomSpaceNode',
    'New-DistributedAtomSpace',
    'New-GitHubRepoAtom',
    'New-GitHubOrgAtom',
    'New-GitHubEnterpriseAtom',
    'New-AzureEntraTenantAtom',
    'New-AzureSubscriptionAtom',
    'New-ExchangeMailboxAtom',
    'New-ExchangeCalendarAtom',
    'New-OpenCogAtomSpaceAtom',
    'Test-ExoticAtom',
    'Test-AtomSpaceAtom',
    'Get-ExoticAtomUri',
    'Get-ExoticAtomProperties',
    'Register-ExoticAtomType',
    'Get-RegisteredExoticTypes',

    # Phase 4 - PLN Extended Truth Values
    'New-SimpleTruthValue',
    'New-CountTruthValue',
    'New-IndefiniteTruthValue',
    'New-FuzzyTruthValue',
    'New-ProbabilisticTruthValue',
    'Invoke-TVRevision',
    'ConvertTo-SimpleTruthValue',

    # Phase 4 - PLN Deduction Rules
    'Invoke-PLNDeduction',
    'Invoke-ModusPonens',
    'Invoke-ModusTollens',
    'Invoke-PLNContraposition',
    'Invoke-HypotheticalSyllogism',
    'Invoke-AtomSpaceDeduction',

    # Phase 5 - PLN Induction and Abduction
    'Invoke-PLNInduction',
    'Invoke-PLNAbduction',
    'Invoke-PLNInversion',
    'Invoke-PLNAndIntroduction',
    'Invoke-PLNOrIntroduction',
    'Invoke-PLNNotIntroduction',

    # Phase 5 - PLN Higher-Order Inference
    'Invoke-InheritanceToSimilarity',
    'Invoke-SimilarityToInheritance',
    'Invoke-IntensionalInheritance',
    'Invoke-ExtensionalInheritance',
    'Invoke-AttractorRule',
    'Invoke-SymmetricSimilarity',
    'Invoke-CombinedInheritance',

    # Phase 5 - Temporal Reasoning
    'New-TemporalInterval',
    'New-EventAtom',
    'Get-AllenRelation',
    'Get-AllAllenRelations',
    'Invoke-TemporalDeduction',
    'Invoke-TemporalProjection',
    'Test-TemporalOverlap'
)

Export-ModuleMember -Function $ExportedFunctions

# Module initialization
Write-Verbose "OpenCog PowerShell module loaded"
Write-Verbose "Core components: Atoms, AtomSpace, PatternMatcher, ExoticAtoms"
Write-Verbose "Phase 2 features: Advanced Links, Type System, Value Atoms (Extended)"
Write-Verbose "Phase 3 features: Advanced Pattern Matching (GetLink, BindLink, etc.)"
Write-Verbose "Phase 3.5 features: Exotic Atoms (GitHub, Azure, Exchange, Distributed)"
Write-Verbose "Phase 4 features: PLN TruthValues + Deduction Rules"
Write-Verbose "Phase 5 features: PLN Induction/Abduction, Higher-Order Inference, Temporal Reasoning"
Write-Verbose "Total functions exported: $($ExportedFunctions.Count)"
