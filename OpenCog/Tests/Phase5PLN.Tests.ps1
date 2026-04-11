<#
.SYNOPSIS
    Phase 5 Advanced PLN Reasoning Tests
.DESCRIPTION
    Tests for Induction/Abduction, Higher-Order Inference, and Temporal Reasoning.
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
    param([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance = 0.02)
    $diff = [Math]::Abs($Actual - $Expected)
    Test-Assertion -Name $Name -Condition ($diff -le $Tolerance) `
        -FailureMessage "Expected ~$Expected, got $Actual (diff=$([Math]::Round($diff,4)))"
}

function Test-TypeName {
    param([object]$Obj, [string]$TypeName)
    return ($null -ne $Obj) -and ($Obj.GetType().Name -eq $TypeName)
}

function Assert-InRange {
    param([string]$Name, [double]$Value, [double]$Min = 0.0, [double]$Max = 1.0)
    Test-Assertion -Name $Name -Condition ($Value -ge $Min -and $Value -le $Max) `
        -FailureMessage "$Value not in [$Min, $Max]"
}

# ===========================================================================
# INDUCTION & ABDUCTION
# ===========================================================================

Start-TestSection "Invoke-PLNInduction"

$ind = Invoke-PLNInduction -StrengthAC 0.95 -ConfidenceAC 0.8 `
    -StrengthBC 0.95 -ConfidenceBC 0.8
Test-Assertion "Returns hashtable"               ($null -ne $ind)
Test-Assertion "Rule = Induction"                ($ind.Rule -eq 'Induction')
Test-Assertion "Conclusion = A→B"                ($ind.Conclusion -eq 'A→B')
Test-Assertion "Has TruthValue"                  ($null -ne $ind.TruthValue)
Assert-InRange "Strength in [0,1]"               $ind.TruthValue.Strength
# When sAC = sBC, ratio = 1.0 (clamped to 1)
Assert-Near    "Equal strengths -> s=1"          $ind.TruthValue.Strength 1.0 0.01
Test-Assertion "Confidence discounted"           ($ind.TruthValue.Confidence -lt 0.8)
Test-Assertion "Has 2 premises"                  ($ind.Premises.Count -eq 2)

# sAC=0.6, sBC=0.8 -> sAB = 0.6/0.8 = 0.75
$ind2 = Invoke-PLNInduction -StrengthAC 0.6 -ConfidenceAC 0.9 `
    -StrengthBC 0.8 -ConfidenceBC 0.7
Assert-Near    "sAC/sBC = 0.75"                  $ind2.TruthValue.Strength 0.75 0.02

# Zero BC strength -> strength clamped to 1
$indZero = Invoke-PLNInduction -StrengthAC 0.5 -ConfidenceAC 0.5 `
    -StrengthBC 0.0 -ConfidenceBC 0.5
Assert-Near    "Zero sBC -> strength=1"          $indZero.TruthValue.Strength 1.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-PLNAbduction"

$abd = Invoke-PLNAbduction -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthAC 0.9 -ConfidenceAC 0.8
Test-Assertion "Returns hashtable"               ($null -ne $abd)
Test-Assertion "Rule = Abduction"                ($abd.Rule -eq 'Abduction')
Test-Assertion "Conclusion = B→C"                ($abd.Conclusion -eq 'B→C')
Assert-InRange "Strength in [0,1]"               $abd.TruthValue.Strength
# Equal sAB = sAC = 0.9 -> sBC = 0.9/0.9 = 1.0
Assert-Near    "Equal -> s=1"                    $abd.TruthValue.Strength 1.0 0.01

# sAC=0.7, sAB=0.9 -> sBC = 0.7/0.9 ≈ 0.778
$abd2 = Invoke-PLNAbduction -StrengthAB 0.9 -ConfidenceAB 0.8 `
    -StrengthAC 0.7 -ConfidenceAC 0.75
Assert-Near    "0.7/0.9 ≈ 0.778"                 $abd2.TruthValue.Strength 0.778 0.02
Test-Assertion "Confidence discounted"           ($abd2.TruthValue.Confidence -lt 0.75)

