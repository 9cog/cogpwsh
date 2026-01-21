<#
.SYNOPSIS
    Knowledge Graph example using OpenCog PowerShell
    
.DESCRIPTION
    Demonstrates building a semantic knowledge graph with:
    - Multiple inheritance hierarchies
    - Relationships and properties
    - Logical inference patterns
    - Complex queries
#>

Import-Module (Join-Path $PSScriptRoot ".." "OpenCog.psd1") -Force

Write-Host "`n=== OpenCog Knowledge Graph Example ===`n" -ForegroundColor Cyan

# Create the AtomSpace
$kb = New-AtomSpace
Write-Host "Created knowledge base (AtomSpace)`n"

# Build a knowledge graph about programming languages
Write-Host "Building knowledge graph about programming languages...`n" -ForegroundColor Green

# 1. Define the ontology (class hierarchy)
Write-Host "1. Creating ontology..."

# Top-level concepts
$thing = New-ConceptNode "Thing"
$thing = Add-Atom -AtomSpace $kb -Atom $thing

$language = New-ConceptNode "ProgrammingLanguage"
$language = Add-Atom -AtomSpace $kb -Atom $language

$paradigm = New-ConceptNode "Paradigm"
$paradigm = Add-Atom -AtomSpace $kb -Atom $paradigm

# Language hierarchy
Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $language -Parent $thing -Strength 1.0 -Confidence 1.0) | Out-Null

# Paradigms
$oop = New-ConceptNode "ObjectOriented"
$oop = Add-Atom -AtomSpace $kb -Atom $oop
Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $oop -Parent $paradigm) | Out-Null

$functional = New-ConceptNode "Functional"
$functional = Add-Atom -AtomSpace $kb -Atom $functional
Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $functional -Parent $paradigm) | Out-Null

$scripting = New-ConceptNode "Scripting"
$scripting = Add-Atom -AtomSpace $kb -Atom $scripting
Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $scripting -Parent $paradigm) | Out-Null

$imperative = New-ConceptNode "Imperative"
$imperative = Add-Atom -AtomSpace $kb -Atom $imperative
Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $imperative -Parent $paradigm) | Out-Null

Write-Host "  Created ontology with concepts and paradigms"

# 2. Add specific programming languages
Write-Host "`n2. Adding programming languages..."

$languages = @{
    "PowerShell" = @{ Paradigms = @($oop, $scripting, $imperative, $functional); Year = 2006 }
    "Python"     = @{ Paradigms = @($oop, $scripting, $imperative, $functional); Year = 1991 }
    "Java"       = @{ Paradigms = @($oop, $imperative); Year = 1995 }
    "JavaScript" = @{ Paradigms = @($oop, $functional, $imperative, $scripting); Year = 1995 }
    "Haskell"    = @{ Paradigms = @($functional); Year = 1990 }
    "C#"         = @{ Paradigms = @($oop, $imperative, $functional); Year = 2000 }
    "Lisp"       = @{ Paradigms = @($functional); Year = 1958 }
}

$langNodes = @{}

foreach ($langName in $languages.Keys) {
    $langNode = New-ConceptNode $langName
    $langNode = Add-Atom -AtomSpace $kb -Atom $langNode
    $langNodes[$langName] = $langNode
    
    # Language is a ProgrammingLanguage
    Add-Atom -AtomSpace $kb -Atom (New-InheritanceLink -Child $langNode -Parent $language -Strength 1.0 -Confidence 1.0) | Out-Null
    
    Write-Host "  Added $langName"
}

# 3. Add paradigm relationships
Write-Host "`n3. Adding paradigm relationships..."

$supportsParadigm = New-PredicateNode "supportsParadigm"
$supportsParadigm = Add-Atom -AtomSpace $kb -Atom $supportsParadigm

foreach ($langName in $languages.Keys) {
    $langNode = $langNodes[$langName]
    $paradigms = $languages[$langName].Paradigms
    
    foreach ($p in $paradigms) {
        $eval = New-EvaluationLink -Predicate $supportsParadigm -Arguments @($langNode, $p) -Strength 1.0 -Confidence 0.95
        Add-Atom -AtomSpace $kb -Atom $eval | Out-Null
    }
}

