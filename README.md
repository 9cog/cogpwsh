# CogPwsh - OpenCog in PowerShell

[![CI](https://github.com/9cog/cogpwsh/actions/workflows/opencog-ci.yml/badge.svg)](https://github.com/9cog/cogpwsh/actions/workflows/opencog-ci.yml)

A pure PowerShell implementation of OpenCog's core cognitive architecture for AI and knowledge representation.

## 🧠 What is This?

**CogPwsh** implements OpenCog's fundamental cognitive computing components in PowerShell, bringing advanced AI concepts to the PowerShell ecosystem:

- **Hypergraph Knowledge Representation**: Store knowledge as interconnected atoms
- **Semantic Networks**: Build complex relationships between concepts  
- **Pattern Matching**: Query knowledge with variables and unification
- **Probabilistic Reasoning**: Handle uncertainty with truth values
- **Extended Type System**: TypeNode, TypedAtomLink, ArrowLink, TypeChoice, TypeIntersection
- **Domain-Specific Atoms**: GitHub, Azure, Exchange, and custom exotic atom types
- **PLN Inference**: Probabilistic Logic Network deduction, modus ponens, and more
- **Pure PowerShell**: No external dependencies, works cross-platform

## 📊 Implementation Status

| Phase | Description | Status | Tests |
|-------|-------------|--------|-------|
| 1 | Core Atoms, AtomSpace, Pattern Matcher | ✅ Complete | 68 / 68 |
| 2 | Extended Atom Types, Type System, Value Atoms | ✅ Complete | 19 / 19 |
| 3 | Advanced Pattern Matching (GetLink, BindLink, etc.) | ✅ Complete | 35 / 35 |
| 3.5 | Exotic Atoms + Universal Kernel Generator | ✅ Complete | 58 / 58 |
| 4 | PLN Infrastructure (TruthValues, Deduction) | 🚧 In Progress | 99 / 99 |
| 5–15 | PLN Advanced, URE, ECAN, Perception, Language, Learning | ⏳ Planned | — |

**Overall progress**: ~30% of full OpenCog architecture · **279 tests across 5 suites, 100% pass rate**

## ✨ Key Features

### Core Components (Phases 1–3)

1. **Atoms** — Fundamental units of knowledge
   - Nodes: ConceptNode, PredicateNode, VariableNode, NumberNode, StringNode, TypeNode, …
   - Links: InheritanceLink, SimilarityLink, EvaluationLink, ContextLink, MemberLink, SubsetLink, EquivalenceLink, ImplicationScopeLink, SequentialAndLink, PresentLink, GetLink, BindLink, SatisfactionLink, DualLink, ChoiceLink, AbsentLink, …
   - Truth Values: Probabilistic strength and confidence

2. **AtomSpace** — Hypergraph knowledge base
   - Efficient storage and indexing (O(1) lookups by handle, type, name)
   - Incoming/outgoing set navigation
   - Duplicate detection with truth-value merging

3. **Pattern Matcher** — Query engine
   - Variable binding and unification
   - Pattern-based queries with QueryBuilder DSL
   - Advanced patterns: value extraction, rewriting, negation, alternation

### Extended Components (Phase 3.5)

4. **Exotic Atoms** — Domain-specific hierarchical atoms
   - GitHub: GitHubRepoAtom, GitHubOrgAtom, GitHubEnterpriseAtom
   - Azure: AzureEntraTenantAtom, AzureSubscriptionAtom
   - Exchange/M365: ExchangeMailboxAtom, ExchangeCalendarAtom
   - OpenCog Meta: OpenCogAtomSpaceAtom
   - Extensible registry for custom domain types

5. **Universal Kernel Generator** — Differential calculus kernels
   - B-Series expansion for domain-specific kernels
   - Elementary differentials, Runge-Kutta, cognitive kernels

### PLN (Phase 4 — In Progress)

6. **Probabilistic Logic Networks** — Uncertain inference
   - SimpleTruthValue, CountTruthValue, IndefiniteTruthValue, FuzzyTruthValue
   - Deduction rule (A→B, B→C ⊢ A→C with TV propagation)
   - Modus ponens, modus tollens, contraposition, hypothetical syllogism

## 🚀 Quick Start

```powershell
# Import the module
Import-Module ./OpenCog/OpenCog.psd1

# Create a knowledge base
$kb = New-AtomSpace

# Create concepts
$cat = New-ConceptNode "Cat"
$animal = New-ConceptNode "Animal"

# Add to knowledge base
$cat = $kb.AddAtom($cat)
$animal = $kb.AddAtom($animal)

# Create relationship
$inheritance = New-InheritanceLink -Child $cat -Parent $animal
$kb.AddAtom($inheritance)

# Query
$concepts = $kb.GetAtomsByType('ConceptNode')
foreach ($concept in $concepts) {
    Write-Host $concept.Name
}
```

## 📚 Documentation

### Module Structure

```
OpenCog/
├── OpenCog.psm1              # Main module (v2.0.0)
├── OpenCog.psd1              # Module manifest (76+ exported functions)
├── Core/
│   ├── Atoms.psm1            # Atom types + Phase 2 extended types
│   ├── AtomSpace.psm1        # Hypergraph storage
│   ├── PatternMatcher.psm1   # Query engine
│   ├── AdvancedPatternMatcher.psm1  # Phase 3 advanced patterns
│   └── ExoticAtoms.psm1      # Phase 3.5 domain-specific atoms
├── PLN/
│   ├── TruthValues.psm1      # Phase 4 extended truth values
│   └── DeductionRules.psm1   # Phase 4 PLN inference rules
├── KernelGenerator/
│   ├── UniversalKernelGenerator.psm1
│   ├── BSeriesExpansion.psm1
│   └── ElementaryDifferentials.psm1
├── Examples/
│   ├── QuickDemo.ps1         # Quick demonstration
│   ├── BasicUsage.ps1        # Comprehensive examples
│   ├── KnowledgeGraph.ps1    # Knowledge graph building
│   ├── Phase2Demo.ps1        # Extended atom types
│   ├── Phase2ExtendedDemo.ps1
│   ├── Phase3Demo.ps1        # Advanced pattern matching
│   ├── ExoticAtomsDemo.ps1   # Domain-specific atoms
│   └── UniversalKernelDemo.ps1
├── Tests/
│   ├── OpenCog.Tests.ps1          # Phase 1 — 68 tests
│   ├── Phase2Extended.Tests.ps1   # Phase 2 — 19 tests
│   ├── Phase3.Tests.ps1           # Phase 3 — 35 tests
│   └── UniversalKernelGenerator.Tests.ps1  # Phase 3.5 — 58 tests
└── README.md                 # Module documentation
```

### Examples

#### Building a Taxonomy

```powershell
$kb = New-AtomSpace

# Create hierarchy
$mammal = New-ConceptNode "Mammal" | ForEach-Object { $kb.AddAtom($_) }
$dog = New-ConceptNode "Dog" | ForEach-Object { $kb.AddAtom($_) }

# Link them
$link = New-InheritanceLink -Child $dog -Parent $mammal
$kb.AddAtom($link)

# Query incoming relationships
$incoming = $kb.GetIncomingSet($mammal)
foreach ($link in $incoming) {
    $child = $link.GetOutgoingAtom(0)
    Write-Host "$($child.Name) is a Mammal"
}
```

#### Properties with Predicates

```powershell
$kb = New-AtomSpace

# Create predicate and concepts
$hasColor = New-PredicateNode "hasColor" | ForEach-Object { $kb.AddAtom($_) }
$apple = New-ConceptNode "Apple" | ForEach-Object { $kb.AddAtom($_) }
$red = New-ConceptNode "Red" | ForEach-Object { $kb.AddAtom($_) }

# Assert property
$eval = New-EvaluationLink -Predicate $hasColor -Arguments @($apple, $red)
$kb.AddAtom($eval)
```

#### Truth Values

```powershell
# Uncertain knowledge
$maybe = New-ConceptNode "Maybe" -Strength 0.5 -Confidence 0.6

# Certain knowledge
$certain = New-ConceptNode "Certain" -Strength 0.99 -Confidence 0.98

# Query by confidence
$allAtoms = $kb.GetAllAtoms()
$highConf = $allAtoms | Where-Object {
    $_.GetTruthValue().Confidence -gt 0.9
}
```

## 🧪 Testing

Run all test suites (279 tests, 100% pass rate):

```powershell
cd OpenCog/Tests
./OpenCog.Tests.ps1              # Phase 1 — 68 tests
./Phase2Extended.Tests.ps1       # Phase 2 — 19 tests
./Phase3.Tests.ps1               # Phase 3 — 35 tests
./UniversalKernelGenerator.Tests.ps1  # Phase 3.5 — 58 tests
./Phase4PLN.Tests.ps1                 # Phase 4   — 99 tests
```

Or via CI (GitHub Actions runs all suites automatically on every push/PR).

Run examples:

```powershell
cd OpenCog/Examples
./QuickDemo.ps1              # Quick demonstration
./BasicUsage.ps1             # Comprehensive examples
./KnowledgeGraph.ps1         # Advanced knowledge graphs
./Phase2Demo.ps1             # Extended atom types
./Phase3Demo.ps1             # Advanced pattern matching
./ExoticAtomsDemo.ps1        # Domain-specific atoms
./UniversalKernelDemo.ps1    # Kernel generator
```

## 📖 API Reference

### Atom Creation (Phase 1)

| Function | Description |
|----------|-------------|
| `New-ConceptNode` | Create a concept node |
| `New-PredicateNode` | Create a predicate node |
| `New-VariableNode` | Create a variable for pattern matching |
| `New-InheritanceLink` | Create inheritance relationship |
| `New-SimilarityLink` | Create similarity relationship |
| `New-EvaluationLink` | Create predicate evaluation |
| `New-AndLink`, `New-OrLink` | Create logical relationships |
| `New-ImplicationLink` | Create implication |

### Extended Atoms (Phase 2)

| Function | Description |
|----------|-------------|
| `New-ContextLink` | Context-dependent relationship |
| `New-MemberLink` | Set membership (element ∈ set) |
| `New-SubsetLink` | Set subset (A ⊆ B) |
| `New-EquivalenceLink` | Bidirectional equivalence |
| `New-ImplicationScopeLink` | Scoped implication (∀x P(x)→Q(x)) |
| `New-NumberNode`, `New-StringNode` | Numeric/string value atoms |
| `New-FloatValue`, `New-LinkValue` | Typed value atoms |
| `New-TypeNode`, `New-TypedAtomLink` | Type system |
| `New-TypeChoice`, `New-TypeIntersection` | Union/intersection types |
| `Get-AtomValue`, `Get-TruthValueOf` | Value extraction |

### Advanced Pattern Matching (Phase 3)

| Function | Description |
|----------|-------------|
| `New-GetLink` | Extract values from pattern matches |
| `New-BindLink` | Pattern rewriting/transformation |
| `New-SatisfactionLink` | Boolean satisfaction query |
| `New-DualLink` | Bidirectional pattern query |
| `New-ChoiceLink` | Alternative patterns |
| `New-AbsentLink` | Negation-as-failure |
| `Invoke-AdvancedPattern` | Execute advanced pattern links |

### Exotic Atoms (Phase 3.5)

| Function | Description |
|----------|-------------|
| `New-ExoticNode` | URI-addressable atom |
| `New-GitHubOrgAtom` | GitHub org as AtomSpace of repos |
| `New-GitHubEnterpriseAtom` | Enterprise hierarchy |
| `New-AzureEntraTenantAtom` | Azure/Entra tenant |
| `New-ExchangeMailboxAtom` | Exchange mailbox atom |
| `Register-ExoticAtomType` | Register custom atom types |

### PLN Inference (Phase 4)

| Function | Description |
|----------|-------------|
| `New-SimpleTruthValue` | Simple (strength, confidence) TV |
| `New-CountTruthValue` | Count-based truth value |
| `New-IndefiniteTruthValue` | Interval truth value (L, U) |
| `New-FuzzyTruthValue` | Fuzzy logic truth value |
| `Invoke-PLNDeduction` | Deduction: A→B, B→C ⊢ A→C |
| `Invoke-ModusPonens` | Modus ponens: A→B, A ⊢ B |
| `Invoke-ModusTollens` | Modus tollens: A→B, ¬B ⊢ ¬A |
| `Invoke-PLNContraposition` | Contraposition: A→B ⊢ ¬B→¬A |

### AtomSpace Operations

| Function | Description |
|----------|-------------|
| `New-AtomSpace` | Create new knowledge base |
| `Add-Atom` | Add atom to AtomSpace |
| `Get-Atom` | Get atom by handle |
| `Get-AtomsByType` | Get all atoms of type |
| `Get-Node` | Get node by type and name |
| `Get-IncomingSet` | Get incoming links |
| `Remove-Atom` | Remove atom |
| `Clear-AtomSpace` | Clear all atoms |
| `Get-AtomSpaceStatistics` | Get statistics |
| `Export-AtomSpace` | Export to JSON |

### Pattern Matching (Phase 1)

| Function | Description |
|----------|-------------|
| `Find-Pattern` | Find pattern matches |
| `Find-AtomsByPredicate` | Find with predicate |
| `Invoke-Query` | Execute query |
| `New-QueryBuilder` | Create query builder |

## 🎯 Use Cases

- **Knowledge Representation**: Build semantic networks and ontologies
- **AI Systems**: Create intelligent reasoning systems
- **Natural Language Processing**: Represent linguistic knowledge
- **Expert Systems**: Encode domain expertise with PLN inference
- **Cloud Governance**: Represent GitHub, Azure, Exchange resource hierarchies
- **Research**: Explore cognitive architecture concepts
- **Education**: Learn AI and knowledge representation

## 🔬 Technical Details

- **Language**: Pure PowerShell 5.1+
- **Module Version**: 2.0.0
- **Dependencies**: None
- **Platforms**: Windows, Linux, macOS
- **Performance**: O(1) lookups, O(n) pattern matching
- **Architecture**: Hypergraph with multiple indexes
- **Exported Functions**: 89
- **Tests**: 180 (100% pass rate)

## 🤝 Contributing

Contributions welcome! Current focus areas:

1. PLN Phase 4 — InductionAbduction.psm1 (induction, abduction rules)
2. PLN Phase 5 — Higher-order inference, fuzzy logic, temporal reasoning
3. Persistence backends (JSON, SQLite, etc.)
4. Performance optimizations for large AtomSpaces
5. More examples and documentation

## 📄 License

MIT License - See LICENSE file

## 🔗 Related Projects

- **OpenCog**: https://opencog.org - The original C++ implementation
- **OpenCog Hyperon**: https://github.com/trueagi-io/hyperon-experimental
- **cogutil, atomspace, ure, pln**: Core OpenCog C++ components

## 🙏 Acknowledgments

- OpenCog Foundation for the cognitive architecture design
- PowerShell team for the excellent platform
- Community contributors

## 📧 Contact

- **Issues**: https://github.com/opencog/cogpwsh/issues
- **Discussions**: OpenCog mailing list

---

**Bringing cognitive computing to PowerShell 🧠⚡**

## What's Next?

The `OpenCog/` directory contains a complete, functional implementation of OpenCog in PowerShell. This coexists with the existing PowerShellForGitHub code in the repository.

### Project Structure

```
cogpwsh/
├── OpenCog/                    # ← New OpenCog implementation
│   ├── OpenCog.psm1
│   ├── OpenCog.psd1
│   ├── Core/
│   ├── Examples/
│   ├── Tests/
│   └── README.md
├── PowerShellForGitHub.psm1   # Existing GitHub module
├── PowerShellForGitHub.psd1
├── GitHub*.ps1                 # Existing GitHub functions
└── README.md                   # This file
```

Both modules can coexist and be used independently.
