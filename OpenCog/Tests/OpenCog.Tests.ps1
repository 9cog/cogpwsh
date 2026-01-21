<#
.SYNOPSIS
    Comprehensive test suite for OpenCog PowerShell module
    
.DESCRIPTION
    Tests all core functionality:
    - Atom creation and properties
    - AtomSpace operations
    - Pattern matching
    - Truth values
    - Query system
#>

Import-Module (Join-Path $PSScriptRoot ".." "OpenCog.psd1") -Force

# Test framework helpers
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:CurrentTestSection = ""

function Start-TestSection {
    param([string]$Name)
    $script:CurrentTestSection = $Name
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
}

function Test-Assertion {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$FailureMessage = ""
    )
    
    if ($Condition) {
        Write-Host "  ✓ $Name" -ForegroundColor Green
        $script:TestsPassed++
    }
    else {
        Write-Host "  ✗ $Name" -ForegroundColor Red
        if ($FailureMessage) {
            Write-Host "    $FailureMessage" -ForegroundColor Yellow
        }
        $script:TestsFailed++
    }
}

function Show-TestSummary {
    $total = $script:TestsPassed + $script:TestsFailed
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests: $total"
    Write-Host "Passed: $script:TestsPassed" -ForegroundColor Green
    Write-Host "Failed: $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { "Green" } else { "Red" })
    
    if ($script:TestsFailed -eq 0) {
        Write-Host "`n✓ All tests passed!" -ForegroundColor Green
        return 0
    }
    else {
        Write-Host "`n✗ Some tests failed!" -ForegroundColor Red
        return 1
    }
}

# Begin Tests
Write-Host "`n=== OpenCog PowerShell - Test Suite ===`n" -ForegroundColor Cyan

# Test 1: Atom Creation
Start-TestSection "Atom Creation Tests"

$testNode = New-ConceptNode "TestConcept"
Test-Assertion "Create ConceptNode" ($null -ne $testNode)
Test-Assertion "Node has correct type" ($testNode.Type.ToString() -eq "ConceptNode")
Test-Assertion "Node has correct name" ($testNode.Name -eq "TestConcept")
Test-Assertion "Node has valid handle" ($testNode.Handle -ne [guid]::Empty)

$testPred = New-PredicateNode "TestPredicate"
Test-Assertion "Create PredicateNode" ($null -ne $testPred)
Test-Assertion "PredicateNode has correct type" ($testPred.Type.ToString() -eq "PredicateNode")

$testVar = New-VariableNode '$x'
Test-Assertion "Create VariableNode" ($null -ne $testVar)
Test-Assertion "VariableNode has correct type" ($testVar.Type.ToString() -eq "VariableNode")

$node1 = New-ConceptNode "A"
$node2 = New-ConceptNode "B"
$testLink = New-InheritanceLink -Child $node1 -Parent $node2
Test-Assertion "Create InheritanceLink" ($null -ne $testLink)
Test-Assertion "Link has correct type" ($testLink.Type.ToString() -eq "InheritanceLink")
Test-Assertion "Link has correct arity" ($testLink.GetArity() -eq 2)
Test-Assertion "Link outgoing[0] is child" ($testLink.GetOutgoingAtom(0).Name -eq "A")
Test-Assertion "Link outgoing[1] is parent" ($testLink.GetOutgoingAtom(1).Name -eq "B")

# Test 2: Truth Values
Start-TestSection "Truth Value Tests"

# Test through atoms instead of direct TruthValue creation
$nodeHighTV = New-ConceptNode "HighTV" -Strength 0.8 -Confidence 0.9
Test-Assertion "Create node with TruthValue" ($null -ne $nodeHighTV)
Test-Assertion "TruthValue strength correct" ($nodeHighTV.TV.Strength -eq 0.8)
Test-Assertion "TruthValue confidence correct" ($nodeHighTV.TV.Confidence -eq 0.9)

$nodeLowTV = New-ConceptNode "LowTV" -Strength 0.7 -Confidence 0.8
$tvMerged = $nodeHighTV.TV.Merge($nodeLowTV.TV)
Test-Assertion "Merge truth values" ($null -ne $tvMerged)
Test-Assertion "Merged strength in valid range" ($tvMerged.Strength -ge 0 -and $tvMerged.Strength -le 1)
Test-Assertion "Merged confidence in valid range" ($tvMerged.Confidence -ge 0 -and $tvMerged.Confidence -le 1)

$nodeWithTV = New-ConceptNode "TestTV" -Strength 0.75 -Confidence 0.85
Test-Assertion "Node with custom TV created" ($null -ne $nodeWithTV)
Test-Assertion "Node TV strength correct" ($nodeWithTV.TV.Strength -eq 0.75)
Test-Assertion "Node TV confidence correct" ($nodeWithTV.TV.Confidence -eq 0.85)

# Test 3: AtomSpace Operations
Start-TestSection "AtomSpace Operations Tests"