# Zero AB strength -> strength clamped to 1
$abdZero = Invoke-PLNAbduction -StrengthAB 0.0 -ConfidenceAB 0.5 `
    -StrengthAC 0.5 -ConfidenceAC 0.5
Assert-Near    "Zero sAB -> strength=1"          $abdZero.TruthValue.Strength 1.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-PLNInversion"

$inv = Invoke-PLNInversion -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthA 0.5 -StrengthB 0.5
Test-Assertion "Returns hashtable"               ($null -ne $inv)
Test-Assertion "Rule = Inversion"                ($inv.Rule -eq 'Inversion')
Test-Assertion "Conclusion = B→A"                ($inv.Conclusion -eq 'B→A')
# Equal priors: s(B→A) = sAB * sA / sB = 0.9 * 0.5 / 0.5 = 0.9
Assert-Near    "Equal priors -> same strength"   $inv.TruthValue.Strength 0.9 0.01
Test-Assertion "Confidence discounted"           ($inv.TruthValue.Confidence -lt 0.85)

# sA > sB: sBA = sAB * sA / sB (clamped to 1)
$inv2 = Invoke-PLNInversion -StrengthAB 0.8 -ConfidenceAB 0.7 `
    -StrengthA 0.7 -StrengthB 0.4
$expectedBA = [Math]::Min(1.0, 0.8 * 0.7 / 0.4)  # 1.4 clamped to 1
Assert-Near    "High A prior -> s clamped to 1"  $inv2.TruthValue.Strength 1.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-PLNAndIntroduction"

$and = Invoke-PLNAndIntroduction -StrengthA 0.9 -ConfidenceA 0.8 `
    -StrengthB 0.8 -ConfidenceB 0.75
Test-Assertion "Returns hashtable"               ($null -ne $and)
Test-Assertion "Rule = AndIntroduction"          ($and.Rule -eq 'AndIntroduction')
Test-Assertion "Conclusion = A∧B"                ($and.Conclusion -eq 'A∧B')
# s = 0.9 * 0.8 = 0.72
Assert-Near    "s = 0.9*0.8 = 0.72"             $and.TruthValue.Strength 0.72 0.01
Test-Assertion "Confidence discounted"           ($and.TruthValue.Confidence -lt 0.75)

$and2 = Invoke-PLNAndIntroduction -StrengthA 1.0 -ConfidenceA 1.0 `
    -StrengthB 1.0 -ConfidenceB 1.0
Assert-Near    "And(1,1) = 1"                    $and2.TruthValue.Strength 1.0 0.01

$and3 = Invoke-PLNAndIntroduction -StrengthA 0.0 -ConfidenceA 0.8 `
    -StrengthB 0.9 -ConfidenceB 0.8
Assert-Near    "And(0,0.9) = 0"                  $and3.TruthValue.Strength 0.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-PLNOrIntroduction"

$or = Invoke-PLNOrIntroduction -StrengthA 0.8 -ConfidenceA 0.9 `
    -StrengthB 0.6 -ConfidenceB 0.7
Test-Assertion "Returns hashtable"               ($null -ne $or)
Test-Assertion "Rule = OrIntroduction"           ($or.Rule -eq 'OrIntroduction')
Test-Assertion "Conclusion = A∨B"                ($or.Conclusion -eq 'A∨B')
# s = 0.8 + 0.6 - 0.48 = 0.92
Assert-Near    "s = 0.8+0.6-0.48 = 0.92"        $or.TruthValue.Strength 0.92 0.01
Test-Assertion "Confidence discounted"           ($or.TruthValue.Confidence -lt 0.7)

