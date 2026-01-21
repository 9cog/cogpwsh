# CogPwsh - OpenCog in PowerShell

A pure PowerShell implementation of OpenCog's core cognitive architecture for AI and knowledge representation.

## 🧠 What is This?

**CogPwsh** implements OpenCog's fundamental cognitive computing components in PowerShell, bringing advanced AI concepts to the PowerShell ecosystem:

- **Hypergraph Knowledge Representation**: Store knowledge as interconnected atoms
- **Semantic Networks**: Build complex relationships between concepts
- **Pattern Matching**: Query knowledge with variables and unification
- **Probabilistic Reasoning**: Handle uncertainty with truth values
- **Pure PowerShell**: No external dependencies, works cross-platform

## ✨ Key Features

### Core Components

1. **Atoms** - Fundamental units of knowledge
   - Nodes: Concepts, predicates, variables
   - Links: Relationships connecting atoms
   - Truth Values: Probabilistic strength and confidence

2. **AtomSpace** - Hypergraph knowledge base
   - Efficient storage and indexing
   - Quick lookups by type, name, relationships
   - Incoming/outgoing set navigation

3. **Pattern Matcher** - Query engine
   - Variable binding and unification
   - Pattern-based queries
   - Complex query construction

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
├── OpenCog.psm1          # Main module
├── OpenCog.psd1          # Module manifest
├── Core/
│   ├── Atoms.psm1        # Atom types and factory functions
│   ├── AtomSpace.psm1    # Hypergraph storage
│   └── PatternMatcher.psm1  # Query engine
├── Examples/
│   ├── QuickDemo.ps1     # Quick demonstration
│   ├── BasicUsage.ps1    # Comprehensive examples
│   └── KnowledgeGraph.ps1   # Knowledge graph building
├── Tests/
│   └── OpenCog.Tests.ps1 # Test suite
└── README.md             # Module documentation
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

Run the comprehensive test suite:

```powershell
cd OpenCog/Tests
./OpenCog.Tests.ps1
```

Expected: 58+ tests passing

Run examples:

```powershell
cd OpenCog/Examples
./QuickDemo.ps1          # Quick demonstration
./BasicUsage.ps1         # Comprehensive examples
./KnowledgeGraph.ps1     # Advanced knowledge graphs
```

## 📖 API Reference

### Atom Creation

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

### Pattern Matching

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
- **Expert Systems**: Encode domain expertise
- **Research**: Explore cognitive architecture concepts
- **Education**: Learn AI and knowledge representation

## 🔬 Technical Details

- **Language**: Pure PowerShell 5.1+
- **Dependencies**: None
- **Platforms**: Windows, Linux, macOS
- **Performance**: O(1) lookups, O(n) pattern matching
- **Architecture**: Hypergraph with multiple indexes

## 🤝 Contributing

Contributions welcome! Areas for enhancement:

1. Additional atom types and link types
2. Performance optimizations
3. Persistence backends (JSON, SQLite, etc.)
4. Probabilistic Logic Networks (PLN)
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
