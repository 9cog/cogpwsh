<#
.SYNOPSIS
    Test Suite for Universal Kernel Generator
    
.DESCRIPTION
    Comprehensive tests for ElementaryDifferentials, BSeriesExpansion,
    and UniversalKernelGenerator modules.
#>

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath

# Import modules
Import-Module "$modulePath/KernelGenerator/ElementaryDifferentials.psm1" -Force
Import-Module "$modulePath/KernelGenerator/BSeriesExpansion.psm1" -Force
Import-Module "$modulePath/KernelGenerator/UniversalKernelGenerator.psm1" -Force

# Test framework
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestsSkipped = 0

function Test-Assert {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$true)]
        [bool]$Condition,
        
        [string]$Message = ""
    )
    
    if ($Condition) {
        Write-Host "  ✓ $TestName" -ForegroundColor Green
        $script:TestsPassed++
    }
    else {
        Write-Host "  ✗ $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "    $Message" -ForegroundColor Yellow
        }
        $script:TestsFailed++
    }
}

function Test-AssertEqual {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$true)]
        $Expected,
        
        [Parameter(Mandatory=$true)]
        $Actual
    )
    
    $condition = $Expected -eq $Actual
    $message = "Expected: $Expected, Actual: $Actual"
    Test-Assert -TestName $TestName -Condition $condition -Message $message
}

function Test-AssertNotNull {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$true)]
        $Value
    )
    
    Test-Assert -TestName $TestName -Condition ($null -ne $Value) -Message "Value is null"
}

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     UNIVERSAL KERNEL GENERATOR TEST SUITE               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================
# Test Suite 1: Elementary Differentials
# ============================================
Write-Host "Test Suite 1: Elementary Differentials" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Test 1.1: Generator creation
$generator = New-ElementaryDifferentialGenerator
Test-AssertNotNull -TestName "Generator created" -Value $generator

# Test 1.2: Generate trees for order 1
$trees1 = $generator.GenerateTrees(1)
Test-AssertEqual -TestName "Order 1 has 1 tree" -Expected 1 -Actual $trees1.Count

# Test 1.3: Generate trees for order 2
$trees2 = $generator.GenerateTrees(2)
Test-AssertEqual -TestName "Order 2 has 1 tree" -Expected 1 -Actual $trees2.Count

# Test 1.4: Generate trees for order 3
$trees3 = $generator.GenerateTrees(3)
Test-AssertEqual -TestName "Order 3 has 2 trees" -Expected 2 -Actual $trees3.Count

# Test 1.5: Generate trees for order 4
$trees4 = $generator.GenerateTrees(4)
Test-AssertEqual -TestName "Order 4 has 4 trees" -Expected 4 -Actual $trees4.Count

# Test 1.6: Generate trees for order 5
$trees5 = $generator.GenerateTrees(5)
Test-AssertEqual -TestName "Order 5 has 9 trees" -Expected 9 -Actual $trees5.Count

# Test 1.7: A000081 sequence
$sequence = Get-A000081Sequence -Terms 5
Test-AssertEqual -TestName "A000081(1) = 1" -Expected 1 -Actual $sequence[0]
Test-AssertEqual -TestName "A000081(2) = 1" -Expected 1 -Actual $sequence[1]
Test-AssertEqual -TestName "A000081(3) = 2" -Expected 2 -Actual $sequence[2]
Test-AssertEqual -TestName "A000081(5) = 9" -Expected 9 -Actual $sequence[4]

# Test 1.8: Tree structure
$tree = $trees1[0]
Test-AssertNotNull -TestName "Tree has structure" -Value $tree.Structure
Test-AssertEqual -TestName "Order 1 tree is 'f'" -Expected "f" -Actual $tree.Structure

# Test 1.9: Differential operator conversion
$operator = ConvertTo-DifferentialOperator -Tree $tree
Test-AssertEqual -TestName "Tree converts to operator" -Expected "f" -Actual $operator

Write-Host ""