$or2 = Invoke-PLNOrIntroduction -StrengthA 0.0 -ConfidenceA 0.8 `
    -StrengthB 0.0 -ConfidenceB 0.8
Assert-Near    "Or(0,0) = 0"                     $or2.TruthValue.Strength 0.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-PLNNotIntroduction"

$not = Invoke-PLNNotIntroduction -Strength 0.7 -Confidence 0.9
Test-Assertion "Returns hashtable"               ($null -ne $not)
Test-Assertion "Rule = NotIntroduction"          ($not.Rule -eq 'NotIntroduction')
Test-Assertion "Conclusion = ¬A"                 ($not.Conclusion -eq '¬A')
Assert-Near    "Not(0.7) = 0.3"                  $not.TruthValue.Strength 0.3 0.01
Assert-Near    "Confidence unchanged"            $not.TruthValue.Confidence 0.9 0.01

$not2 = Invoke-PLNNotIntroduction -Strength 0.0 -Confidence 0.8
Assert-Near    "Not(0) = 1"                      $not2.TruthValue.Strength 1.0 0.01

$not3 = Invoke-PLNNotIntroduction -Strength 1.0 -Confidence 0.8
Assert-Near    "Not(1) = 0"                      $not3.TruthValue.Strength 0.0 0.01

# ===========================================================================
# HIGHER-ORDER INFERENCE
# ===========================================================================

Start-TestSection "Invoke-InheritanceToSimilarity"

$i2s = Invoke-InheritanceToSimilarity -StrengthAB 0.9 -ConfidenceAB 0.8 `
    -StrengthBA 0.85 -ConfidenceBA 0.75
Test-Assertion "Returns hashtable"               ($null -ne $i2s)
Test-Assertion "Rule = InheritanceToSimilarity"  ($i2s.Rule -eq 'InheritanceToSimilarity')
Test-Assertion "Conclusion = A↔B"                ($i2s.Conclusion -eq 'A↔B')
Assert-InRange "Strength in [0,1]"               $i2s.TruthValue.Strength
# Harmonic mean(0.9, 0.85) = 2*0.9*0.85/(0.9+0.85) ≈ 0.8743
Assert-Near    "Harmonic mean ~0.874"            $i2s.TruthValue.Strength 0.874 0.02
Test-Assertion "Confidence discounted"           ($i2s.TruthValue.Confidence -lt 0.75)

$i2sEqual = Invoke-InheritanceToSimilarity -StrengthAB 0.8 -ConfidenceAB 0.8 `
    -StrengthBA 0.8 -ConfidenceBA 0.8
Assert-Near    "Equal -> sim = same"             $i2sEqual.TruthValue.Strength 0.8 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-SimilarityToInheritance"

$s2i = Invoke-SimilarityToInheritance -StrengthSim 0.85 -ConfidenceSim 0.8
Test-Assertion "Returns hashtable"               ($null -ne $s2i)
Test-Assertion "Rule = SimilarityToInheritance"  ($s2i.Rule -eq 'SimilarityToInheritance')
Test-Assertion "Conclusion = A→B"                ($s2i.Conclusion -eq 'A→B')
Assert-InRange "Strength in [0,1]"               $s2i.TruthValue.Strength
# Default sB=0.5: s = 0.85*(1+0.5)/2 = 0.85*0.75 = 0.6375
Assert-Near    "Weighted strength ~0.638"        $s2i.TruthValue.Strength 0.6375 0.02

$s2iFull = Invoke-SimilarityToInheritance -StrengthSim 1.0 -ConfidenceSim 0.9 -StrengthB 1.0
Assert-Near    "Sim(1.0)+sB=1 -> s=1"           $s2iFull.TruthValue.Strength 1.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-IntensionalInheritance"

$ii = Invoke-IntensionalInheritance -OverlapCount 7 -TotalPredicatesA 10 -Confidence 0.9
Test-Assertion "Returns hashtable"               ($null -ne $ii)
Test-Assertion "Rule = IntensionalInheritance"   ($ii.Rule -eq 'IntensionalInheritance')
Assert-Near    "7/10 = 0.7"                      $ii.TruthValue.Strength 0.7 0.01
Assert-InRange "Confidence in [0,1]"             $ii.TruthValue.Confidence

$iiZero = Invoke-IntensionalInheritance -OverlapCount 0 -TotalPredicatesA 10 -Confidence 0.9
Assert-Near    "0/10 = 0"                        $iiZero.TruthValue.Strength 0.0 0.01

$iiEmpty = Invoke-IntensionalInheritance -OverlapCount 5 -TotalPredicatesA 0 -Confidence 0.8
Assert-Near    "Zero total -> s=0"               $iiEmpty.TruthValue.Strength 0.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-ExtensionalInheritance"

$ei = Invoke-ExtensionalInheritance -OverlapCount 15 -TotalMembersA 20 -Confidence 0.85
Test-Assertion "Returns hashtable"               ($null -ne $ei)
Test-Assertion "Rule = ExtensionalInheritance"   ($ei.Rule -eq 'ExtensionalInheritance')
Assert-Near    "15/20 = 0.75"                    $ei.TruthValue.Strength 0.75 0.01

$eiAll = Invoke-ExtensionalInheritance -OverlapCount 10 -TotalMembersA 10 -Confidence 0.9
Assert-Near    "All overlap -> s=1"              $eiAll.TruthValue.Strength 1.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-AttractorRule"

$attr = Invoke-AttractorRule -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthBA 0.8 -ConfidenceBA 0.75
Test-Assertion "Returns hashtable"               ($null -ne $attr)
Test-Assertion "Rule = Attractor"                ($attr.Rule -eq 'Attractor')
Test-Assertion "Conclusion = Attract(A,B)"       ($attr.Conclusion -eq 'Attract(A,B)')
# Geometric mean of 0.9 and 0.8 = sqrt(0.72) ≈ 0.8485
Assert-Near    "Geom mean ~0.849"                $attr.TruthValue.Strength 0.849 0.02
Test-Assertion "Confidence discounted"           ($attr.TruthValue.Confidence -lt 0.75)

$attrZero = Invoke-AttractorRule -StrengthAB 0.0 -ConfidenceAB 0.8 `
    -StrengthBA 0.9 -ConfidenceBA 0.8
