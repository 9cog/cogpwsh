<#
.SYNOPSIS
    Phase 4 PLN Infrastructure Tests
.DESCRIPTION
    Tests for PLN Extended Truth Values and Deduction Rules.
#>

Import-Module (Join-Path $PSScriptRoot ".." "OpenCog.psd1") -Force

$script:TestsPassed = 0
$script:TestsFailed = 0

function Start-TestSection {
    param([string]$Name)
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
}

function Test-Assertion {
    param([string]$Name, [bool]$Condition, [string]$FailureMessage = "")
    if ($Condition) {
        Write-Host "  ✓ $Name" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "  ✗ $Name" -ForegroundColor Red
        if ($FailureMessage) { Write-Host "    $FailureMessage" -ForegroundColor Yellow }
        $script:TestsFailed++
    }
}

function Assert-Near {
    param([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance = 0.01)
    $diff = [Math]::Abs($Actual - $Expected)
    Test-Assertion -Name $Name -Condition ($diff -le $Tolerance) `
        -FailureMessage "Expected ~$Expected, got $Actual (diff=$([Math]::Round($diff,4)))"
}

function Test-TypeName {
    param([object]$Obj, [string]$TypeName)
    return ($null -ne $Obj) -and ($Obj.GetType().Name -eq $TypeName)
}

# --- SimpleTruthValue ---
Start-TestSection "SimpleTruthValue"

$stv = New-SimpleTruthValue -Strength 0.8 -Confidence 0.9
Test-Assertion "Created SimpleTruthValue"       ($null -ne $stv)
Test-Assertion "Is SimpleTruthValue"            (Test-TypeName $stv 'SimpleTruthValue')
Assert-Near    "Strength is 0.8"                $stv.Strength   0.8
Assert-Near    "Confidence is 0.9"              $stv.Confidence 0.9
Test-Assertion "ToString not empty"             ($stv.ToString().Length -gt 0)

$clamped = New-SimpleTruthValue -Strength 1.5 -Confidence -0.3
Assert-Near "Strength clamped to 1.0"           $clamped.Strength    1.0
Assert-Near "Confidence clamped to 0.0"         $clamped.Confidence  0.0

$tv1 = New-SimpleTruthValue -Strength 0.8 -Confidence 0.7
$tv2 = New-SimpleTruthValue -Strength 0.6 -Confidence 0.9
$rev = Invoke-TVRevision -TV1 $tv1 -TV2 $tv2
Test-Assertion "Revision is SimpleTruthValue"   (Test-TypeName $rev 'SimpleTruthValue')
Test-Assertion "Revised conf >= max input"      ($rev.Confidence -ge [Math]::Max($tv1.Confidence, $tv2.Confidence) - 0.001)
Test-Assertion "Revised strength in [0,1]"      ($rev.Strength -ge 0.0 -and $rev.Strength -le 1.0)

$simple = $stv.ToSimple()
Test-Assertion "ToSimple is SimpleTruthValue"   (Test-TypeName $simple 'SimpleTruthValue')
Assert-Near    "ToSimple preserves strength"    $simple.Strength 0.8

# --- CountTruthValue ---
Start-TestSection "CountTruthValue"

$ctv = New-CountTruthValue -Count 100 -Confidence 0.95
Test-Assertion "Created CountTruthValue"        ($null -ne $ctv)
Test-Assertion "Is CountTruthValue"             (Test-TypeName $ctv 'CountTruthValue')
Assert-Near    "Count is 100"                   $ctv.Count      100.0
Assert-Near    "Confidence is 0.95"             $ctv.Confidence 0.95
Test-Assertion "ToString not empty"             ($ctv.ToString().Length -gt 0)

$ctvSimple = $ctv.ToSimple()
Test-Assertion "ToSimple is SimpleTruthValue"   (Test-TypeName $ctvSimple 'SimpleTruthValue')
# With k=800, count=100 gives s=100/900≈0.11; count=8000 gives 8000/8800≈0.91
$ctvLarge  = New-CountTruthValue -Count 8000 -Confidence 0.95
Test-Assertion "Large count (8000) -> high strength" ($ctvLarge.ToSimple().Strength -gt 0.9)

$ctv0 = New-CountTruthValue -Count 0 -Confidence 0.5
Assert-Near    "Zero count -> zero strength"    ($ctv0.ToSimple().Strength) 0.0

try {
    New-CountTruthValue -Count -5 -Confidence 0.5
    Test-Assertion "Negative count should throw" $false
} catch {
    Test-Assertion "Negative count throws" $true
}

# --- IndefiniteTruthValue ---
Start-TestSection "IndefiniteTruthValue"

$itv = New-IndefiniteTruthValue -L 0.6 -U 0.9 -Confidence 0.85
Test-Assertion "Created IndefiniteTruthValue"   ($null -ne $itv)
Test-Assertion "Is IndefiniteTruthValue"        (Test-TypeName $itv 'IndefiniteTruthValue')
Assert-Near    "L is 0.6"                       $itv.L          0.6
Assert-Near    "U is 0.9"                       $itv.U          0.9
Assert-Near    "Confidence is 0.85"             $itv.Confidence 0.85
Assert-Near    "Mean is 0.75"                   $itv.Mean()     0.75
Assert-Near    "Width is 0.3"                   $itv.Width()    0.3
Test-Assertion "ToString not empty"             ($itv.ToString().Length -gt 0)

$itvSimple = $itv.ToSimple()
Assert-Near    "ToSimple strength = mean"       $itvSimple.Strength 0.75

try {
    New-IndefiniteTruthValue -L 0.9 -U 0.3 -Confidence 0.8
    Test-Assertion "L>U should throw" $false
} catch {
    Test-Assertion "L>U throws" $true
}

$itv2 = New-IndefiniteTruthValue -L 0.4 -U 0.8
Assert-Near "Default confidence is 0.9"         $itv2.Confidence 0.9

# --- FuzzyTruthValue ---
Start-TestSection "FuzzyTruthValue"

$ftv = New-FuzzyTruthValue -Mean 0.75 -StdDev 0.1
Test-Assertion "Created FuzzyTruthValue"        ($null -ne $ftv)
Test-Assertion "Is FuzzyTruthValue"             (Test-TypeName $ftv 'FuzzyTruthValue')
Assert-Near    "Mean is 0.75"                   $ftv.Mean   0.75
Assert-Near    "StdDev is 0.1"                  $ftv.StdDev 0.1
Test-Assertion "Confidence in [0,1]"            ($ftv.Confidence() -ge 0.0 -and $ftv.Confidence() -le 1.0)
Test-Assertion "ToString not empty"             ($ftv.ToString().Length -gt 0)

$ftvHigh = New-FuzzyTruthValue -Mean 0.5 -StdDev 0.6
Test-Assertion "High stddev -> low confidence"  ($ftvHigh.Confidence() -lt 0.2)

$ftvZero = New-FuzzyTruthValue -Mean 0.8
Assert-Near    "Zero stddev -> confidence 1.0"  ($ftvZero.Confidence()) 1.0

$ftvA = New-FuzzyTruthValue -Mean 0.8 -StdDev 0.05
$ftvB = New-FuzzyTruthValue -Mean 0.6 -StdDev 0.05
$ftvT = $ftvA.GetType()
$fAnd = $ftvT::FuzzyAnd($ftvA, $ftvB)
Assert-Near "FuzzyAnd = min(0.8,0.6)=0.6"      $fAnd.Mean 0.6
$fOr  = $ftvT::FuzzyOr($ftvA, $ftvB)
Assert-Near "FuzzyOr = max(0.8,0.6)=0.8"       $fOr.Mean  0.8
$fNot = $ftvT::FuzzyNot($ftvA)
Assert-Near "FuzzyNot(0.8) = 0.2"              $fNot.Mean 0.2

# --- ProbabilisticTruthValue ---
Start-TestSection "ProbabilisticTruthValue"

$ptv = New-ProbabilisticTruthValue -Count 50 -Probability 0.7
Test-Assertion "Created ProbabilisticTruthValue"  ($null -ne $ptv)
Test-Assertion "Is ProbabilisticTruthValue"       (Test-TypeName $ptv 'ProbabilisticTruthValue')
Assert-Near    "Count is 50"                      $ptv.Count       50.0
Assert-Near    "Probability is 0.7"               $ptv.Probability 0.7
Test-Assertion "Confidence in (0,1)"              ($ptv.Confidence() -gt 0.0 -and $ptv.Confidence() -lt 1.0)
Test-Assertion "ToString not empty"               ($ptv.ToString().Length -gt 0)

$ptvSimple = $ptv.ToSimple()
Assert-Near "ToSimple strength = probability"     $ptvSimple.Strength 0.7

$ptvLarge = New-ProbabilisticTruthValue -Count 1000 -Probability 0.9
Test-Assertion "Large count -> high confidence"   ($ptvLarge.Confidence() -gt 0.99)

$ptv0 = New-ProbabilisticTruthValue -Count 0 -Probability 0.5
Assert-Near "Zero count -> zero confidence"       ($ptv0.Confidence()) 0.0

# --- ConvertTo-SimpleTruthValue ---
Start-TestSection "ConvertTo-SimpleTruthValue"

$ctv2  = New-CountTruthValue -Count 200 -Confidence 0.9
$conv  = ConvertTo-SimpleTruthValue -TruthValue $ctv2
Test-Assertion "CountTV converts"                 (Test-TypeName $conv 'SimpleTruthValue')

$stv2  = New-SimpleTruthValue -Strength 0.7 -Confidence 0.8
$conv2 = ConvertTo-SimpleTruthValue -TruthValue $stv2
Test-Assertion "SimpleTruthValue passes through"  (Test-TypeName $conv2 'SimpleTruthValue')
Assert-Near    "Strength preserved"               $conv2.Strength 0.7

# --- PLN Deduction ---
Start-TestSection "Invoke-PLNDeduction"

$ded = Invoke-PLNDeduction -StrengthAB 0.9 -ConfidenceAB 0.9 -StrengthBC 0.95 -ConfidenceBC 0.85
Test-Assertion "Returns hashtable"                ($null -ne $ded)
Test-Assertion "Rule = Deduction"                 ($ded.Rule -eq 'Deduction')
Test-Assertion "Has TruthValue"                   ($null -ne $ded.TruthValue)
Test-Assertion "TV is SimpleTruthValue"           (Test-TypeName $ded.TruthValue 'SimpleTruthValue')
Test-Assertion "Strength in [0,1]"                ($ded.TruthValue.Strength -ge 0.0 -and $ded.TruthValue.Strength -le 1.0)
Test-Assertion "Confidence discounted"            ($ded.TruthValue.Confidence -le 0.9)
Test-Assertion "Has 2 Premises"                   ($ded.Premises.Count -eq 2)
Test-Assertion "Conclusion = A->C"                ($ded.Conclusion -eq 'A→C')

$ded1 = Invoke-PLNDeduction -StrengthAB 1.0 -ConfidenceAB 1.0 -StrengthBC 1.0 -ConfidenceBC 1.0
Assert-Near    "Deduction(1,1,1,1) strength=1"    $ded1.TruthValue.Strength 1.0

# sAB=0, sB=0.5, sC=0.5, sBC=0.8 => sAC = (0.5-0.5*0.8)/0.5 = 0.2
$ded2 = Invoke-PLNDeduction -StrengthAB 0.0 -ConfidenceAB 0.8 -StrengthBC 0.8 -ConfidenceBC 0.8 `
    -StrengthB 0.5 -StrengthC 0.5
Assert-Near    "Deduction(sAB=0) ~0.2"            $ded2.TruthValue.Strength 0.2 0.05

# --- Modus Ponens ---
Start-TestSection "Invoke-ModusPonens"

$mp = Invoke-ModusPonens -StrengthImplication 0.9 -ConfidenceImplication 0.8 `
    -StrengthA 0.95 -ConfidenceA 0.9
Test-Assertion "Returns hashtable"                ($null -ne $mp)
Test-Assertion "Rule = ModusPonens"               ($mp.Rule -eq 'ModusPonens')
Test-Assertion "Has TruthValue"                   ($null -ne $mp.TruthValue)
Test-Assertion "Strength in [0,1]"                ($mp.TruthValue.Strength -ge 0.0 -and $mp.TruthValue.Strength -le 1.0)
Assert-Near    "Strength = 0.9*0.95 = 0.855"      $mp.TruthValue.Strength 0.855

$mp1 = Invoke-ModusPonens -StrengthImplication 1.0 -ConfidenceImplication 1.0 `
    -StrengthA 1.0 -ConfidenceA 1.0
Assert-Near    "ModusPonens(1,1) strength=1"       $mp1.TruthValue.Strength 1.0

# --- Modus Tollens ---
Start-TestSection "Invoke-ModusTollens"

$mt = Invoke-ModusTollens -StrengthImplication 0.9 -ConfidenceImplication 0.8 `
    -StrengthNotB 0.9 -ConfidenceNotB 0.85
Test-Assertion "Returns hashtable"                ($null -ne $mt)
Test-Assertion "Rule = ModusTollens"              ($mt.Rule -eq 'ModusTollens')
Test-Assertion "Has TruthValue"                   ($null -ne $mt.TruthValue)
Test-Assertion "Conclusion = negA"                ($mt.Conclusion -eq '¬A')
Test-Assertion "Strength in [0,1]"                ($mt.TruthValue.Strength -ge 0.0 -and $mt.TruthValue.Strength -le 1.0)

$mt2 = Invoke-ModusTollens -StrengthImplication 0.5 -ConfidenceImplication 0.8 `
    -StrengthNotB 0.9 -ConfidenceNotB 0.9
Test-Assertion "Weak impl gives some negA"        ($mt2.TruthValue.Strength -gt 0.0)

# --- Contraposition ---
Start-TestSection "Invoke-PLNContraposition"

$contra = Invoke-PLNContraposition -StrengthAB 0.85 -ConfidenceAB 0.9
Test-Assertion "Returns hashtable"                ($null -ne $contra)
Test-Assertion "Rule = Contraposition"            ($contra.Rule -eq 'Contraposition')
Test-Assertion "Conclusion = negB->negA"          ($contra.Conclusion -eq '¬B→¬A')
Test-Assertion "Strength in [0,1]"                ($contra.TruthValue.Strength -ge 0.0 -and $contra.TruthValue.Strength -le 1.0)
Test-Assertion "Confidence discounted"            ($contra.TruthValue.Confidence -lt 0.9)

$contra2 = Invoke-PLNContraposition -StrengthAB 0.8 -ConfidenceAB 1.0 -StrengthA 0.5 -StrengthB 0.5
Assert-Near    "Contraposition(sAB=0.8) ~0.2"     $contra2.TruthValue.Strength 0.2 0.05

# --- Hypothetical Syllogism ---
Start-TestSection "Invoke-HypotheticalSyllogism"

$hs = Invoke-HypotheticalSyllogism -StrengthAB 0.9 -ConfidenceAB 0.8 `
    -StrengthBC 0.85 -ConfidenceBC 0.75
Test-Assertion "Returns hashtable"                ($null -ne $hs)
Test-Assertion "Rule = HypotheticalSyllogism"     ($hs.Rule -eq 'HypotheticalSyllogism')
Test-Assertion "Has TruthValue"                   ($null -ne $hs.TruthValue)
Test-Assertion "Conclusion = A->C"                ($hs.Conclusion -eq 'A→C')

# --- AtomSpace Deduction ---
Start-TestSection "Invoke-AtomSpaceDeduction"

$kb     = New-AtomSpace
$cat    = $kb.AddAtom((New-ConceptNode "Cat"))
$animal = $kb.AddAtom((New-ConceptNode "Animal"))
$living = $kb.AddAtom((New-ConceptNode "LivingThing"))

$linkCA = $kb.AddAtom((New-InheritanceLink -Child $cat    -Parent $animal -Strength 0.9  -Confidence 0.9))
$linkAL = $kb.AddAtom((New-InheritanceLink -Child $animal -Parent $living -Strength 0.95 -Confidence 0.85))

$res = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $linkCA -LinkBC $linkAL -AddToAtomSpace
Test-Assertion "Returns result"                   ($null -ne $res)
Test-Assertion "Has Conclusion atom"              ($null -ne $res.Conclusion)
Test-Assertion "Conclusion is InheritanceLink"    ($res.Conclusion.Type -eq 'InheritanceLink')
Test-Assertion "Conclusion A = Cat"               ($res.Conclusion.GetOutgoingAtom(0).Name -eq 'Cat')
Test-Assertion "Conclusion C = LivingThing"       ($res.Conclusion.GetOutgoingAtom(1).Name -eq 'LivingThing')
Test-Assertion "TV is SimpleTruthValue"           (Test-TypeName $res.TruthValue 'SimpleTruthValue')
Test-Assertion "AtomSpace has 3+ InheritanceLinks" ($kb.GetAtomsByType('InheritanceLink').Count -ge 3)

try {
    Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $null -LinkBC $linkAL
    Test-Assertion "Null LinkAB should throw" $false
} catch {
    Test-Assertion "Null LinkAB throws" $true
}

# --- Integration ---
Start-TestSection "Integration: Multi-Step Deduction Chain"

$kb2     = New-AtomSpace
$catN    = $kb2.AddAtom((New-ConceptNode "Cat"))
$animalN = $kb2.AddAtom((New-ConceptNode "Animal"))
$livingN = $kb2.AddAtom((New-ConceptNode "LivingThing"))
$orgN    = $kb2.AddAtom((New-ConceptNode "Organism"))

$l1 = $kb2.AddAtom((New-InheritanceLink -Child $catN    -Parent $animalN -Strength 0.9  -Confidence 0.9))
$l2 = $kb2.AddAtom((New-InheritanceLink -Child $animalN -Parent $livingN -Strength 0.95 -Confidence 0.85))
$l3 = $kb2.AddAtom((New-InheritanceLink -Child $livingN -Parent $orgN    -Strength 0.98 -Confidence 0.9))

$r1 = Invoke-AtomSpaceDeduction -AtomSpace $kb2 -LinkAB $l1 -LinkBC $l2 -AddToAtomSpace
Test-Assertion "Step 1: Cat->LivingThing created" ($null -ne $r1.Conclusion)

$r2 = Invoke-AtomSpaceDeduction -AtomSpace $kb2 -LinkAB $r1.Conclusion -LinkBC $l3 -AddToAtomSpace
Test-Assertion "Step 2: Cat->Organism created"    ($null -ne $r2.Conclusion)
Test-Assertion "Final link target = Organism"     ($r2.Conclusion.GetOutgoingAtom(1).Name -eq 'Organism')
Test-Assertion "Confidence degrades with depth"   ($r2.TruthValue.Confidence -lt $l1.GetTruthValue().Confidence)

# ---------------------------------------------------------------------------
$total = $script:TestsPassed + $script:TestsFailed
Write-Host "`n=== Phase 4 PLN Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests : $total"
Write-Host "Passed      : $script:TestsPassed" -ForegroundColor Green
if ($script:TestsFailed -gt 0) {
    Write-Host "Failed      : $script:TestsFailed" -ForegroundColor Red
    Write-Host "`n✗ Some tests failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Failed      : 0" -ForegroundColor Green
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
}
