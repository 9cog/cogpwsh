<#
.SYNOPSIS
    Tests for Phase 3 Advanced Pattern Matching
    
.DESCRIPTION
    Comprehensive tests for advanced pattern matching features
#>

# Import the OpenCog module
Import-Module "$PSScriptRoot/../OpenCog.psd1" -Force

# Test framework
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:FailedTests = @()

function Assert-True {
    param([bool]$Condition, [string]$TestName)
    if ($Condition) {
        $script:TestsPassed++
        Write-Host "  ✓ $TestName" -ForegroundColor Green
    } else {
        $script:TestsFailed++
        $script:FailedTests += $TestName
        Write-Host "  ✗ $TestName" -ForegroundColor Red
    }
}

function Assert-NotNull {
    param($Object, [string]$TestName)
    Assert-True -Condition ($null -ne $Object) -TestName $TestName
}

function Assert-Equal {
    param($Expected, $Actual, [string]$TestName)
    Assert-True -Condition ($Expected -eq $Actual) -TestName "$TestName (Expected: $Expected, Actual: $Actual)"
}

Write-Host "`n=== Phase 3 Advanced Pattern Matching Tests ===`n" -ForegroundColor Cyan

#region Test Suite 1: Link Creation
Write-Host "Test Suite 1: Advanced Link Creation" -ForegroundColor Yellow

$kb = New-AtomSpace
$varX = New-VariableNode '$x'
$varY = New-VariableNode '$y'
$cat = New-ConceptNode "Cat"
$animal = New-ConceptNode "Animal"

# Test GetLink creation
$varList = New-ListLink @($varX)
$pattern = New-InheritanceLink -Child $varX -Parent $animal
$getLink = New-GetLink -VariableList $varList -Pattern $pattern -Output $varX

Assert-NotNull -Object $getLink -TestName "GetLink created"
Assert-Equal -Expected 'GetLink' -Actual ($getLink.GetMetadata('LinkSubType')) -TestName "GetLink has correct subtype"

# Test BindLink creation
$rewrite = New-ConceptNode "Rewritten"
$bindLink = New-BindLink -VariableList $varList -Pattern $pattern -Rewrite $rewrite

Assert-NotNull -Object $bindLink -TestName "BindLink created"
Assert-Equal -Expected 'BindLink' -Actual ($bindLink.GetMetadata('LinkSubType')) -TestName "BindLink has correct subtype"

# Test SatisfactionLink creation
$satLink = New-SatisfactionLink -VariableList $varList -Pattern $pattern

Assert-NotNull -Object $satLink -TestName "SatisfactionLink created"
Assert-Equal -Expected 'SatisfactionLink' -Actual ($satLink.GetMetadata('LinkSubType')) -TestName "SatisfactionLink has correct subtype"

# Test DualLink creation
$forward = New-InheritanceLink -Child $varX -Parent $animal
$backward = New-InheritanceLink -Child $cat -Parent $varY
$dualLink = New-DualLink -Forward $forward -Backward $backward

Assert-NotNull -Object $dualLink -TestName "DualLink created"
Assert-Equal -Expected 'DualLink' -Actual ($dualLink.GetMetadata('LinkSubType')) -TestName "DualLink has correct subtype"

# Test ChoiceLink creation
$alt1 = New-ConceptNode "Alternative1"
$alt2 = New-ConceptNode "Alternative2"
$choiceLink = New-ChoiceLink -Alternatives @($alt1, $alt2)

Assert-NotNull -Object $choiceLink -TestName "ChoiceLink created"
Assert-Equal -Expected 'ChoiceLink' -Actual ($choiceLink.GetMetadata('LinkSubType')) -TestName "ChoiceLink has correct subtype"

# Test SequentialOrLink creation
$seqOrLink = New-SequentialOrLink -Alternatives @($alt1, $alt2)

Assert-NotNull -Object $seqOrLink -TestName "SequentialOrLink created"
Assert-Equal -Expected 'SequentialOrLink' -Actual ($seqOrLink.GetMetadata('LinkSubType')) -TestName "SequentialOrLink has correct subtype"

# Test AbsentLink creation
$absentLink = New-AbsentLink -Pattern $pattern

Assert-NotNull -Object $absentLink -TestName "AbsentLink created"
Assert-Equal -Expected 'AbsentLink' -Actual ($absentLink.GetMetadata('LinkSubType')) -TestName "AbsentLink has correct subtype"

#endregion

#region Test Suite 2: GetLink Execution (Structure Only)
Write-Host "`nTest Suite 2: GetLink Structure" -ForegroundColor Yellow

# Setup knowledge base
$kb = New-AtomSpace
$cat = New-ConceptNode "Cat"
$dog = New-ConceptNode "Dog"
$mammal = New-ConceptNode "Mammal"

$kb.AddAtom($cat)
$kb.AddAtom($dog)
$kb.AddAtom($mammal)

$catInherit = New-InheritanceLink -Child $cat -Parent $mammal
$dogInherit = New-InheritanceLink -Child $dog -Parent $mammal

$kb.AddAtom($catInherit)
$kb.AddAtom($dogInherit)

# Create GetLink
$varX = New-VariableNode '$x'
$varList = New-ListLink @($varX)
$pattern = New-InheritanceLink -Child $varX -Parent $mammal
$getLink = New-GetLink -VariableList $varList -Pattern $pattern -Output $varX

Assert-NotNull -Object $getLink -TestName "GetLink structure created for mammals query"
Assert-NotNull -Object $getLink.VariableList -TestName "GetLink has variable list"
Assert-NotNull -Object $getLink.Pattern -TestName "GetLink has pattern"
Assert-NotNull -Object $getLink.Output -TestName "GetLink has output specification"

