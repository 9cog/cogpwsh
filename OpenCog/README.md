# OpenCog PowerShell

A pure PowerShell implementation of OpenCog's core cognitive architecture components.

## 🧠 Overview

OpenCog PowerShell brings cognitive computing to the PowerShell ecosystem. It implements the fundamental building blocks of the OpenCog framework for artificial general intelligence (AGI), enabling you to build intelligent systems using PowerShell's powerful scripting capabilities.

## ✨ Features

- **Hypergraph Knowledge Representation**: Store and query knowledge using OpenCog's AtomSpace hypergraph
- **Cognitive Atoms**: Create nodes and links forming complex semantic networks
- **Pattern Matching**: Query knowledge with variable binding and unification
- **Probabilistic Reasoning**: Truth values with Bayesian updating for uncertain knowledge
- **Pure PowerShell**: No external dependencies, works on Windows, Linux, and macOS
- **Well-Documented**: Comprehensive examples and test suite

## 🏗️ Architecture

### Core Components

#### 1. **Atoms** (`Atoms.psm1`)
The fundamental units of knowledge:
- **Nodes**: Named entities (ConceptNode, PredicateNode, VariableNode)
- **Links**: Relationships between atoms (InheritanceLink, EvaluationLink, etc.)
- **TruthValues**: Probabilistic truth with strength and confidence

#### 2. **AtomSpace** (`AtomSpace.psm1`)
The hypergraph knowledge base:
- Efficient storage and indexing
- Quick lookups by type, name, and relationships
- Incoming/outgoing set navigation
- Statistics and export capabilities

#### 3. **Pattern Matcher** (`PatternMatcher.psm1`)
Query and inference engine:
- Variable binding and unification
- Pattern-based queries
- Predicate filtering
- Complex query construction

## 📦 Installation

### Option 1: Direct Import
```powershell
# Clone or download this repository
cd OpenCog
Import-Module ./OpenCog.psd1
```

### Option 2: PowerShell Gallery (Coming Soon)
```powershell
Install-Module -Name OpenCog
Import-Module OpenCog
```

## 🚀 Quick Start

### Basic Example

```powershell
# Import the module
Import-Module ./OpenCog/OpenCog.psd1

# Create an AtomSpace (knowledge base)
$space = New-AtomSpace

# Create some concepts
$cat = New-ConceptNode "Cat"
$animal = New-ConceptNode "Animal"

# Add them to the AtomSpace
$cat = Add-Atom -AtomSpace $space -Atom $cat
$animal = Add-Atom -AtomSpace $space -Atom $animal

# Create a relationship
$inheritance = New-InheritanceLink -Child $cat -Parent $animal
$inheritance = Add-Atom -AtomSpace $space -Atom $inheritance

# Query: Find all things that inherit from Animal
$variable = New-VariableNode '$x'
$pattern = New-InheritanceLink -Child $variable -Parent $animal
$results = Find-Pattern -AtomSpace $space -Pattern $pattern

# Display results
foreach ($match in $results) {
    Write-Host "Found: $($match['$x'].Name)"
}
```

## 📚 Core Concepts

### Atoms

Atoms are the basic units of knowledge. There are two main types:

#### Nodes
Named entities representing concepts, predicates, or variables:

```powershell
# Concept: A thing or idea
$dog = New-ConceptNode "Dog"

# Predicate: A property or relation
$hasLegs = New-PredicateNode "hasLegs"

# Variable: For pattern matching
$x = New-VariableNode '$x'
```

#### Links
Relationships connecting atoms:

```powershell
# Inheritance: X is a type of Y
$link1 = New-InheritanceLink -Child $dog -Parent $animal

# Similarity: X is similar to Y
$link2 = New-SimilarityLink -Atom1 $cat -Atom2 $dog

# Evaluation: Predicate applied to arguments
$link3 = New-EvaluationLink -Predicate $hasLegs -Arguments @($dog, $fourLegs)

# Logical: AND, OR, Implication
$link4 = New-AndLink -Atoms @($a, $b, $c)
$link5 = New-ImplicationLink -Antecedent $a -Consequent $b
```

### Truth Values

Every atom has a probabilistic truth value with two components:

- **Strength**: Degree of truth (0.0 to 1.0)
- **Confidence**: Certainty of the strength value (0.0 to 1.0)

```powershell
# Create atom with truth value
$uncertain = New-ConceptNode "Schrodinger" -Strength 0.5 -Confidence 0.6

# Truth values merge when duplicate atoms are added
$atom1 = New-ConceptNode "Test" -Strength 0.8 -Confidence 0.7
$atom2 = New-ConceptNode "Test" -Strength 0.9 -Confidence 0.6

Add-Atom -AtomSpace $space -Atom $atom1
Add-Atom -AtomSpace $space -Atom $atom2  # Merges with atom1
```

### AtomSpace

The AtomSpace is the hypergraph container for all atoms:

```powershell
# Create an AtomSpace
$space = New-AtomSpace

# Add atoms
$atom = Add-Atom -AtomSpace $space -Atom $myAtom

# Query by type
$concepts = Get-AtomsByType -AtomSpace $space -Type ConceptNode

# Query by name
$node = Get-Node -AtomSpace $space -Type ConceptNode -Name "Cat"

# Get relationships
$incoming = Get-IncomingSet -AtomSpace $space -Atom $node

# Statistics
$stats = Get-AtomSpaceStatistics -AtomSpace $space

# Export
Export-AtomSpace -AtomSpace $space -Path "knowledge.json"
```

### Pattern Matching

Find atoms matching patterns with variables:

```powershell
# Pattern: Find all X where (InheritanceLink X Animal)
$var = New-VariableNode '$x'
$pattern = New-InheritanceLink -Child $var -Parent $animal

$matches = Find-Pattern -AtomSpace $space -Pattern $pattern

# Each match is a hashtable of variable bindings
foreach ($match in $matches) {
    $boundAtom = $match['$x']
    Write-Host "Found: $($boundAtom.Name)"
}

# Predicate-based queries
$highConfidence = Find-AtomsByPredicate -AtomSpace $space -Predicate {
    param($atom)
    $atom.GetTruthValue().Confidence -gt 0.9
}
```

## 📖 Examples

### Example 1: Simple Taxonomy

```powershell
Import-Module ./OpenCog/OpenCog.psd1

$kb = New-AtomSpace

# Build a simple animal taxonomy
$animal = New-ConceptNode "Animal" | Add-Atom -AtomSpace $kb
$mammal = New-ConceptNode "Mammal" | Add-Atom -AtomSpace $kb
$dog = New-ConceptNode "Dog" | Add-Atom -AtomSpace $kb

# Create hierarchy
New-InheritanceLink -Child $mammal -Parent $animal | Add-Atom -AtomSpace $kb
New-InheritanceLink -Child $dog -Parent $mammal | Add-Atom -AtomSpace $kb

# Query: What inherits from Mammal?
$var = New-VariableNode '$x'
$pattern = New-InheritanceLink -Child $var -Parent $mammal
$results = Find-Pattern -AtomSpace $kb -Pattern $pattern

$results | ForEach-Object { Write-Host $_.['$x'].Name }
```

### Example 2: Properties and Relations

```powershell
# Create predicates
$hasColor = New-PredicateNode "hasColor" | Add-Atom -AtomSpace $kb

# Create instances
$apple = New-ConceptNode "Apple" | Add-Atom -AtomSpace $kb
$red = New-ConceptNode "Red" | Add-Atom -AtomSpace $kb

# Assert property
$eval = New-EvaluationLink -Predicate $hasColor -Arguments @($apple, $red)
$eval = Add-Atom -AtomSpace $kb -Atom $eval

# Query: What color is the apple?
$varColor = New-VariableNode '$color'
$pattern = New-EvaluationLink -Predicate $hasColor -Arguments @($apple, $varColor)
$results = Find-Pattern -AtomSpace $kb -Pattern $pattern

$results | ForEach-Object { Write-Host "Apple is $($_.['$color'].Name)" }
```

## 🔧 API Reference

### Atom Creation Functions

| Function | Description | Example |
|----------|-------------|---------|
| `New-ConceptNode` | Create a concept node | `New-ConceptNode "Cat"` |
| `New-PredicateNode` | Create a predicate node | `New-PredicateNode "hasLegs"` |
| `New-VariableNode` | Create a variable node | `New-VariableNode '$x'` |
| `New-InheritanceLink` | Create inheritance relationship | `New-InheritanceLink -Child $a -Parent $b` |
| `New-SimilarityLink` | Create similarity relationship | `New-SimilarityLink -Atom1 $a -Atom2 $b` |
| `New-EvaluationLink` | Create predicate evaluation | `New-EvaluationLink -Predicate $p -Arguments @($a, $b)` |
| `New-ImplicationLink` | Create logical implication | `New-ImplicationLink -Antecedent $a -Consequent $b` |
| `New-AndLink` | Create logical AND | `New-AndLink -Atoms @($a, $b, $c)` |
| `New-OrLink` | Create logical OR | `New-OrLink -Atoms @($a, $b)` |

### AtomSpace Functions