Write-Host "  Added paradigm support relationships"

# 4. Add properties (year created, popularity, etc.)
Write-Host "`n4. Adding properties..."

$createdIn = New-PredicateNode "createdInYear"
$createdIn = Add-Atom -AtomSpace $kb -Atom $createdIn

foreach ($langName in $languages.Keys) {
    $langNode = $langNodes[$langName]
    $year = $languages[$langName].Year
    $yearNode = New-ConceptNode $year.ToString()
    $yearNode = Add-Atom -AtomSpace $kb -Atom $yearNode
    
    $eval = New-EvaluationLink -Predicate $createdIn -Arguments @($langNode, $yearNode) -Strength 1.0 -Confidence 1.0
    Add-Atom -AtomSpace $kb -Atom $eval | Out-Null
}

Write-Host "  Added creation year properties"

# 5. Add similarity relationships
Write-Host "`n5. Adding similarity relationships..."

$similarities = @(
    @{ Lang1 = "PowerShell"; Lang2 = "Python"; Strength = 0.75 }
    @{ Lang1 = "Python"; Lang2 = "JavaScript"; Strength = 0.70 }
    @{ Lang1 = "Java"; Lang2 = "C#"; Strength = 0.85 }
    @{ Lang1 = "JavaScript"; Lang2 = "Java"; Strength = 0.60 }
    @{ Lang1 = "Haskell"; Lang2 = "Lisp"; Strength = 0.80 }
)

foreach ($sim in $similarities) {
    $lang1 = $langNodes[$sim.Lang1]
    $lang2 = $langNodes[$sim.Lang2]
    $simLink = New-SimilarityLink -Atom1 $lang1 -Atom2 $lang2 -Strength $sim.Strength -Confidence 0.8
    Add-Atom -AtomSpace $kb -Atom $simLink | Out-Null
    Write-Host "  $($sim.Lang1) similar to $($sim.Lang2) (strength: $($sim.Strength))"
}

# 6. Query the knowledge graph
Write-Host "`n`n=== Querying the Knowledge Graph ===" -ForegroundColor Green

# Query 1: Find all object-oriented languages
Write-Host "`nQuery 1: Find all object-oriented languages"
$varLang = New-VariableNode '$lang'
$pattern = New-EvaluationLink -Predicate $supportsParadigm -Arguments @($varLang, $oop)

$results = Find-Pattern -AtomSpace $kb -Pattern $pattern
Write-Host "Found $($results.Count) OOP languages:"
foreach ($result in $results) {
    $lang = $result['$lang']
    Write-Host "  - $($lang.Name)"
}

# Query 2: Find all functional languages
Write-Host "`nQuery 2: Find all functional languages"
$pattern = New-EvaluationLink -Predicate $supportsParadigm -Arguments @($varLang, $functional)

$results = Find-Pattern -AtomSpace $kb -Pattern $pattern
Write-Host "Found $($results.Count) functional languages:"
foreach ($result in $results) {
    $lang = $result['$lang']
    Write-Host "  - $($lang.Name)"
}

# Query 3: Find languages created before 2000
Write-Host "`nQuery 3: Find languages created before 2000"
$oldLanguages = Find-AtomsByPredicate -AtomSpace $kb -Predicate {
    param($atom)
    
    # Check if this is a language
    if ($atom -isnot [Node]) { return $false }
    
    $incoming = $kb.GetIncomingSet($atom)
    $isLanguage = $false
    
    foreach ($link in $incoming) {
        if ($link.Type -eq [AtomType]::InheritanceLink -and 
            $link.GetOutgoingAtom(1).Name -eq "ProgrammingLanguage") {
            $isLanguage = $true
            break
        }
    }
    
    if (-not $isLanguage) { return $false }
    
    # Check creation year
    foreach ($link in $incoming) {
        if ($link.Type -eq [AtomType]::EvaluationLink) {
            $pred = $link.GetOutgoingAtom(0)
            if ($pred.Name -eq "createdInYear") {
                $listLink = $link.GetOutgoingAtom(1)
                $yearNode = $listLink.GetOutgoingAtom(1)
                $year = [int]$yearNode.Name
                return $year -lt 2000
            }
        }
    }
    
    return $false
}

