# Phase 2 Extended Features Test Suite
# Tests comprehensive Phase 2 extended features including:
# - Extended value atoms (FloatValue, LinkValue)
# - Type system extensions (TypeChoice, TypeIntersection)
# - Additional advanced links (ImplicationScopeLink, PresentLink)
# - Value extractors (Get-TruthValueOf, Get-StrengthOf, Get-ConfidenceOf)
# - Type system helpers (Test-TypeCompatibility, Get-TypeHierarchy)

# Import module
Import-Module "$PSScriptRoot/../OpenCog.psd1" -Force

Write-Host "`n=== Testing Phase 2 Extended Features ===" -ForegroundColor Cyan

$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    FailedTests = @()
}

function Test-Feature {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $testResults.Total++
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✓ $Name" -ForegroundColor Green
            $testResults.Passed++
            return $true
        } else {
            Write-Host "  ✗ $Name" -ForegroundColor Red
            $testResults.Failed++
            $testResults.FailedTests += $Name
            return $false
        }
    } catch {
        Write-Host "  ✗ $Name - Error: $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.FailedTests += "$Name (Error: $_)"
        return $false
    }
}

Write-Host "`n--- Extended Value Atoms ---" -ForegroundColor Yellow

Test-Feature "FloatValue creation" {
    $float = New-FloatValue -Value 3.14159 -Precision 5
    return ($float -ne $null) -and ($float.GetValue() -eq 3.14159)
}

Test-Feature "FloatValue with Get-AtomValue" {
    $float = New-FloatValue -Value 2.71828
    $value = Get-AtomValue $float
    return $value -eq 2.71828
}

Test-Feature "LinkValue creation" {
    $node1 = New-ConceptNode "A"
    $node2 = New-ConceptNode "B"
    $link = New-InheritanceLink -Child $node1 -Parent $node2
    $linkValue = New-LinkValue -Link $link
    return ($linkValue -ne $null) -and ($linkValue.GetLink() -ne $null)
}

Test-Feature "LinkValue with Get-AtomValue" {
    $node1 = New-ConceptNode "X"
    $node2 = New-ConceptNode "Y"
    $link = New-SimilarityLink -Atom1 $node1 -Atom2 $node2
    $linkValue = New-LinkValue -Link $link
    $retrieved = Get-AtomValue $linkValue
    return ($retrieved -ne $null) -and ($retrieved.GetArity() -eq 2)
}

Write-Host "`n--- Extended Type System ---" -ForegroundColor Yellow

Test-Feature "TypeChoice creation (union types)" {
    $stringType = New-TypeNode -TypeName "String"
    $numberType = New-TypeNode -TypeName "Number"
    $choice = New-TypeChoice -Types @($stringType, $numberType)
    return ($choice -ne $null) -and ($choice.GetTypes().Count -eq 2)
}

Test-Feature "TypeIntersection creation (intersection types)" {
    $type1 = New-TypeNode -TypeName "Serializable"
    $type2 = New-TypeNode -TypeName "Comparable"
    $intersection = New-TypeIntersection -Types @($type1, $type2)
    return ($intersection -ne $null) -and ($intersection.GetTypes().Count -eq 2)
}

Test-Feature "Test-TypeCompatibility with TypeChoice" {
    $stringType = New-TypeNode -TypeName "StringNode"
    $numberType = New-TypeNode -TypeName "NumberNode"
    $choice = New-TypeChoice -Types @($stringType, $numberType)
    
    $stringNode = New-StringNode -Value "test"
    $result = Test-TypeCompatibility -Atom $stringNode -Type $choice
    return $result -eq $true
}

Write-Host "`n--- Additional Advanced Links ---" -ForegroundColor Yellow

Test-Feature "ImplicationScopeLink creation" {
    $varX = New-VariableNode '$x'
    $varList = New-ListLink @($varX)
    $antecedent = New-ConceptNode "Condition"
    $consequent = New-ConceptNode "Result"
    $scoped = New-ImplicationScopeLink -Variables $varList -Antecedent $antecedent -Consequent $consequent
    return ($scoped -ne $null) -and ($scoped.GetArity() -eq 3)
}

Test-Feature "ImplicationScopeLink with Test-AtomType" {
    $varX = New-VariableNode '$x'
    $varList = New-ListLink @($varX)
    $ant = New-ConceptNode "A"
    $con = New-ConceptNode "B"
    $scoped = New-ImplicationScopeLink -Variables $varList -Antecedent $ant -Consequent $con
    return Test-AtomType -Atom $scoped -SubType 'ImplicationScopeLink'
}

Test-Feature "PresentLink creation" {
    $atom = New-ConceptNode "HappeningNow"
    $present = New-PresentLink -Atom $atom
    return ($present -ne $null) -and ($present.GetArity() -eq 1)
}