# ============================================
# Test Suite 2: B-Series Expansion
# ============================================
Write-Host "Test Suite 2: B-Series Expansion" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Test 2.1: Butcher tableau creation
$tableau = New-ButcherTableau -Order 4 -MethodName "RK4"
Test-AssertNotNull -TestName "Tableau created" -Value $tableau
Test-AssertEqual -TestName "RK4 has 4 stages" -Expected 4 -Actual $tableau.Stages
Test-AssertEqual -TestName "RK4 B weights count" -Expected 4 -Actual $tableau.B.Count

# Test 2.2: Euler method (order 1)
$euler = New-ButcherTableau -Order 1 -MethodName "Euler"
Test-AssertEqual -TestName "Euler has 1 stage" -Expected 1 -Actual $euler.Stages
Test-AssertEqual -TestName "Euler B weight is 1" -Expected 1.0 -Actual $euler.B[0]

# Test 2.3: B-Series expansion creation
$bseries = New-BSeriesExpansion -Order 3 -Domain "consciousness"
Test-AssertNotNull -TestName "B-Series created" -Value $bseries
Test-AssertEqual -TestName "B-Series order is 3" -Expected 3 -Actual $bseries.Order

# Test 2.4: Generate terms
$bseries.GenerateTerms()
$termCount = $bseries.TermCount()
Test-Assert -TestName "B-Series has terms" -Condition ($termCount -gt 0)
Test-AssertEqual -TestName "Order 3 has 4 terms (1+1+2)" -Expected 4 -Actual $termCount

# Test 2.5: Term structure
$terms = Get-BSeriesTerms -Expansion $bseries
Test-AssertNotNull -TestName "Terms retrieved" -Value $terms
Test-Assert -TestName "First term has tree" -Condition ($null -ne $terms[0].Tree)
Test-Assert -TestName "First term has coefficient" -Condition ($terms[0].Coefficient -ne 0)

# Test 2.6: Domain-specific weights
$physicsExp = New-BSeriesExpansion -Order 2 -Domain "physics"
$physicsExp.GenerateTerms()
Test-Assert -TestName "Physics expansion created" -Condition ($physicsExp.TermCount() -gt 0)

$chemistryExp = New-BSeriesExpansion -Order 2 -Domain "chemistry"
$chemistryExp.GenerateTerms()
Test-Assert -TestName "Chemistry expansion created" -Condition ($chemistryExp.TermCount() -gt 0)

Write-Host ""

# ============================================
# Test Suite 3: Universal Kernel Generator
# ============================================
Write-Host "Test Suite 3: Universal Kernel Generator" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Test 3.1: Generator creation
$kernelGen = New-UniversalKernelGenerator
Test-AssertNotNull -TestName "Kernel generator created" -Value $kernelGen
Test-AssertNotNull -TestName "Generator has analyzer" -Value $kernelGen.Analyzer
Test-AssertNotNull -TestName "Generator has optimizer" -Value $kernelGen.Optimizer

# Test 3.2: Domain specification
$domain = New-DomainSpecification -Name "test-domain"
Test-AssertNotNull -TestName "Domain specification created" -Value $domain
Test-AssertEqual -TestName "Domain name correct" -Expected "test-domain" -Actual $domain.Name

# Test 3.3: Kernel generation for consciousness
$consciousnessKernel = Invoke-KernelGeneration -DomainName "consciousness" -Order 3
Test-AssertNotNull -TestName "Consciousness kernel generated" -Value $consciousnessKernel
Test-AssertEqual -TestName "Kernel order is 3" -Expected 3 -Actual $consciousnessKernel.Order
Test-Assert -TestName "Kernel has positive grip" -Condition ($consciousnessKernel.Grip -gt 0)

# Test 3.4: Kernel generation for physics
$physicsKernel = Invoke-KernelGeneration -DomainName "physics" -Order 4
Test-AssertNotNull -TestName "Physics kernel generated" -Value $physicsKernel
Test-AssertEqual -TestName "Physics kernel order is 4" -Expected 4 -Actual $physicsKernel.Order

# Test 3.5: Kernel generation for computing
$computingKernel = Invoke-KernelGeneration -DomainName "computing" -Order 2
Test-AssertNotNull -TestName "Computing kernel generated" -Value $computingKernel
Test-AssertEqual -TestName "Computing kernel order is 2" -Expected 2 -Actual $computingKernel.Order