Assert-Near    "Attract(0, 0.9) = 0"             $attrZero.TruthValue.Strength 0.0 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-SymmetricSimilarity"

$sym = Invoke-SymmetricSimilarity -StrengthSim 0.85 -ConfidenceSim 0.9
Test-Assertion "Returns hashtable"               ($null -ne $sym)
Test-Assertion "Rule = SymmetricSimilarity"      ($sym.Rule -eq 'SymmetricSimilarity')
Test-Assertion "Conclusion = B↔A"                ($sym.Conclusion -eq 'B↔A')
Assert-Near    "Strength unchanged"              $sym.TruthValue.Strength 0.85 0.001
Assert-Near    "Confidence unchanged"            $sym.TruthValue.Confidence 0.9 0.001

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-CombinedInheritance"

$comb = Invoke-CombinedInheritance `
    -IntensionalStrength 0.7 -IntensionalConfidence 0.8 `
    -ExtensionalStrength 0.85 -ExtensionalConfidence 0.9
Test-Assertion "Returns hashtable"               ($null -ne $comb)
Test-Assertion "Rule = CombinedInheritance"      ($comb.Rule -eq 'CombinedInheritance')
# 0.5 * 0.7 + 0.5 * 0.85 = 0.775
Assert-Near    "Equal weights -> 0.775"          $comb.TruthValue.Strength 0.775 0.01
# c = min(0.8, 0.9) = 0.8
Assert-Near    "Confidence = min(ci,ce)"         $comb.TruthValue.Confidence 0.8 0.001