$space = New-AtomSpace
Test-Assertion "Create AtomSpace" ($null -ne $space)
Test-Assertion "Empty AtomSpace has size 0" ($space.GetSize() -eq 0)

$atom1 = New-ConceptNode "Atom1"
$added1 = Add-Atom -AtomSpace $space -Atom $atom1
Test-Assertion "Add atom to AtomSpace" ($null -ne $added1)
Test-Assertion "AtomSpace size increases" ($space.GetSize() -eq 1)
Test-Assertion "AtomSpace contains atom" ($space.Contains($atom1))

$atom2 = New-ConceptNode "Atom2"
Add-Atom -AtomSpace $space -Atom $atom2 | Out-Null
Test-Assertion "Add second atom" ($space.GetSize() -eq 2)

# Test duplicate addition (should merge)
$atom1Dup = New-ConceptNode "Atom1" -Strength 0.5 -Confidence 0.5
$addedDup = Add-Atom -AtomSpace $space -Atom $atom1Dup
Test-Assertion "Duplicate atom merged" ($space.GetSize() -eq 2)
Test-Assertion "Returned same atom instance" ($addedDup.Handle -eq $added1.Handle)

$retrieved = Get-Node -AtomSpace $space -Type ConceptNode -Name "Atom1"
Test-Assertion "Retrieve node by name and type" ($null -ne $retrieved)
Test-Assertion "Retrieved node is correct" ($retrieved.Name -eq "Atom1")

$allConcepts = Get-AtomsByType -AtomSpace $space -Type ConceptNode
Test-Assertion "Get atoms by type" ($allConcepts.Count -eq 2)

$removed = Remove-Atom -AtomSpace $space -Atom $atom2
Test-Assertion "Remove atom from AtomSpace" ($removed -eq $true)
Test-Assertion "AtomSpace size decreases" ($space.GetSize() -eq 1)
Test-Assertion "AtomSpace no longer contains removed atom" (-not $space.Contains($atom2))

Clear-AtomSpace -AtomSpace $space
Test-Assertion "Clear AtomSpace" ($space.GetSize() -eq 0)

# Test 4: Links and Incoming Sets
Start-TestSection "Links and Incoming Set Tests"

$space2 = New-AtomSpace
$cat = New-ConceptNode "Cat"
$cat = Add-Atom -AtomSpace $space2 -Atom $cat

$animal = New-ConceptNode "Animal"
$animal = Add-Atom -AtomSpace $space2 -Atom $animal

$link1 = New-InheritanceLink -Child $cat -Parent $animal
$link1 = Add-Atom -AtomSpace $space2 -Atom $link1

Test-Assertion "Link added to AtomSpace" ($space2.Contains($link1))

$incoming = Get-IncomingSet -AtomSpace $space2 -Atom $animal
Test-Assertion "Incoming set not empty" ($incoming.Count -gt 0)
Test-Assertion "Incoming set contains link" ($incoming[0].GetHandle() -eq $link1.GetHandle())

$incomingCat = Get-IncomingSet -AtomSpace $space2 -Atom $cat
Test-Assertion "Cat also in incoming set" ($incomingCat.Count -gt 0)

# Test 5: Pattern Matching
Start-TestSection "Pattern Matching Tests"

$space3 = New-AtomSpace

# Build test knowledge base
$dog = New-ConceptNode "Dog"
$dog = Add-Atom -AtomSpace $space3 -Atom $dog

$cat3 = New-ConceptNode "Cat"
$cat3 = Add-Atom -AtomSpace $space3 -Atom $cat3

$animal3 = New-ConceptNode "Animal"
$animal3 = Add-Atom -AtomSpace $space3 -Atom $animal3

$dogLink = New-InheritanceLink -Child $dog -Parent $animal3
Add-Atom -AtomSpace $space3 -Atom $dogLink | Out-Null

$catLink = New-InheritanceLink -Child $cat3 -Parent $animal3
Add-Atom -AtomSpace $space3 -Atom $catLink | Out-Null

# Pattern: Find all things inheriting from Animal
$varX = New-VariableNode '$x'
$pattern = New-InheritanceLink -Child $varX -Parent $animal3

$matches = Find-Pattern -AtomSpace $space3 -Pattern $pattern
Test-Assertion "Pattern matching finds results" ($matches.Count -gt 0)
Test-Assertion "Pattern matching finds correct count" ($matches.Count -eq 2)

$matchNames = $matches | ForEach-Object { $_['$x'].Name } | Sort-Object
Test-Assertion "Pattern matches Cat" ($matchNames -contains "Cat")
Test-Assertion "Pattern matches Dog" ($matchNames -contains "Dog")

# Test 6: Complex Links
Start-TestSection "Complex Link Tests"

$space4 = New-AtomSpace

$hasLegs = New-PredicateNode "hasLegs"
$hasLegs = Add-Atom -AtomSpace $space4 -Atom $hasLegs

