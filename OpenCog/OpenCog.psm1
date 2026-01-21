<#
.SYNOPSIS
    OpenCog Cognitive Architecture in PowerShell
    
.DESCRIPTION
    A pure PowerShell implementation of OpenCog's core cognitive architecture components:
    - Atoms: Nodes and Links forming a hypergraph
    - AtomSpace: Knowledge representation and storage
    - Pattern Matching: Query and unification engine
    - Truth Values: Probabilistic truth value system
    
.NOTES
    Author: OpenCog PowerShell Project
    Version: 1.0.0
    
.LINK
    https://opencog.org
#>

# Import core modules
$CorePath = Join-Path $PSScriptRoot "Core"

# Import Atoms module (base types)
Import-Module (Join-Path $CorePath "Atoms.psm1") -Force

# Import AtomSpace module
Import-Module (Join-Path $CorePath "AtomSpace.psm1") -Force

# Import Pattern Matcher module
Import-Module (Join-Path $CorePath "PatternMatcher.psm1") -Force

# Re-export all functions from core modules
$ExportedFunctions = @(
    # Atom creation functions
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
    
    # AtomSpace functions
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
    
    # Pattern matching functions
    'New-PatternMatcher',
    'Find-Pattern',
    'New-QueryBuilder',
    'Find-AtomsByPredicate',
    'Get-MatchResults',
    'Invoke-Query'
)

Export-ModuleMember -Function $ExportedFunctions

# Module initialization
Write-Verbose "OpenCog PowerShell module loaded"
Write-Verbose "Core components: Atoms, AtomSpace, PatternMatcher"