$combWeighted = Invoke-CombinedInheritance `
    -IntensionalStrength 0.6 -IntensionalConfidence 0.7 `
    -ExtensionalStrength 0.9 -ExtensionalConfidence 0.8 `
    -IntensionalWeight 0.2
# 0.2*0.6 + 0.8*0.9 = 0.12 + 0.72 = 0.84
Assert-Near    "Weighted: 0.2*0.6+0.8*0.9=0.84" $combWeighted.TruthValue.Strength 0.84 0.01

# ===========================================================================
# TEMPORAL REASONING
# ===========================================================================

Start-TestSection "New-TemporalInterval"

$ti = New-TemporalInterval -Start 2.0 -End 5.0
Test-Assertion "Created TemporalInterval"        ($null -ne $ti)
Test-Assertion "Is TemporalInterval"             (Test-TypeName $ti 'TemporalInterval')
Assert-Near    "Start = 2.0"                     $ti.Start 2.0 0.001
Assert-Near    "End = 5.0"                       $ti.End   5.0 0.001
Assert-Near    "Duration = 3.0"                  $ti.Duration() 3.0 0.001
Assert-Near    "Midpoint = 3.5"                  $ti.Midpoint() 3.5 0.001
Test-Assertion "Contains(3)"                     $ti.Contains(3.0)
Test-Assertion "Not Contains(6)"                 (-not $ti.Contains(6.0))
Test-Assertion "ToString not empty"              ($ti.ToString().Length -gt 0)

try {
    New-TemporalInterval -Start 5.0 -End 2.0
    Test-Assertion "End < Start should throw"    $false
} catch {
    Test-Assertion "End < Start throws"          $true
}

# ---------------------------------------------------------------------------
Start-TestSection "New-EventAtom"

$evt = New-EventAtom -Name "MeetingA" -Start 9.0 -End 10.0 -Strength 0.95 -Confidence 0.9
Test-Assertion "Created EventAtom"               ($null -ne $evt)
Test-Assertion "Has Name"                        ($evt.Name -eq "MeetingA")
Test-Assertion "Type = EventAtom"                ($evt.Type -eq 'EventAtom')
Test-Assertion "Has Interval"                    ($null -ne $evt.Interval)
Assert-Near    "Interval start = 9"              $evt.Interval.Start 9.0 0.001
Test-Assertion "Has TV"                          ($null -ne $evt.TV)
Assert-Near    "TV strength = 0.95"              $evt.TV.Strength 0.95 0.001

# ---------------------------------------------------------------------------
Start-TestSection "Get-AllenRelation"

$before  = New-TemporalInterval -Start 1 -End 3
$after   = New-TemporalInterval -Start 5 -End 8
$meets1  = New-TemporalInterval -Start 1 -End 5
$meets2  = New-TemporalInterval -Start 5 -End 9
$overlap1 = New-TemporalInterval -Start 1 -End 6
$overlap2 = New-TemporalInterval -Start 4 -End 9
$inside  = New-TemporalInterval -Start 3 -End 7
$outer   = New-TemporalInterval -Start 1 -End 10
$starts1 = New-TemporalInterval -Start 1 -End 4
$starts2 = New-TemporalInterval -Start 1 -End 8
$finish1 = New-TemporalInterval -Start 4 -End 9
$finish2 = New-TemporalInterval -Start 2 -End 9
$equal1  = New-TemporalInterval -Start 2 -End 7
$equal2  = New-TemporalInterval -Start 2 -End 7

Test-Assertion "Before"             ((Get-AllenRelation $before  $after  ) -eq 'Before')
Test-Assertion "After"              ((Get-AllenRelation $after   $before ) -eq 'After')
Test-Assertion "Meets"              ((Get-AllenRelation $meets1  $meets2 ) -eq 'Meets')
Test-Assertion "MetBy"              ((Get-AllenRelation $meets2  $meets1 ) -eq 'MetBy')
Test-Assertion "Overlaps"           ((Get-AllenRelation $overlap1 $overlap2) -eq 'Overlaps')
Test-Assertion "OverlappedBy"       ((Get-AllenRelation $overlap2 $overlap1) -eq 'OverlappedBy')
Test-Assertion "During"             ((Get-AllenRelation $inside  $outer  ) -eq 'During')
Test-Assertion "Contains"           ((Get-AllenRelation $outer   $inside ) -eq 'Contains')
Test-Assertion "Starts"             ((Get-AllenRelation $starts1 $starts2) -eq 'Starts')
Test-Assertion "StartedBy"          ((Get-AllenRelation $starts2 $starts1) -eq 'StartedBy')
Test-Assertion "Finishes"           ((Get-AllenRelation $finish1 $finish2) -eq 'Finishes')
Test-Assertion "FinishedBy"         ((Get-AllenRelation $finish2 $finish1) -eq 'FinishedBy')
Test-Assertion "Equals"             ((Get-AllenRelation $equal1  $equal2 ) -eq 'Equals')

# ---------------------------------------------------------------------------
Start-TestSection "Get-AllAllenRelations"

$aList = @(
    (New-TemporalInterval -Start 1 -End 3),
    (New-TemporalInterval -Start 5 -End 8)
)
$bList = @(
    (New-TemporalInterval -Start 2 -End 6)
)

$allRels = Get-AllAllenRelations -IntervalsA $aList -IntervalsB $bList
Test-Assertion "Returns list"                    ($null -ne $allRels)
Test-Assertion "2*1 = 2 pairs"                   ($allRels.Count -eq 2)
Test-Assertion "Each has Relation key"           ($allRels[0].ContainsKey('Relation'))
Test-Assertion "Each has IntervalA key"          ($allRels[0].ContainsKey('IntervalA'))

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-TemporalDeduction"

$td = Invoke-TemporalDeduction `
    -StrengthAB 0.9 -ConfidenceAB 0.85 -TimeAB 0 `
    -StrengthBC 0.8 -ConfidenceBC 0.8  -TimeBC 0
Test-Assertion "Returns hashtable"               ($null -ne $td)
Test-Assertion "Rule = TemporalDeduction"        ($td.Rule -eq 'TemporalDeduction')
Test-Assertion "Has TruthValue"                  ($null -ne $td.TruthValue)
Assert-InRange "Strength in [0,1]"               $td.TruthValue.Strength
Test-Assertion "Has TimeDelta"                   ($null -ne $td.TimeDelta)
Test-Assertion "No decay at t=0"                 ($td.DecayFactor -gt 0.999)

$tdDecay = Invoke-TemporalDeduction `
    -StrengthAB 0.9 -ConfidenceAB 0.85 -TimeAB 0 `
    -StrengthBC 0.8 -ConfidenceBC 0.8  -TimeBC 20 `
    -DecayRate 0.1