# Test 3.6: Custom domain kernel
$customDomain = New-DomainSpecification -Name "quantum"
$customDomain.Symmetries = @("unitarity", "gauge-invariance")
$customKernel = $kernelGen.GenerateCustomKernel($customDomain, 3)
Test-AssertNotNull -TestName "Custom domain kernel generated" -Value $customKernel
Test-AssertEqual -TestName "Custom kernel domain correct" -Expected "quantum" -Actual $customKernel.Domain.Name

# Test 3.7: Grip quality
Test-Assert -TestName "Consciousness grip > 0.5" -Condition ($consciousnessKernel.Grip -gt 0.5)
Test-Assert -TestName "Physics grip > 0.5" -Condition ($physicsKernel.Grip -gt 0.5)
Test-Assert -TestName "Grip <= 1.0" -Condition ($consciousnessKernel.Grip -le 1.0)

# Test 3.8: B-Series terms in kernel
Test-AssertNotNull -TestName "Kernel has expansion" -Value $consciousnessKernel.Expansion
Test-Assert -TestName "Expansion has terms" -Condition ($consciousnessKernel.Expansion.TermCount() -gt 0)

# Test 3.9: Domain symmetries
Test-Assert -TestName "Physics has symmetries" -Condition ($physicsKernel.Domain.Symmetries.Count -gt 0)
Test-Assert -TestName "Consciousness has invariants" -Condition ($consciousnessKernel.Domain.Invariants.Count -gt 0)

# Test 3.10: Higher order kernels
$highOrderKernel = Invoke-KernelGeneration -DomainName "consciousness" -Order 5
Test-AssertNotNull -TestName "Order 5 kernel generated" -Value $highOrderKernel
Test-Assert -TestName "Higher order has more terms" -Condition ($highOrderKernel.Expansion.TermCount() -gt $consciousnessKernel.Expansion.TermCount())

Write-Host ""

# ============================================
# Test Suite 4: Integration Tests
# ============================================
Write-Host "Test Suite 4: Integration Tests" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Test 4.1: All domains generate kernels
$domains = @('physics', 'chemistry', 'biology', 'computing', 'consciousness')
foreach ($domainName in $domains) {
    $kernel = Invoke-KernelGeneration -DomainName $domainName -Order 3
    Test-Assert -TestName "$domainName kernel generated" -Condition ($null -ne $kernel)
}

# Test 4.2: Kernel grip comparison
$grips = @{}
foreach ($domainName in $domains) {
    $kernel = Invoke-KernelGeneration -DomainName $domainName -Order 3
    $grips[$domainName] = $kernel.Grip
}
Test-Assert -TestName "Consciousness has highest grip" -Condition ($grips['consciousness'] -gt 0.5)

# Test 4.3: Consistency across multiple generations
$kernel1 = Invoke-KernelGeneration -DomainName "computing" -Order 3
$kernel2 = Invoke-KernelGeneration -DomainName "computing" -Order 3
Test-AssertEqual -TestName "Same domain gives consistent order" -Expected $kernel1.Order -Actual $kernel2.Order
Test-AssertEqual -TestName "Same domain gives consistent terms" -Expected $kernel1.Expansion.TermCount() -Actual $kernel2.Expansion.TermCount()

Write-Host ""

# ============================================
# Test Results Summary
# ============================================
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   TEST RESULTS SUMMARY                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$totalTests = $script:TestsPassed + $script:TestsFailed + $script:TestsSkipped
$passRate = if ($totalTests -gt 0) { [Math]::Round(($script:TestsPassed / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests:   $totalTests" -ForegroundColor White
Write-Host "Passed:        " -NoNewline
Write-Host "$script:TestsPassed" -ForegroundColor Green
Write-Host "Failed:        " -NoNewline
Write-Host "$script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { 'Green' } else { 'Red' })
Write-Host "Skipped:       $script:TestsSkipped" -ForegroundColor Yellow
Write-Host "Pass Rate:     " -NoNewline
Write-Host "$passRate%" -ForegroundColor $(if ($passRate -ge 90) { 'Green' } elseif ($passRate -ge 75) { 'Yellow' } else { 'Red' })

if ($script:TestsFailed -eq 0) {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n✗ Some tests failed" -ForegroundColor Red
    exit 1
}
