<#
.SYNOPSIS
    Phase 5 Advanced PLN Reasoning Demo

.DESCRIPTION
    Demonstrates Phase 5 capabilities:
    - Induction, abduction, inversion
    - AndIntroduction, OrIntroduction, NotIntroduction
    - Higher-order inference: InheritanceToSimilarity, AttractorRule
    - Intensional and extensional inheritance
    - Allen's interval algebra and temporal reasoning
    - Temporal deduction with time decay
    - Temporal projection

.NOTES
    Phase 5 — Advanced PLN Reasoning
    Run: ./OpenCog/Examples/Phase5Demo.ps1
#>

Import-Module (Join-Path $PSScriptRoot ".." "OpenCog.psd1") -Force

Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  OpenCog PowerShell — Phase 5: Advanced PLN Demo" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Magenta

# ===========================================================================
# 1. INDUCTION AND ABDUCTION
# ===========================================================================

Write-Host "━━━ 1. Induction & Abduction ━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Induction: Cat→Breathes, Dog→Breathes  ⊢  Cat→Dog (via shared effect)
$indResult = Invoke-PLNInduction `
    -StrengthAC 0.95 -ConfidenceAC 0.9 `
    -StrengthBC 0.95 -ConfidenceBC 0.85
Write-Host "INDUCTION  : Cat→Breathes + Dog→Breathes => Cat→Dog"
Write-Host "             $($indResult.TruthValue)"

# Abduction: Fluffy→Animal, Fluffy→Breathes  ⊢  Animal→Breathes
$abdResult = Invoke-PLNAbduction `
    -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthAC 0.95 -ConfidenceAC 0.8
Write-Host "ABDUCTION  : Fluffy→Animal + Fluffy→Breathes => Animal→Breathes"
Write-Host "             $($abdResult.TruthValue)"

# Inversion: IsA(Cat, Animal) ⊢ IsA(Animal, Cat)  [Bayesian inversion]
$invResult = Invoke-PLNInversion `
    -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthA 0.3 -StrengthB 0.7
Write-Host "INVERSION  : Cat→Animal (P(Cat)=0.3, P(Animal)=0.7) => Animal→Cat"
Write-Host "             $($invResult.TruthValue)"

# AndIntroduction + OrIntroduction
$andR = Invoke-PLNAndIntroduction -StrengthA 0.9 -ConfidenceA 0.85 -StrengthB 0.8 -ConfidenceB 0.75
$orR  = Invoke-PLNOrIntroduction  -StrengthA 0.9 -ConfidenceA 0.85 -StrengthB 0.8 -ConfidenceB 0.75
$notR = Invoke-PLNNotIntroduction -Strength 0.7 -Confidence 0.9
Write-Host "AND INTRO  : A(0.9) ∧ B(0.8) = $([Math]::Round($andR.TruthValue.Strength,3))"
Write-Host "OR  INTRO  : A(0.9) ∨ B(0.8) = $([Math]::Round($orR.TruthValue.Strength,3))"
Write-Host "NOT INTRO  : ¬A(0.7) = $([Math]::Round($notR.TruthValue.Strength,3))"

# ===========================================================================
# 2. HIGHER-ORDER INFERENCE
# ===========================================================================

Write-Host "`n━━━ 2. Higher-Order Inference ━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Derive similarity from bidirectional inheritance
$sim = Invoke-InheritanceToSimilarity `
    -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthBA 0.8 -ConfidenceBA 0.75
Write-Host "SIMILARITY  : Cat→Animal(0.9) + Animal→Cat(0.8) => Cat↔Animal"
Write-Host "              $($sim.TruthValue)"

# And reverse: similarity back to inheritance
$inh = Invoke-SimilarityToInheritance -StrengthSim 0.85 -ConfidenceSim 0.8 -StrengthB 0.4
Write-Host "INHERITANCE : Cat↔Animal(0.85) => Cat→Animal"
Write-Host "              $($inh.TruthValue)"

# Symmetry
$symR = Invoke-SymmetricSimilarity -StrengthSim 0.85 -ConfidenceSim 0.9
Write-Host "SYMMETRY    : Cat↔Animal => Animal↔Cat"
Write-Host "              $($symR.TruthValue)"

# Attraction
$attr = Invoke-AttractorRule `
    -StrengthAB 0.9 -ConfidenceAB 0.85 `
    -StrengthBA 0.8 -ConfidenceBA 0.75
Write-Host "ATTRACTION  : Mutual Cat↔Animal links => Attract(Cat,Animal)"
Write-Host "              $($attr.TruthValue)"

# Intensional vs extensional
$intInh = Invoke-IntensionalInheritance -OverlapCount 8 -TotalPredicatesA 10 -Confidence 0.9
$extInh = Invoke-ExtensionalInheritance -OverlapCount 15 -TotalMembersA 20  -Confidence 0.85
$combined = Invoke-CombinedInheritance `
    -IntensionalStrength $intInh.TruthValue.Strength -IntensionalConfidence $intInh.TruthValue.Confidence `
    -ExtensionalStrength $extInh.TruthValue.Strength -ExtensionalConfidence $extInh.TruthValue.Confidence
Write-Host "INTENSIONAL : 8/10 predicates shared => $([Math]::Round($intInh.TruthValue.Strength,3))"
Write-Host "EXTENSIONAL : 15/20 members shared   => $([Math]::Round($extInh.TruthValue.Strength,3))"
Write-Host "COMBINED    : weighted average        => $([Math]::Round($combined.TruthValue.Strength,3))"

# ===========================================================================
# 3. TEMPORAL REASONING — ALLEN'S ALGEBRA
# ===========================================================================

Write-Host "`n━━━ 3. Allen's Interval Algebra ━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$meeting   = New-TemporalInterval -Start 9.0  -End 10.5
$lunch     = New-TemporalInterval -Start 12.0 -End 13.0
$project   = New-TemporalInterval -Start 8.0  -End 17.0
$standup   = New-TemporalInterval -Start 9.0  -End 9.5
$afternoon = New-TemporalInterval -Start 13.0 -End 17.0

$relMeetingLunch    = Get-AllenRelation $meeting   $lunch
$relMeetingProject  = Get-AllenRelation $meeting   $project
$relStandupMeeting  = Get-AllenRelation $standup   $meeting
$relLunchAfternoon  = Get-AllenRelation $lunch     $afternoon
$relProjectMeeting  = Get-AllenRelation $project   $meeting

Write-Host "Meeting    [9.0–10.5]  vs  Lunch     [12–13]:   $relMeetingLunch"
Write-Host "Meeting    [9.0–10.5]  vs  Project   [8–17]:    $relMeetingProject"
Write-Host "Standup    [9.0–9.5]   vs  Meeting   [9–10.5]:  $relStandupMeeting"
Write-Host "Lunch      [12–13]     vs  Afternoon [13–17]:   $relLunchAfternoon"
Write-Host "Project    [8–17]      vs  Meeting   [9–10.5]:  $relProjectMeeting"

# Overlap test
$testOverlap = Test-TemporalOverlap -IntervalA $meeting -IntervalB $project
Write-Host "`nMeeting overlaps with Project: $testOverlap"

# ===========================================================================
# 4. TEMPORAL DEDUCTION AND PROJECTION
# ===========================================================================

Write-Host "`n━━━ 4. Temporal Deduction & Projection ━━━━━━━━━━━━" -ForegroundColor Cyan

# Event atoms
$evtA = New-EventAtom -Name "RainForecast"  -Start 0  -End 1 -Strength 0.85 -Confidence 0.9
$evtB = New-EventAtom -Name "RoadWet"       -Start 1  -End 2 -Strength 0.9  -Confidence 0.85
$evtC = New-EventAtom -Name "AccidentRisk"  -Start 5  -End 6 -Strength 0.7  -Confidence 0.8

Write-Host "Events:"
Write-Host "  $($evtA.Name)  : $($evtA.TV)"
Write-Host "  $($evtB.Name)      : $($evtB.TV)"
Write-Host "  $($evtC.Name) : $($evtC.TV)"

# Temporal deduction: RainForecast->RoadWet->AccidentRisk (with time decay)
$tdResult = Invoke-TemporalDeduction `
    -StrengthAB $evtA.TV.Strength -ConfidenceAB $evtA.TV.Confidence -TimeAB 0 `
    -StrengthBC $evtB.TV.Strength -ConfidenceBC $evtB.TV.Confidence -TimeBC 5 `
    -DecayRate 0.05

Write-Host "`nTemporal Deduction: Rain→Road (t=0) + Road→Accident (t=5)"
Write-Host "  Time delta  : $($tdResult.TimeDelta)"
Write-Host "  Decay factor: $([Math]::Round($tdResult.DecayFactor, 4))"
Write-Host "  Conclusion  : $($tdResult.TruthValue)"

