<#
.SYNOPSIS
    Universal Kernel Generator - Demonstration Script
    
.DESCRIPTION
    Demonstrates the Universal Kernel Generator by creating domain-specific
    kernels for physics, chemistry, biology, computing, and consciousness.
    Shows how B-Series expansions with elementary differentials produce
    optimal kernels with maximum "grip" on each domain.
#>

# Import the kernel generator modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptPath/../KernelGenerator/ElementaryDifferentials.psm1" -Force
Import-Module "$scriptPath/../KernelGenerator/BSeriesExpansion.psm1" -Force
Import-Module "$scriptPath/../KernelGenerator/UniversalKernelGenerator.psm1" -Force

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║         UNIVERSAL KERNEL GENERATOR DEMONSTRATION                  ║
║                                                                   ║
║  Generating optimal kernels via B-Series expansions              ║
║  Elementary Differentials as Rooted Trees (OEIS A000081)         ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ========================================
# Example 1: Elementary Differentials
# ========================================
Write-Host "`n═══ Example 1: Elementary Differentials (Rooted Trees) ═══" -ForegroundColor Green
Write-Host "Generating elementary differentials up to order 5...`n"

$generator = New-ElementaryDifferentialGenerator

for ($order = 1; $order -le 5; $order++) {
    $trees = $generator.GenerateTrees($order)
    Write-Host "Order $order : " -NoNewline -ForegroundColor Yellow
    Write-Host "$($trees.Count) trees" -ForegroundColor White
    
    foreach ($tree in $trees) {
        Write-Host "  • $($tree.Structure)" -ForegroundColor Gray
        if ($tree.Description) {
            Write-Host "    ($($tree.Description))" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

# Show A000081 sequence
Write-Host "`nA000081 Sequence (Rooted Tree Counts):" -ForegroundColor Yellow
$sequence = Get-A000081Sequence -Terms 10
Write-Host "  $($sequence -join ', ')" -ForegroundColor White
Write-Host "  (Expected: 1, 1, 2, 4, 9, 20, 48, 115, 286, 719, ...)`n"

# ========================================
# Example 2: B-Series Expansion
# ========================================
Write-Host "`n═══ Example 2: B-Series Expansion for Consciousness ═══" -ForegroundColor Green

$bseries = New-BSeriesExpansion -Order 4 -Domain "consciousness"
$bseries.GenerateTerms()

Write-Host "Created B-Series with $($bseries.TermCount()) terms"
Write-Host "Total combined order: $($bseries.TotalOrder())`n"

Show-BSeriesExpansion -Expansion $bseries

# ========================================
# Example 3: Generate Consciousness Kernel
# ========================================
Write-Host "`n`n═══ Example 3: Consciousness Kernel (Echo Trees) ═══" -ForegroundColor Green

$consciousnessKernel = Invoke-KernelGeneration -DomainName "consciousness" -Order 5
Show-GeneratedKernel -Kernel $consciousnessKernel

# ========================================
# Example 4: Generate Physics Kernel
# ========================================
Write-Host "`n`n═══ Example 4: Physics Kernel (Hamiltonian Trees) ═══" -ForegroundColor Green

$physicsKernel = Invoke-KernelGeneration -DomainName "physics" -Order 4
Show-GeneratedKernel -Kernel $physicsKernel

# ========================================
# Example 5: Generate Chemistry Kernel
# ========================================
Write-Host "`n`n═══ Example 5: Chemistry Kernel (Reaction Trees) ═══" -ForegroundColor Green

$chemistryKernel = Invoke-KernelGeneration -DomainName "chemistry" -Order 4
Show-GeneratedKernel -Kernel $chemistryKernel

# ========================================
# Example 6: Generate Computing Kernel
# ========================================
Write-Host "`n`n═══ Example 6: Computing Kernel (Recursion Trees) ═══" -ForegroundColor Green

$computingKernel = Invoke-KernelGeneration -DomainName "computing" -Order 3
Show-GeneratedKernel -Kernel $computingKernel

# ========================================
# Example 7: Generate Biology Kernel
# ========================================
Write-Host "`n`n═══ Example 7: Biology Kernel (Metabolic Trees) ═══" -ForegroundColor Green

$biologyKernel = Invoke-KernelGeneration -DomainName "biology" -Order 4
Show-GeneratedKernel -Kernel $biologyKernel

# ========================================
# Example 8: Custom Domain Kernel
# ========================================
Write-Host "`n`n═══ Example 8: Custom Domain - Quantum Mechanics ═══" -ForegroundColor Green

$quantumDomain = New-DomainSpecification -Name "quantum"
$quantumDomain.TopologyType = "hilbert-space"
$quantumDomain.Symmetries = @("unitarity", "gauge-invariance", "parity")
$quantumDomain.Invariants = @("probability-conservation", "hermiticity")

$kernelGen = New-UniversalKernelGenerator
$quantumKernel = $kernelGen.GenerateCustomKernel($quantumDomain, 4)
Show-GeneratedKernel -Kernel $quantumKernel

# ========================================
# Example 9: Butcher Tableaux
# ========================================
Write-Host "`n`n═══ Example 9: Butcher Tableaux for Standard Methods ═══" -ForegroundColor Green

Write-Host "`nEuler Method (Order 1):" -ForegroundColor Yellow
$euler = New-ButcherTableau -Order 1 -MethodName "Euler"
Write-Host "  Stages: $($euler.Stages)"
Write-Host "  B weights: $($euler.B -join ', ')"

Write-Host "`nMidpoint Method (Order 2):" -ForegroundColor Yellow
$midpoint = New-ButcherTableau -Order 2 -MethodName "Midpoint"
Write-Host "  Stages: $($midpoint.Stages)"
Write-Host "  B weights: $($midpoint.B -join ', ')"

Write-Host "`nRunge-Kutta 4 (Order 4):" -ForegroundColor Yellow
$rk4 = New-ButcherTableau -Order 4 -MethodName "RK4"
Write-Host "  Stages: $($rk4.Stages)"
Write-Host "  B weights: $($rk4.B -join ', ')"

# ========================================
# Example 10: Grip Quality Comparison
# ========================================
Write-Host "`n`n═══ Example 10: Grip Quality Across Domains ═══" -ForegroundColor Green
Write-Host "Comparing kernel-domain fit quality...`n"

$domains = @('physics', 'chemistry', 'biology', 'computing', 'consciousness')
$order = 4

$results = @()
foreach ($domain in $domains) {
    $kernel = Invoke-KernelGeneration -DomainName $domain -Order $order
    $gripPercent = [Math]::Round($kernel.Grip * 100, 2)
    
    $results += [PSCustomObject]@{
        Domain = $domain
        Order = $order
        Terms = $kernel.Expansion.TermCount()
        Grip = "$gripPercent%"
        Topology = $kernel.Domain.TopologyType
    }
}

$results | Format-Table -AutoSize

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    DEMONSTRATION COMPLETE                         ║
║                                                                   ║
║  The Universal Kernel Generator successfully produced optimal     ║
║  kernels for multiple domains using B-Series expansions with      ║
║  elementary differentials (rooted trees).                         ║
║                                                                   ║
║  Key Insight: All kernels are B-Series expansions where each      ║
║  term corresponds to a rooted tree, and the "grip" measures       ║
║  how well the kernel's differential structure matches the         ║
║  domain's natural geometry.                                       ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