Test-Assertion "Large time gap reduces confidence" ($tdDecay.TruthValue.Confidence -lt $td.TruthValue.Confidence)
Assert-Near    "TimeDelta = 20"                  $tdDecay.TimeDelta 20.0 0.001
# Decay: exp(-0.1*20) = exp(-2) ≈ 0.135
Assert-Near    "DecayFactor ≈ 0.135"             $tdDecay.DecayFactor 0.135 0.01

# ---------------------------------------------------------------------------
Start-TestSection "Invoke-TemporalProjection"

$tp = Invoke-TemporalProjection `
    -StrengthT1 0.5 -StrengthT2 0.7 `
    -TimeT1 0 -TimeT2 10 -TimeFuture 20 `
    -ConfidenceBase 0.8 -DecayRate 0.05
Test-Assertion "Returns hashtable"               ($null -ne $tp)
Test-Assertion "Rule = TemporalProjection"       ($tp.Rule -eq 'TemporalProjection')
Test-Assertion "Has TruthValue"                  ($null -ne $tp.TruthValue)
# slope = (0.7-0.5)/10 = 0.02; s(t=20) = 0.7 + 0.02*10 = 0.9
Assert-Near    "Projected s(20) = 0.9"           $tp.TruthValue.Strength 0.9 0.01
# confidence: 0.8 * exp(-0.05*10) = 0.8 * 0.6065 ≈ 0.485
Assert-Near    "Confidence decayed ~0.485"       $tp.TruthValue.Confidence 0.485 0.02
Assert-Near    "Slope = 0.02"                    $tp.Slope 0.02 0.001
Assert-Near    "Horizon = 10"                    $tp.Horizon 10.0 0.001

# Declining trend
$tpDecline = Invoke-TemporalProjection `
    -StrengthT1 0.8 -StrengthT2 0.6 `
    -TimeT1 0 -TimeT2 10 -TimeFuture 15
# slope = -0.02; s(15) = 0.6 + (-0.02)*5 = 0.5
Assert-Near    "Declining: s(15)=0.5"            $tpDecline.TruthValue.Strength 0.5 0.01

# Clamped to 0 when trend would go negative
$tpFloor = Invoke-TemporalProjection `
    -StrengthT1 0.8 -StrengthT2 0.3 `
    -TimeT1 0 -TimeT2 10 -TimeFuture 20
Assert-InRange "Strength clamped to [0,1]"       $tpFloor.TruthValue.Strength

try {
    Invoke-TemporalProjection -StrengthT1 0.5 -StrengthT2 0.7 `
        -TimeT1 10 -TimeT2 5 -TimeFuture 20
    Test-Assertion "T2 < T1 should throw"        $false
} catch {
    Test-Assertion "T2 < T1 throws"              $true
}