| Function | Description | Example |
|----------|-------------|---------|
| `New-AtomSpace` | Create a new AtomSpace | `$space = New-AtomSpace` |
| `Add-Atom` | Add atom to AtomSpace | `Add-Atom -AtomSpace $space -Atom $atom` |
| `Get-Atom` | Get atom by handle | `Get-Atom -AtomSpace $space -Handle $guid` |
| `Get-AtomsByType` | Get all atoms of type | `Get-AtomsByType -AtomSpace $space -Type ConceptNode` |
| `Get-Node` | Get node by type and name | `Get-Node -AtomSpace $space -Type ConceptNode -Name "Cat"` |
| `Get-IncomingSet` | Get incoming links | `Get-IncomingSet -AtomSpace $space -Atom $atom` |
| `Remove-Atom` | Remove atom | `Remove-Atom -AtomSpace $space -Atom $atom` |
| `Clear-AtomSpace` | Clear all atoms | `Clear-AtomSpace -AtomSpace $space` |
| `Get-AtomSpaceStatistics` | Get statistics | `Get-AtomSpaceStatistics -AtomSpace $space` |
| `Export-AtomSpace` | Export to JSON | `Export-AtomSpace -AtomSpace $space -Path "out.json"` |

### Pattern Matching Functions

| Function | Description | Example |
|----------|-------------|---------|
| `Find-Pattern` | Find pattern matches | `Find-Pattern -AtomSpace $space -Pattern $pattern` |
| `Find-AtomsByPredicate` | Find with predicate | `Find-AtomsByPredicate -AtomSpace $space -Predicate $pred` |
| `Invoke-Query` | Execute query | `Invoke-Query -AtomSpace $space -Pattern $pattern` |
| `New-QueryBuilder` | Create query builder | `New-QueryBuilder -AtomSpace $space` |

## 🧪 Testing

Run the comprehensive test suite:

```powershell
cd OpenCog/Tests
./OpenCog.Tests.ps1
```

Expected output:
```
=== OpenCog PowerShell - Test Suite ===

=== Atom Creation Tests ===
  ✓ Create ConceptNode
  ✓ Node has correct type
  ✓ Node has correct name
  ...

=== Test Summary ===
Total Tests: 65
Passed: 65
Failed: 0

✓ All tests passed!
```

## 📝 Examples

Explore the examples directory:

- **`BasicUsage.ps1`**: Introduction to core concepts and operations
- **`KnowledgeGraph.ps1`**: Building semantic knowledge graphs
- **`OpenCog.Tests.ps1`**: Comprehensive test suite

Run examples:
```powershell
cd OpenCog/Examples
./BasicUsage.ps1
./KnowledgeGraph.ps1
```

## 🎯 Use Cases

### Knowledge Representation
Build semantic networks and ontologies:
- Taxonomies and hierarchies
- Properties and relationships
- Complex semantic structures

### Reasoning Systems
Implement inference and reasoning:
- Pattern-based queries
- Logical relationships
- Probabilistic reasoning

### AI Applications
Create intelligent systems:
- Knowledge bases
- Expert systems
- Cognitive architectures

### Education
Learn cognitive architecture concepts:
- Hypergraph data structures
- Pattern matching algorithms
- Probabilistic reasoning

## 🔬 Technical Details

### Implementation

- **Language**: Pure PowerShell 5.1+
- **Dependencies**: None (standalone)
- **Classes**: Custom PowerShell classes for atoms and AtomSpace
- **Data Structures**: Hashtables and generic lists for efficient indexing

### Performance

- O(1) atom lookup by handle
- O(1) node lookup by type and name
- O(n) pattern matching (where n = atoms of matching type)
- Memory-efficient indexing with multiple indexes

### Compatibility

- **PowerShell 5.1+**: Full compatibility
- **PowerShell Core 6+**: Full compatibility
- **Platforms**: Windows, Linux, macOS

## 🤝 Contributing

Contributions welcome! Areas for enhancement:

1. **Additional Atom Types**: Implement more link types from OpenCog
2. **Performance**: Optimize pattern matching algorithms
3. **Persistence**: Database backends for large knowledge bases
4. **Reasoning**: PLN (Probabilistic Logic Networks) implementation
5. **Documentation**: More examples and tutorials

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Related Projects

- **OpenCog**: https://opencog.org - The original C++ implementation
- **OpenCog Hyperon**: https://github.com/trueagi-io/hyperon-experimental - Next-generation OpenCog
- **atomspace-rocks**: Persistent storage for AtomSpace

## 📚 References

### OpenCog Documentation
- [OpenCog Wiki](https://wiki.opencog.org)
- [AtomSpace Documentation](https://wiki.opencog.org/w/AtomSpace)
- [Pattern Matcher](https://wiki.opencog.org/w/Pattern_matcher)

### Academic Papers
- "OpenCog: A Software Framework for Integrative Artificial General Intelligence"
- "Probabilistic Logic Networks: A Comprehensive Framework for Uncertain Inference"
- "The CogPrime Architecture for Artificial General Intelligence"

## 🙏 Acknowledgments

- OpenCog Foundation for the cognitive architecture design
- PowerShell team for the excellent scripting platform
- Community contributors

## 📧 Contact

For questions, issues, or contributions:
- GitHub Issues: https://github.com/opencog/cogpwsh/issues
- OpenCog Mailing List: opencog@googlegroups.com

---

**Built with ❤️ for cognitive computing in PowerShell**