#endregion

#region Test Suite 3: BindLink Structure
Write-Host "`nTest Suite 3: BindLink Structure" -ForegroundColor Yellow

$varX = New-VariableNode '$x'
$varY = New-VariableNode '$y'
$varList = New-ListLink @($varX, $varY)

$pattern1 = New-InheritanceLink -Child $varX -Parent $varY
$pattern2 = New-InheritanceLink -Child $varY -Parent $mammal
$pattern = New-AndLink @($pattern1, $pattern2)

$rewrite = New-InheritanceLink -Child $varX -Parent $mammal

$bindLink = New-BindLink -VariableList $varList -Pattern $pattern -Rewrite $rewrite

Assert-NotNull -Object $bindLink -TestName "BindLink structure created for transitive inference"
Assert-NotNull -Object $bindLink.VariableList -TestName "BindLink has variable list"
Assert-NotNull -Object $bindLink.Pattern -TestName "BindLink has pattern"
Assert-NotNull -Object $bindLink.Rewrite -TestName "BindLink has rewrite template"

#endregion

#region Test Suite 4: SatisfactionLink Structure
Write-Host "`nTest Suite 4: SatisfactionLink Structure" -ForegroundColor Yellow

$varX = New-VariableNode '$x'
$varList = New-ListLink @($varX)
$pattern = New-InheritanceLink -Child $varX -Parent $mammal

$satLink = New-SatisfactionLink -VariableList $varList -Pattern $pattern

Assert-NotNull -Object $satLink -TestName "SatisfactionLink structure created"
Assert-NotNull -Object $satLink.VariableList -TestName "SatisfactionLink has variable list"
Assert-NotNull -Object $satLink.Pattern -TestName "SatisfactionLink has pattern"

#endregion

#region Test Suite 5: ChoiceLink Structure
Write-Host "`nTest Suite 5: ChoiceLink Structure" -ForegroundColor Yellow

$varX = New-VariableNode '$x'
$pattern1 = New-InheritanceLink -Child $varX -Parent $mammal
$pattern2 = New-InheritanceLink -Child $varX -Parent $animal

$choiceLink = New-ChoiceLink -Alternatives @($pattern1, $pattern2)

Assert-NotNull -Object $choiceLink -TestName "ChoiceLink structure created"
Assert-NotNull -Object $choiceLink.Alternatives -TestName "ChoiceLink has alternatives"
Assert-Equal -Expected 2 -Actual $choiceLink.Alternatives.Count -TestName "ChoiceLink has 2 alternatives"

#endregion

#region Test Suite 6: AbsentLink Structure
Write-Host "`nTest Suite 6: AbsentLink Structure" -ForegroundColor Yellow

$robot = New-ConceptNode "Robot"
$pattern = New-InheritanceLink -Child $cat -Parent $robot

$absentLink = New-AbsentLink -Pattern $pattern

Assert-NotNull -Object $absentLink -TestName "AbsentLink structure created"
Assert-NotNull -Object $absentLink.Pattern -TestName "AbsentLink has pattern"

#endregion

#region Test Suite 7: Complex Pattern Structure
Write-Host "`nTest Suite 7: Complex Pattern Structure" -ForegroundColor Yellow

# Create complex nested pattern
$varX = New-VariableNode '$x'
$varY = New-VariableNode '$y'
$varList = New-ListLink @($varX, $varY)

$subPattern1 = New-InheritanceLink -Child $varX -Parent $varY
$subPattern2 = New-InheritanceLink -Child $varY -Parent $animal
$complexPattern = New-AndLink @($subPattern1, $subPattern2)

$outputPair = New-ListLink @($varX, $varY)

$complexGetLink = New-GetLink -VariableList $varList -Pattern $complexPattern -Output $outputPair

Assert-NotNull -Object $complexGetLink -TestName "Complex GetLink structure created"
Assert-NotNull -Object $complexGetLink.Pattern -TestName "Complex pattern is AndLink"
Assert-Equal -Expected 2 -Actual $complexGetLink.VariableList.Outgoing.Count -TestName "Complex pattern has 2 variables"

#endregion

#region Test Suite 8: Edge Cases
Write-Host "`nTest Suite 8: Edge Cases" -ForegroundColor Yellow

# Test with single alternative in ChoiceLink
$singleChoice = New-ChoiceLink -Alternatives @($pattern1)
Assert-NotNull -Object $singleChoice -TestName "ChoiceLink with single alternative"

# Test with empty variable list (should work for some patterns)
$emptyVarList = New-ListLink @()
Assert-NotNull -Object $emptyVarList -TestName "Empty variable list created"

# Test nested GetLinks
$innerGetLink = New-GetLink -VariableList $varList -Pattern $pattern -Output $varX
$outerPattern = New-ListLink @($innerGetLink)
Assert-NotNull -Object $outerPattern -TestName "Nested GetLink pattern structure"

#endregion

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { 'Green' } else { 'Red' })

if ($script:TestsFailed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $script:FailedTests) {
        Write-Host "  - $test" -ForegroundColor Red
    }
}

$passRate = [math]::Round(($script:TestsPassed / ($script:TestsPassed + $script:TestsFailed)) * 100, 1)
Write-Host "`nPass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { 'Green' } elseif ($passRate -ge 70) { 'Yellow' } else { 'Red' })

Write-Host "`nPhase 3 Advanced Pattern Matching tests complete!" -ForegroundColor Cyan