try {
    Invoke-TemporalProjection -StrengthT1 0.5 -StrengthT2 0.7 `
        -TimeT1 0 -TimeT2 10 -TimeFuture 5
    Test-Assertion "Future <= T2 should throw"   $false
} catch {
    Test-Assertion "Future <= T2 throws"         $true
}

# ---------------------------------------------------------------------------
Start-TestSection "Test-TemporalOverlap"

$ta = New-TemporalInterval -Start 1 -End 5
$tb = New-TemporalInterval -Start 3 -End 8
$tc = New-TemporalInterval -Start 6 -End 9
$td2 = New-TemporalInterval -Start 5 -End 7

Test-Assertion "Overlapping intervals"           (Test-TemporalOverlap -IntervalA $ta -IntervalB $tb)
Test-Assertion "Non-overlapping intervals"       (-not (Test-TemporalOverlap -IntervalA $ta -IntervalB $tc))
Test-Assertion "Touching at endpoint overlaps"   (Test-TemporalOverlap -IntervalA $ta -IntervalB $td2)
Test-Assertion "Symmetric: b overlaps a"         (Test-TemporalOverlap -IntervalA $tb -IntervalB $ta)

# ===========================================================================
# INTEGRATION TEST: Reasoning Chain with Temporal Context
# ===========================================================================

Start-TestSection "Integration: Temporal Knowledge Chain"

$kb = New-AtomSpace
$fluffy   = $kb.AddAtom((New-ConceptNode "Fluffy"))
$cat      = $kb.AddAtom((New-ConceptNode "Cat"))
$animal   = $kb.AddAtom((New-ConceptNode "Animal"))
$mortal   = $kb.AddAtom((New-ConceptNode "Mortal"))

# Fluffy is a Cat (high confidence)
$fluffyCat = $kb.AddAtom((New-InheritanceLink -Child $fluffy -Parent $cat `
    -Strength 0.98 -Confidence 0.95))
# Cat is an Animal
$catAnimal = $kb.AddAtom((New-InheritanceLink -Child $cat -Parent $animal `
    -Strength 0.99 -Confidence 0.99))
# Animal is Mortal
$animalMortal = $kb.AddAtom((New-InheritanceLink -Child $animal -Parent $mortal `
    -Strength 0.95 -Confidence 0.9))

# Step 1: Deduce Fluffy is Animal
$r1 = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $fluffyCat -LinkBC $catAnimal -AddToAtomSpace
Test-Assertion "Fluffy→Animal inferred"          ($r1.Conclusion.GetOutgoingAtom(1).Name -eq 'Animal')

# Step 2: Deduce Fluffy is Mortal via temporal deduction
$tvFA = $r1.TruthValue
$tvAM = $animalMortal.GetTruthValue()
$td2 = Invoke-TemporalDeduction `
    -StrengthAB $tvFA.Strength -ConfidenceAB $tvFA.Confidence -TimeAB 0 `
    -StrengthBC $tvAM.Strength -ConfidenceBC $tvAM.Confidence -TimeBC 0
Test-Assertion "Temporal deduction returns result"  ($null -ne $td2)
Assert-InRange "Fluffy→Mortal strength in [0,1]"   $td2.TruthValue.Strength

# Induction: both Fluffy and another Cat have the Mortal property => generalise
$spot = $kb.AddAtom((New-ConceptNode "Spot"))
$spotCat = $kb.AddAtom((New-InheritanceLink -Child $spot -Parent $cat `
    -Strength 0.95 -Confidence 0.9))
$r3 = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $spotCat -LinkBC $catAnimal -AddToAtomSpace
$indResult = Invoke-PLNInduction `
    -StrengthAC $r1.TruthValue.Strength    -ConfidenceAC $r1.TruthValue.Confidence `
    -StrengthBC $r3.TruthValue.Strength    -ConfidenceBC $r3.TruthValue.Confidence
Test-Assertion "Induction: Fluffy→Spot via Animal"  ($null -ne $indResult)
Assert-InRange "Induced strength in [0,1]"          $indResult.TruthValue.Strength

# ---------------------------------------------------------------------------
$total = $script:TestsPassed + $script:TestsFailed
Write-Host "`n=== Phase 5 PLN Test Summary ===" -ForegroundColor Cyan
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