Write-Host "Found $($oldLanguages.Count) languages created before 2000:"
foreach ($lang in $oldLanguages) {
    Write-Host "  - $($lang.Name)"
}

# Query 4: Find languages similar to PowerShell
Write-Host "`nQuery 4: Find languages similar to PowerShell"
$pwsh = $langNodes["PowerShell"]
$incoming = Get-IncomingSet -AtomSpace $kb -Atom $pwsh

Write-Host "Languages similar to PowerShell:"
foreach ($link in $incoming) {
    if ($link.Type -eq [AtomType]::SimilarityLink) {
        $other = $link.GetOutgoingAtom(0)
        if ($other.Name -eq "PowerShell") {
            $other = $link.GetOutgoingAtom(1)
        }
        $strength = $link.GetTruthValue().Strength
        Write-Host "  - $($other.Name) (similarity: $($strength))"
    }
}

# Query 5: Multi-paradigm languages (support 3+ paradigms)
Write-Host "`nQuery 5: Find multi-paradigm languages (3+ paradigms)"

$multiParadigm = @{}

foreach ($langName in $languages.Keys) {
    $langNode = $langNodes[$langName]
    $incoming = Get-IncomingSet -AtomSpace $kb -Atom $langNode
    
    $paradigmCount = 0
    $supportedParadigms = @()
    
    foreach ($link in $incoming) {
        if ($link.Type -eq [AtomType]::EvaluationLink) {
            $pred = $link.GetOutgoingAtom(0)
            if ($pred.Name -eq "supportsParadigm") {
                $listLink = $link.GetOutgoingAtom(1)
                $paradigmNode = $listLink.GetOutgoingAtom(1)
                $paradigmCount++
                $supportedParadigms += $paradigmNode.Name
            }
        }
    }
    
    if ($paradigmCount -ge 3) {
        $multiParadigm[$langName] = $supportedParadigms
    }
}

Write-Host "Found $($multiParadigm.Count) multi-paradigm languages:"
foreach ($langName in $multiParadigm.Keys) {
    $paradigms = $multiParadigm[$langName] -join ", "
    Write-Host "  - $langName : $paradigms"
}

# 7. Knowledge graph statistics
Write-Host "`n`n=== Knowledge Graph Statistics ===" -ForegroundColor Green

$stats = Get-AtomSpaceStatistics -AtomSpace $kb

Write-Host "Total Atoms: $($stats.TotalAtoms)"
Write-Host "Nodes: $($stats.NodeCount)"
Write-Host "Links: $($stats.LinkCount)"
Write-Host "`nAtom Type Distribution:"
foreach ($type in $stats.AtomsByType.Keys | Sort-Object) {
    Write-Host "  $type : $($stats.AtomsByType[$type])"
}

# 8. Export the knowledge graph
Write-Host "`n`nExporting knowledge graph..."
$exportPath = Join-Path $PSScriptRoot "knowledge-graph-export.json"
Export-AtomSpace -AtomSpace $kb -Path $exportPath

Write-Host "`n=== Knowledge Graph Example Complete ===`n" -ForegroundColor Cyan
Write-Host "This example demonstrated:"
Write-Host "  ✓ Building hierarchical ontologies"
Write-Host "  ✓ Creating semantic relationships"
Write-Host "  ✓ Adding properties and metadata"
Write-Host "  ✓ Similarity relationships"
Write-Host "  ✓ Complex pattern matching queries"
Write-Host "  ✓ Predicate-based filtering"
Write-Host "  ✓ Knowledge graph export"
Write-Host "`nYou can now build sophisticated knowledge graphs in PowerShell!`n"
