@{
    # Script module or binary module file associated with this manifest
    RootModule = 'OpenCog.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    
    # Author of this module
    Author = 'OpenCog PowerShell Project'
    
    # Company or vendor of this module
    CompanyName = 'OpenCog Community'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 OpenCog PowerShell Project. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = @'
OpenCog Cognitive Architecture implemented in pure PowerShell.

This module provides a complete implementation of OpenCog's core components:

- Atoms: Nodes and Links forming a hypergraph structure
- AtomSpace: Hypergraph-based knowledge representation system
- Pattern Matching: Query and unification engine for knowledge retrieval
- Truth Values: Probabilistic truth value system with Bayesian updating

Features:
* Create and manage cognitive atoms (nodes and links)
* Store knowledge in a hypergraph AtomSpace
* Query patterns with variable binding
* Represent uncertain knowledge with truth values
* Build intelligent systems using cognitive architecture principles

Perfect for:
- AI and cognitive systems research
- Knowledge representation and reasoning
- Semantic networks and ontologies
- Pattern-based inference systems
- Educational exploration of cognitive architectures
'@
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'Core/Atoms.psm1',
        'Core/AtomSpace.psm1',
        'Core/PatternMatcher.psm1'
    )
    
    # Functions to export from this module
    FunctionsToExport = @(
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
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @(
        'OpenCog.psm1',
        'Core/Atoms.psm1',
        'Core/AtomSpace.psm1',
        'Core/PatternMatcher.psm1'
    )
    
    # List of all files packaged with this module
    FileList = @(
        'OpenCog.psm1',
        'OpenCog.psd1',
        'Core/Atoms.psm1',
        'Core/AtomSpace.psm1',
        'Core/PatternMatcher.psm1',
        'Examples/BasicUsage.ps1',
        'Examples/KnowledgeGraph.ps1',
        'Tests/OpenCog.Tests.ps1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @(
                'OpenCog',
                'CognitiveArchitecture',
                'AI',
                'Knowledge',
                'Reasoning',
                'Hypergraph',
                'PatternMatching',
                'TruthValue',
                'AGI',
                'Cognitive'
            )
            
            # A URL to the license for this module
            LicenseUri = 'https://opensource.org/licenses/MIT'
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/opencog/cogpwsh'
            
            # A URL to an icon representing this module
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0 - Initial Release

Core Features:
- Atom types (Node, Link, TruthValue)
- AtomSpace hypergraph knowledge base
- Pattern matching with variable binding
- Query system for knowledge retrieval
- Truth value probabilistic reasoning
- Full PowerShell integration

Components:
* Atoms.psm1 - Core atom types and factory functions
* AtomSpace.psm1 - Hypergraph storage and indexing
* PatternMatcher.psm1 - Query and pattern matching engine

Examples:
* BasicUsage.ps1 - Introduction to core concepts
* KnowledgeGraph.ps1 - Building semantic networks
* OpenCog.Tests.ps1 - Comprehensive test suite
'@
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