# Temporal projection: traffic congestion trend
Write-Host "`nTemporal Projection: Traffic Congestion Trend"
$tp = Invoke-TemporalProjection `
    -StrengthT1 0.4 -StrengthT2 0.65 `
    -TimeT1 0 -TimeT2 10 -TimeFuture 20 `
    -ConfidenceBase 0.85 -DecayRate 0.03

Write-Host "  t= 0: strength=0.40"
Write-Host "  t=10: strength=0.65"
Write-Host "  t=20: projected=$([Math]::Round($tp.TruthValue.Strength,3)) (confidence=$([Math]::Round($tp.TruthValue.Confidence,3)))"
Write-Host "  Slope       : $([Math]::Round($tp.Slope,4)) per time unit"

# ===========================================================================
# 5. INTEGRATED KNOWLEDGE REASONING SCENARIO
# ===========================================================================

Write-Host "`n━━━ 5. Integrated Scenario: Animal Kingdom ━━━━━━━━" -ForegroundColor Cyan

$kb = New-AtomSpace

# Concepts
$felix   = $kb.AddAtom((New-ConceptNode "Felix"))
$rex     = $kb.AddAtom((New-ConceptNode "Rex"))
$cat     = $kb.AddAtom((New-ConceptNode "Cat"))
$dog     = $kb.AddAtom((New-ConceptNode "Dog"))
$mammal  = $kb.AddAtom((New-ConceptNode "Mammal"))
$animal  = $kb.AddAtom((New-ConceptNode "Animal"))

# Links
$felixCat  = $kb.AddAtom((New-InheritanceLink -Child $felix  -Parent $cat   -Strength 0.98 -Confidence 0.95))
$rexDog    = $kb.AddAtom((New-InheritanceLink -Child $rex    -Parent $dog   -Strength 0.97 -Confidence 0.95))
$catMammal = $kb.AddAtom((New-InheritanceLink -Child $cat    -Parent $mammal -Strength 0.99 -Confidence 0.99))
$dogMammal = $kb.AddAtom((New-InheritanceLink -Child $dog    -Parent $mammal -Strength 0.99 -Confidence 0.99))
$mammalAni = $kb.AddAtom((New-InheritanceLink -Child $mammal -Parent $animal -Strength 0.99 -Confidence 0.99))

# Forward deduction chain
$r1 = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $felixCat  -LinkBC $catMammal -AddToAtomSpace
$r2 = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $r1.Conclusion -LinkBC $mammalAni -AddToAtomSpace

Write-Host "Deduction chain:"
Write-Host "  Felix→Cat→Mammal: $($r1.TruthValue)"
Write-Host "  Felix→Mammal→Animal: $($r2.TruthValue)"

# Induction: both Felix and Rex are Mammals => Felix→Rex
$felixMammal = $r1.Conclusion
$r3 = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $rexDog -LinkBC $dogMammal -AddToAtomSpace
$rexMammal = $r3.Conclusion

$indAnimal = Invoke-PLNInduction `
    -StrengthAC $felixMammal.GetTruthValue().Strength `
    -ConfidenceAC $felixMammal.GetTruthValue().Confidence `
    -StrengthBC $rexMammal.GetTruthValue().Strength `
    -ConfidenceBC $rexMammal.GetTruthValue().Confidence
Write-Host "`nInduction: Felix→Mammal + Rex→Mammal => Felix→Rex"
Write-Host "  $($indAnimal.TruthValue)"

# Similarity: Cat and Dog both inherit from Mammal
$simCatDog = Invoke-PLNInduction `
    -StrengthAC $catMammal.GetTruthValue().Strength `
    -ConfidenceAC $catMammal.GetTruthValue().Confidence `
    -StrengthBC $dogMammal.GetTruthValue().Strength `
    -ConfidenceBC $dogMammal.GetTruthValue().Confidence
Write-Host "`nInduction: Cat→Mammal + Dog→Mammal => Cat similar to Dog"
Write-Host "  $($simCatDog.TruthValue)"

# Statistics
$stats = $kb.GetStatistics()
Write-Host "`nKnowledge Base Statistics:"
Write-Host "  Atoms    : $($stats.TotalAtoms)"
Write-Host "  Nodes    : $($stats.NodeCount)"
Write-Host "  Links    : $($stats.LinkCount)"

Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Phase 5 Demo complete — Advanced PLN operational!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Magenta
