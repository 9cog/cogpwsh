<#
.SYNOPSIS
    Basic usage examples for OpenCog PowerShell module
    
.DESCRIPTION
    Demonstrates fundamental concepts and operations:
    - Creating atoms (nodes and links)
    - Building an AtomSpace
    - Pattern matching and queries
    - Truth value operations
#>

# Import the OpenCog module
Import-Module (Join-Path $PSScriptRoot ".." "OpenCog.psd1") -Force

Write-Host "`n=== OpenCog PowerShell - Basic Usage Examples ===`n" -ForegroundColor Cyan

# Example 1: Creating Atoms
Write-Host "Example 1: Creating Atoms" -ForegroundColor Green
Write-Host "Creating basic atoms (nodes and links)...`n"

# Create concept nodes
$cat = New-ConceptNode "Cat"
$animal = New-ConceptNode "Animal"
$mammal = New-ConceptNode "Mammal"

Write-Host "Created nodes:"
Write-Host "  $($cat.ToString())"
Write-Host "  $($animal.ToString())"
Write-Host "  $($mammal.ToString())"

# Create inheritance links
$catIsAnimal = New-InheritanceLink -Child $cat -Parent $animal -Strength 0.95 -Confidence 0.9
$catIsMammal = New-InheritanceLink -Child $cat -Parent $mammal -Strength 0.98 -Confidence 0.95

Write-Host "`nCreated links:"
Write-Host "  $($catIsAnimal.ToString())"
Write-Host "  $($catIsMammal.ToString())"

# Example 2: Building an AtomSpace
Write-Host "`n`nExample 2: Building an AtomSpace" -ForegroundColor Green
Write-Host "Creating an AtomSpace and adding atoms...`n"

$space = New-AtomSpace

# Add atoms to the AtomSpace
$cat = Add-Atom -AtomSpace $space -Atom $cat
$animal = Add-Atom -AtomSpace $space -Atom $animal
$mammal = Add-Atom -AtomSpace $space -Atom $mammal
$catIsAnimal = Add-Atom -AtomSpace $space -Atom $catIsAnimal
$catIsMammal = Add-Atom -AtomSpace $space -Atom $catIsMammal

# Add more animals
$dog = New-ConceptNode "Dog"
$dog = Add-Atom -AtomSpace $space -Atom $dog

$dogIsAnimal = New-InheritanceLink -Child $dog -Parent $animal -Strength 0.96 -Confidence 0.92
$dogIsAnimal = Add-Atom -AtomSpace $space -Atom $dogIsAnimal

$dogIsMammal = New-InheritanceLink -Child $dog -Parent $mammal -Strength 0.97 -Confidence 0.94
$dogIsMammal = Add-Atom -AtomSpace $space -Atom $dogIsMammal

Write-Host "AtomSpace contents:"
Write-Host $space.ToString()

# Example 3: Querying the AtomSpace
Write-Host "`nExample 3: Querying the AtomSpace" -ForegroundColor Green
Write-Host "Retrieving atoms by type and relationships...`n"

# Get all concept nodes
$concepts = Get-AtomsByType -AtomSpace $space -Type ConceptNode
Write-Host "All ConceptNodes ($($concepts.Count)):"
foreach ($concept in $concepts) {
    Write-Host "  - $($concept.Name)"
}

# Get all inheritance links
$inheritances = Get-AtomsByType -AtomSpace $space -Type InheritanceLink
Write-Host "`nAll InheritanceLinks ($($inheritances.Count)):"
foreach ($link in $inheritances) {
    $child = $link.GetOutgoingAtom(0)
    $parent = $link.GetOutgoingAtom(1)
    Write-Host "  - $($child.Name) inherits from $($parent.Name) $($link.TV.ToString())"
}

# Get incoming links for a specific atom
Write-Host "`nIncoming links for 'Animal':"
$incoming = Get-IncomingSet -AtomSpace $space -Atom $animal
foreach ($link in $incoming) {
    $child = $link.GetOutgoingAtom(0)
    Write-Host "  - $($child.Name) -> Animal"
}

# Example 4: Pattern Matching
Write-Host "`n`nExample 4: Pattern Matching" -ForegroundColor Green
Write-Host "Using variables to find patterns...`n"

# Create a pattern: find all things that inherit from Animal
$varX = New-VariableNode '$x'
$pattern = New-InheritanceLink -Child $varX -Parent $animal

Write-Host "Pattern: Find all X where (InheritanceLink X Animal)"
Write-Host "Searching...`n"

$matches = Find-Pattern -AtomSpace $space -Pattern $pattern

Write-Host "Found $($matches.Count) match(es):"
foreach ($match in $matches) {
    $boundAtom = $match['$x']
    Write-Host "  - `$x = $($boundAtom.Name)"
}

# Example 5: Complex Patterns
Write-Host "`n`nExample 5: Complex Patterns with Predicates" -ForegroundColor Green
Write-Host "Creating evaluation links with predicates...`n"

# Create predicates and evaluation links
$hasLegs = New-PredicateNode "hasLegs"
$fourLegs = New-ConceptNode "4"

$catHasLegs = New-EvaluationLink -Predicate $hasLegs -Arguments @($cat, $fourLegs) -Strength 1.0 -Confidence 1.0
$catHasLegs = Add-Atom -AtomSpace $space -Atom $catHasLegs

$dogHasLegs = New-EvaluationLink -Predicate $hasLegs -Arguments @($dog, $fourLegs) -Strength 1.0 -Confidence 1.0
$dogHasLegs = Add-Atom -AtomSpace $space -Atom $dogHasLegs

Write-Host "Added evaluation links for hasLegs predicate"

# Example 6: Truth Value Operations
Write-Host "`n`nExample 6: Truth Value Operations" -ForegroundColor Green
Write-Host "Working with probabilistic truth values...`n"

# Create a node with uncertain truth value
$schrodinger = New-ConceptNode "Schrodinger" -Strength 0.5 -Confidence 0.6
$schrodinger = Add-Atom -AtomSpace $space -Atom $schrodinger

Write-Host "Created atom with uncertain truth: $($schrodinger.ToString())"

# Find atoms with high confidence
Write-Host "`nFinding atoms with confidence > 0.9:"
$highConfidence = Find-AtomsByPredicate -AtomSpace $space -Predicate {
    param($atom)
    $atom.GetTruthValue().Confidence -gt 0.9
}

foreach ($atom in $highConfidence) {
    if ($atom -is [Node]) {
        Write-Host "  - $($atom.Name): $($atom.TV.ToString())"
    }
}

# Example 7: Statistics and Export
Write-Host "`n`nExample 7: AtomSpace Statistics" -ForegroundColor Green
Write-Host "Analyzing the knowledge base...`n"

$stats = Get-AtomSpaceStatistics -AtomSpace $space

Write-Host "AtomSpace Statistics:"
Write-Host "  Total Atoms: $($stats.TotalAtoms)"
Write-Host "  Nodes: $($stats.NodeCount)"
Write-Host "  Links: $($stats.LinkCount)"
Write-Host "`n  Breakdown by type:"
foreach ($type in $stats.AtomsByType.Keys | Sort-Object) {
    Write-Host "    $type : $($stats.AtomsByType[$type])"
}

# Export to JSON
Write-Host "`nExporting AtomSpace to JSON..."
$exportPath = Join-Path $PSScriptRoot "example-export.json"
Export-AtomSpace -AtomSpace $space -Path $exportPath

# Example 8: Query Builder
Write-Host "`n`nExample 8: Using Query Builder" -ForegroundColor Green
Write-Host "Building complex queries with filters...`n"

$varAnimal = New-VariableNode '$animal'
$queryPattern = New-InheritanceLink -Child $varAnimal -Parent $mammal

Write-Host "Query: Find mammals with confidence > 0.93"

$queryResults = New-QueryBuilder -AtomSpace $space |
    ForEach-Object { $_.WithPattern($queryPattern) } |
    ForEach-Object { 
        $_.WithFilter({
            param($binding)
            $atom = $binding['$animal']
            # Find the inheritance link in incoming set
            $incoming = $space.GetIncomingSet($atom)
            foreach ($link in $incoming) {
                if ($link.Type -eq [AtomType]::InheritanceLink -and 
                    $link.GetOutgoingAtom(1).Name -eq "Mammal" -and
                    $link.GetTruthValue().Confidence -gt 0.93) {
                    return $true
                }
            }
            return $false
        })
    } |
    ForEach-Object { $_.Execute() }

Write-Host "Results:"
foreach ($result in $queryResults) {
    $boundAtom = $result['$animal']
    Write-Host "  - $($boundAtom.Name)"
}

# Summary
Write-Host "`n`n=== Summary ===" -ForegroundColor Cyan
Write-Host "This example demonstrated:"
Write-Host "  ✓ Creating atoms (nodes and links)"
Write-Host "  ✓ Building an AtomSpace knowledge base"
Write-Host "  ✓ Querying by type and relationships"
Write-Host "  ✓ Pattern matching with variables"
Write-Host "  ✓ Working with truth values"
Write-Host "  ✓ Complex queries and filters"
Write-Host "  ✓ Statistics and data export"
Write-Host "`nOpenCog PowerShell is ready for cognitive computing!`n"