Test-Feature "PresentLink with Test-AtomType" {
    $atom = New-PredicateNode "IsPresent"
    $present = New-PresentLink -Atom $atom
    return Test-AtomType -Atom $present -SubType 'PresentLink'
}

Write-Host "`n--- Value Extractors ---" -ForegroundColor Yellow

Test-Feature "Get-TruthValueOf" {
    $node = New-ConceptNode "TestNode" -Strength 0.8 -Confidence 0.9
    $tv = Get-TruthValueOf -Atom $node
    return ($tv -ne $null) -and ($tv.Strength -eq 0.8) -and ($tv.Confidence -eq 0.9)
}

Test-Feature "Get-StrengthOf" {
    $node = New-ConceptNode "TestStrength" -Strength 0.75 -Confidence 0.85
    $strength = Get-StrengthOf -Atom $node
    return $strength -eq 0.75
}

Test-Feature "Get-ConfidenceOf" {
    $node = New-ConceptNode "TestConfidence" -Strength 0.65 -Confidence 0.95
    $confidence = Get-ConfidenceOf -Atom $node
    return $confidence -eq 0.95
}

Write-Host "`n--- Type System Helpers ---" -ForegroundColor Yellow

Test-Feature "Test-TypeCompatibility basic" {
    $stringType = New-TypeNode -TypeName "StringNode"
    $stringNode = New-StringNode -Value "hello"
    return Test-TypeCompatibility -Atom $stringNode -Type $stringType
}

Test-Feature "Get-TypeHierarchy" {
    $kb = New-AtomSpace
    $node = New-ConceptNode "TestNode"
    $type = New-TypeNode -TypeName "CustomType"
    $typedLink = New-TypedAtomLink -Atom $node -Type $type
    
    $addedNode = $kb.AddAtom($node)
    $addedType = $kb.AddAtom($type)
    $addedLink = $kb.AddAtom($typedLink)
    
    $types = Get-TypeHierarchy -Atom $addedNode -AtomSpace $kb
    return $types.Count -gt 0
}

Write-Host "`n--- Integration Tests ---" -ForegroundColor Yellow

Test-Feature "Complete type system workflow" {
    $kb = New-AtomSpace
    
    # Create types
    $stringType = New-TypeNode -TypeName "String"
    $numberType = New-TypeNode -TypeName "Number"
    $unionType = New-TypeChoice -Types @($stringType, $numberType)
    
    # Create value atoms
    $name = New-StringNode -Value "Alice"
    $age = New-NumberNode -Value 30
    $pi = New-FloatValue -Value 3.14159
    
    # Add to AtomSpace
    $kb.AddAtom($stringType)
    $kb.AddAtom($numberType)
    $kb.AddAtom($name)
    $kb.AddAtom($age)
    $kb.AddAtom($pi)
    
    # Verify
    $stats = $kb.GetStatistics()
    return $stats.TotalAtoms -ge 5
}

Test-Feature "Advanced links with AtomSpace" {
    $kb = New-AtomSpace
    
    # Create scoped implication
    $varX = New-VariableNode '$x'
    $varList = New-ListLink @($varX)
    $condition = New-ConceptNode "Human"
    $conclusion = New-ConceptNode "Mortal"
    $rule = New-ImplicationScopeLink -Variables $varList -Antecedent $condition -Consequent $conclusion
    
    # Create present link
    $event = New-ConceptNode "CurrentEvent"
    $present = New-PresentLink -Atom $event
    
    # Add to AtomSpace
    $kb.AddAtom($varX)
    $kb.AddAtom($varList)
    $kb.AddAtom($condition)
    $kb.AddAtom($conclusion)
    $kb.AddAtom($rule)
    $kb.AddAtom($event)
    $kb.AddAtom($present)
    
    return $kb.GetStatistics().TotalAtoms -ge 7
}

Test-Feature "Value extractors workflow" {
    $node1 = New-ConceptNode "High" -Strength 0.9 -Confidence 0.95
    $node2 = New-ConceptNode "Medium" -Strength 0.5 -Confidence 0.5
    $node3 = New-ConceptNode "Low" -Strength 0.1 -Confidence 0.2
    
    $s1 = Get-StrengthOf $node1
    $s2 = Get-StrengthOf $node2
    $s3 = Get-StrengthOf $node3
    
    return ($s1 -gt $s2) -and ($s2 -gt $s3)
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -eq 0) { 'Green' } else { 'Red' })

if ($testResults.Failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $testResults.FailedTests) {
        Write-Host "  - $test" -ForegroundColor Red
    }
}

$passRate = [math]::Round(($testResults.Passed / $testResults.Total) * 100, 1)
Write-Host "`nPass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { 'Green' } elseif ($passRate -ge 70) { 'Yellow' } else { 'Red' })

# Return success if all tests passed
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })
