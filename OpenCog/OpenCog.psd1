@{
    # Script module or binary module file associated with this manifest
    RootModule = 'OpenCog.psm1'
    
    # Version number of this module
    ModuleVersion = '1.2.0'
    
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

Phase 1 - Core Foundation:
- Atoms: Nodes and Links forming a hypergraph structure
- AtomSpace: Hypergraph-based knowledge representation system
- Pattern Matching: Query and unification engine for knowledge retrieval
- Truth Values: Probabilistic truth value system with Bayesian updating

Phase 2 - Extended Atom Types:
- Advanced Links: ContextLink, MemberLink, SubsetLink, ImplicationScopeLink, etc.
- Type System: TypeNode, TypedAtomLink, SignatureLink, ArrowLink, TypeChoice, TypeIntersection
- Value Atoms: NumberNode, StringNode, FloatValue with value operations

Phase 3 - Advanced Pattern Matching:
- GetLink: Extract values from pattern matches
- BindLink: Pattern rewriting and transformation
- SatisfactionLink: Boolean satisfaction queries
- DualLink: Bidirectional pattern queries
- ChoiceLink: Alternative pattern matching
- SequentialOrLink: Ordered disjunction patterns
- AbsentLink: Negation-as-failure queries

Features:
* Create and manage cognitive atoms (nodes and links)
* Store knowledge in a hypergraph AtomSpace
* Query patterns with variable binding
* Represent uncertain knowledge with truth values
* Advanced set theory and contextual relationships
* Complete type system with type checking and inference
* Numeric and string value atoms with operations
* Build intelligent systems using cognitive architecture principles

Perfect for:
- AI and cognitive systems research
- Knowledge representation and reasoning
- Semantic networks and ontologies
- Pattern-based inference systems
- Type-safe cognitive architectures
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
        # Phase 1 - Atom creation functions
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
        'Invoke-PatternInstantiation'
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
Version 1.2.0 - Phase 3: Advanced Pattern Matching (Integrated)

New Features:
- Advanced Pattern Matching (integrated into Atoms.psm1 and PatternMatcher.psm1)
  * GetLink for extracting values from pattern matches
  * BindLink for pattern rewriting and transformation
  * SatisfactionLink for boolean satisfaction queries
  * DualLink for bidirectional pattern queries
  * ChoiceLink for alternative pattern matching
  * SequentialOrLink for ordered disjunction patterns
  * AbsentLink for negation-as-failure queries
  * AdvancedPatternMatcher execution engine

Improvements:
* Module now exports 59 functions (up from 50)
* Sophisticated query capabilities
* Pattern rewriting and transformation
* Support for negation and alternatives
* Backward compatible with Phase 1 and Phase 2 code
* Fixed PowerShell class instantiation issues by integrating classes

Components:
* Phase 1: Atoms.psm1, AtomSpace.psm1, PatternMatcher.psm1
* Phase 2: Extended types in Atoms.psm1
* Phase 3: Advanced pattern links in Atoms.psm1, execution engine in PatternMatcher.psm1

Version 1.1.0 - Phase 2: Extended Atom Types

New Features:
- Advanced Link Types (AdvancedLinks.psm1)
  * ContextLink for contextual relationships
  * MemberLink and SubsetLink for set theory
  * ImplicationScopeLink for scoped implications
  * EquivalenceLink for bidirectional equivalence
  * SequentialAndLink for ordered conjunctions
  * PresentLink for temporal presence

- Type System (TypeSystem.psm1)
  * TypeNode for type definitions
  * TypedAtomLink for type annotations
  * SignatureLink for function signatures
  * ArrowLink for function type arrows
  * TypeChoice for union types
  * TypeIntersection for intersection types
  * Type validation and inference helpers

- Value Atoms (ValueAtoms.psm1)
  * NumberNode for numeric constants
  * StringNode for string values
  * FloatValue for precise floating-point numbers
  * LinkValue for link values
  * TruthValueOfLink, StrengthOfLink, ConfidenceOfLink extractors
  * Arithmetic operations on NumberNodes

Improvements:
* Module now exports 75 functions (up from 26)
* Enhanced type safety and value handling
* Extended cognitive architecture capabilities
* Backward compatible with Phase 1 code

Components:
* Phase 1: Atoms.psm1, AtomSpace.psm1, PatternMatcher.psm1
* Phase 2: AdvancedLinks.psm1, TypeSystem.psm1, ValueAtoms.psm1

Version 1.0.0 - Initial Release

Core Features:
- Atom types (Node, Link, TruthValue)
- AtomSpace hypergraph knowledge base
- Pattern matching with variable binding
- Query system for knowledge retrieval
- Truth value probabilistic reasoning
- Full PowerShell integration
'@
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