$spider = New-ConceptNode "Spider"
$spider = Add-Atom -AtomSpace $space4 -Atom $spider

$eightLegs = New-ConceptNode "8"
$eightLegs = Add-Atom -AtomSpace $space4 -Atom $eightLegs

$eval = New-EvaluationLink -Predicate $hasLegs -Arguments @($spider, $eightLegs)
$eval = Add-Atom -AtomSpace $space4 -Atom $eval

Test-Assertion "EvaluationLink created" ($null -ne $eval)
Test-Assertion "EvaluationLink has correct type" ($eval.Type.ToString() -eq "EvaluationLink")
Test-Assertion "EvaluationLink has arity 2" ($eval.GetArity() -eq 2)

$predOut = $eval.GetOutgoingAtom(0)
Test-Assertion "EvaluationLink first element is predicate" ($predOut.Name -eq "hasLegs")

$listOut = $eval.GetOutgoingAtom(1)
Test-Assertion "EvaluationLink second element is ListLink" ($listOut.Type.ToString() -eq "ListLink")

# Test 7: Logical Links
Start-TestSection "Logical Link Tests"

$a = New-ConceptNode "A"
$b = New-ConceptNode "B"
$c = New-ConceptNode "C"

$andLink = New-AndLink -Atoms @($a, $b, $c)
Test-Assertion "AndLink created" ($null -ne $andLink)
Test-Assertion "AndLink has correct arity" ($andLink.GetArity() -eq 3)

$orLink = New-OrLink -Atoms @($a, $b)
Test-Assertion "OrLink created" ($null -ne $orLink)
Test-Assertion "OrLink has correct arity" ($orLink.GetArity() -eq 2)

$implLink = New-ImplicationLink -Antecedent $a -Consequent $b
Test-Assertion "ImplicationLink created" ($null -ne $implLink)
Test-Assertion "ImplicationLink has correct arity" ($implLink.GetArity() -eq 2)

# Test 8: Query System
Start-TestSection "Query System Tests"

$space5 = New-AtomSpace

# Add atoms with varying truth values
$high = New-ConceptNode "HighConfidence" -Strength 0.9 -Confidence 0.95
$high = Add-Atom -AtomSpace $space5 -Atom $high

$med = New-ConceptNode "MediumConfidence" -Strength 0.8 -Confidence 0.6
$med = Add-Atom -AtomSpace $space5 -Atom $med

$low = New-ConceptNode "LowConfidence" -Strength 0.7 -Confidence 0.3
$low = Add-Atom -AtomSpace $space5 -Atom $low

# Find atoms with high confidence
$highConfAtoms = Find-AtomsByPredicate -AtomSpace $space5 -Predicate {
    param($atom)
    $atom.GetTruthValue().Confidence -gt 0.8
}

Test-Assertion "Predicate query finds results" ($highConfAtoms.Count -gt 0)
Test-Assertion "Predicate query filters correctly" ($highConfAtoms.Count -eq 1)
Test-Assertion "Predicate query finds correct atom" ($highConfAtoms[0].Name -eq "HighConfidence")

# Test 9: Statistics and Export
Start-TestSection "Statistics and Export Tests"

$space6 = New-AtomSpace

for ($i = 1; $i -le 5; $i++) {
    $node = New-ConceptNode "Node$i"
    Add-Atom -AtomSpace $space6 -Atom $node | Out-Null
}

for ($i = 1; $i -le 3; $i++) {
    $pred = New-PredicateNode "Pred$i"
    Add-Atom -AtomSpace $space6 -Atom $pred | Out-Null
}

$stats = Get-AtomSpaceStatistics -AtomSpace $space6
Test-Assertion "Statistics returns data" ($null -ne $stats)
Test-Assertion "Total atoms correct" ($stats.TotalAtoms -eq 8)
Test-Assertion "Node count correct" ($stats.NodeCount -eq 8)

$export = Export-AtomSpace -AtomSpace $space6
Test-Assertion "Export returns data" ($null -ne $export)
Test-Assertion "Export has nodes" ($export.Nodes.Count -gt 0)

# Test 10: Atom Equality
Start-TestSection "Atom Equality Tests"

$n1 = New-ConceptNode "Test"
$n2 = New-ConceptNode "Test"
Test-Assertion "Nodes with same type and name are equal" ($n1.Equals($n2))

$n3 = New-ConceptNode "Different"
Test-Assertion "Nodes with different names are not equal" (-not $n1.Equals($n3))

$l1 = New-InheritanceLink -Child $n1 -Parent $n2
$l2 = New-InheritanceLink -Child $n1 -Parent $n2
Test-Assertion "Links with same structure are equal" ($l1.Equals($l2))

$l3 = New-InheritanceLink -Child $n2 -Parent $n1
Test-Assertion "Links with different structure are not equal" (-not $l1.Equals($l3))

# Show final summary
Show-TestSummary
