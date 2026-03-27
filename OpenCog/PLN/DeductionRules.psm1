using module ./TruthValues.psm1

<#
.SYNOPSIS
    PLN Deduction Rules for OpenCog PowerShell

.DESCRIPTION
    Implements the core Probabilistic Logic Networks (PLN) deduction rules:

    - Deduction        : A→B, B→C ⊢ A→C  (transitivity with TV propagation)
    - Modus Ponens     : A→B, A ⊢ B
    - Modus Tollens    : A→B, ¬B ⊢ ¬A
    - Contraposition   : A→B ⊢ ¬B→¬A
    - Hypothetical Syllogism : same as Deduction but with explicit naming

    Each rule returns a result hashtable:
      @{
          Conclusion  = <string description>
          TruthValue  = <SimpleTruthValue>
          Rule        = <string rule name>
          Premises    = <string[]>
      }

    Truth value propagation follows standard PLN formulas:
      - Deduction confidence uses min(c_AB, c_BC) * min confidence factor
      - Strength uses the PLN deduction formula: sAC = sAB * sBC

.NOTES
    Phase 4 — PLN Infrastructure
    Version: 2.0.0
    Reference: Probabilistic Logic Networks (Goertzel et al.)
#>

# Ensure TruthValues types are available (dot-sourced via OpenCog.psm1)
# Classes SimpleTruthValue, CountTruthValue, etc. are expected to already be loaded.

# ---------------------------------------------------------------------------
# Internal helper: extract SimpleTruthValue from anything TV-like
# ---------------------------------------------------------------------------
function script:Get-SimpleTV {
    param([object]$tv)
    if ($tv.GetType().Name -eq 'SimpleTruthValue') { return $tv }
    if ($null -ne ($tv | Get-Member -Name 'ToSimple' -ErrorAction SilentlyContinue)) {
        return $tv.ToSimple()
    }
    if ($null -ne ($tv | Get-Member -Name 'Strength' -ErrorAction SilentlyContinue)) {
        return New-SimpleTruthValue -Strength $tv.Strength -Confidence $tv.Confidence
    }
    throw "Cannot extract SimpleTruthValue from '$($tv.GetType().Name)'"
}

# ---------------------------------------------------------------------------
# Deduction Rule: A→B, B→C ⊢ A→C
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply the PLN deduction rule: given A→B and B→C, conclude A→C.

.DESCRIPTION
    PLN deduction formula:
      sAC = sAB * sBC + (1 - sAB) * (sC - sB * sBC) / (1 - sB)   (when sB < 1)
      cAC = min(cAB, cBC) * k   where k is a confidence discount factor

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthBC
    Strength of B→C.

.PARAMETER ConfidenceBC
    Confidence of B→C.

.PARAMETER StrengthB
    Marginal probability/strength of B (default 0.5 for unknown).

.PARAMETER StrengthC
    Marginal probability/strength of C (default 0.5 for unknown).

.PARAMETER DiscountFactor
    Confidence discount factor k ∈ (0,1]. Default 0.9.

.EXAMPLE
    # Cat is Animal (0.9, 0.9), Animal is LivingThing (0.95, 0.85)
    $result = Invoke-PLNDeduction -StrengthAB 0.9 -ConfidenceAB 0.9 `
        -StrengthBC 0.95 -ConfidenceBC 0.85
    $result.TruthValue
#>
function Invoke-PLNDeduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthBC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBC,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$StrengthC = 0.5,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    # Clamp inputs
    $sAB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthAB))
    $cAB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceAB))
    $sBC = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthBC))
    $cBC = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceBC))
    $sB  = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthB))
    $sC  = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthC))

    # Deduction strength formula (PLN)
    if ((1.0 - $sB) -lt 1e-10) {
        $sAC = $sAB * $sBC
    }
    else {
        $sAC = $sAB * $sBC + (1.0 - $sAB) * ($sC - $sB * $sBC) / (1.0 - $sB)
    }
    $sAC = [Math]::Max(0.0, [Math]::Min(1.0, $sAC))

    # Confidence: min of the two * discount
    $cAC = [Math]::Min($cAB, $cBC) * [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    return @{
        Rule       = 'Deduction'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "B→C (s=$sBC, c=$cBC)")
        Conclusion = "A→C"
        TruthValue = New-SimpleTruthValue -Strength $sAC -Confidence $cAC
    }
}

# ---------------------------------------------------------------------------
# Modus Ponens: A→B, A ⊢ B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply modus ponens: given A→B and A, conclude B.

.DESCRIPTION
    PLN modus ponens:
      sB' = sAB * sA + (1 - sAB) * (1 - sA) * sB_prior  (simplified)
      cB' = min(cAB, cA) * discount

    For the simple (non-prior) form:
      sB' = sAB * sA
      cB' = min(cAB, cA) * discount

.PARAMETER StrengthImplication
    Strength of A→B.

.PARAMETER ConfidenceImplication
    Confidence of A→B.

.PARAMETER StrengthA
    Strength/truth of A.

.PARAMETER ConfidenceA
    Confidence of A.

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $result = Invoke-ModusPonens -StrengthImplication 0.9 -ConfidenceImplication 0.8 `
        -StrengthA 0.95 -ConfidenceA 0.9
#>
function Invoke-ModusPonens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthImplication,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceImplication,
        [Parameter(Mandatory = $true)]  [double]$StrengthA,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceA,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthImplication))
    $cAB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceImplication))
    $sA  = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthA))
    $cA  = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceA))

    $sB = $sAB * $sA
    $cB = [Math]::Min($cAB, $cA) * [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    return @{
        Rule       = 'ModusPonens'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "A (s=$sA, c=$cA)")
        Conclusion = 'B'
        TruthValue = New-SimpleTruthValue -Strength $sB -Confidence $cB
    }
}

# ---------------------------------------------------------------------------
# Modus Tollens: A→B, ¬B ⊢ ¬A
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply modus tollens: given A→B and ¬B, conclude ¬A.

.DESCRIPTION
    In PLN:
      s(¬B) = 1 - sB
      s(¬A) = 1 - sA'  where sA' ≈ sAB * sA + (1-sAB)*(1-sA) approximation
      Simplified: s(¬A) ≈ 1 - sAB * sA / (sAB * sA + (1-sAB)*(1-sA))

    This implementation uses the probabilistic contrapositive formula.

.PARAMETER StrengthImplication
    Strength of A→B.

.PARAMETER ConfidenceImplication
    Confidence of A→B.

.PARAMETER StrengthNotB
    Strength of ¬B (= 1 - sB typically).

.PARAMETER ConfidenceNotB
    Confidence of ¬B.

.PARAMETER DiscountFactor
    Confidence discount. Default 0.9.

.EXAMPLE
    $result = Invoke-ModusTollens -StrengthImplication 0.9 -ConfidenceImplication 0.8 `
        -StrengthNotB 0.9 -ConfidenceNotB 0.85
#>
function Invoke-ModusTollens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthImplication,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceImplication,
        [Parameter(Mandatory = $true)]  [double]$StrengthNotB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceNotB,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB  = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthImplication))
    $cAB  = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceImplication))
    $sNB  = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthNotB))
    $cNB  = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceNotB))

    # ¬A strength via contrapositive: s(¬A→¬B) = s(A→B) => s(¬A|¬B) ≈ sAB * sNB
    # Simplified formula: P(¬A|¬B) = P(¬B|A)*P(A) / P(¬B)
    # Using sNB ≈ s(¬B) = 1 - sB,  s(¬B|A) = 1 - sAB
    # -> s(¬A) ≈ (1 - sAB) * sNB  (prior P(A) = 0.5 assumed)
    $sNA = (1.0 - $sAB) * $sNB
    $sNA = [Math]::Max(0.0, [Math]::Min(1.0, $sNA))
    $cNA = [Math]::Min($cAB, $cNB) * [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    return @{
        Rule       = 'ModusTollens'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "¬B (s=$sNB, c=$cNB)")
        Conclusion = '¬A'
        TruthValue = New-SimpleTruthValue -Strength $sNA -Confidence $cNA
    }
}

# ---------------------------------------------------------------------------
# Contraposition: A→B ⊢ ¬B→¬A
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply the PLN contraposition rule: A→B ⊢ ¬B→¬A.

.DESCRIPTION
    Contraposition transforms an implication into its contrapositive.
    In PLN: s(¬B→¬A) = (1-sAB) / (1-sAB + sA_prior * ...) — approximated as
    s(¬B→¬A) ≈ 1 - sAB   for unknown base rates.

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthA
    Prior strength of A (default 0.5).

.PARAMETER StrengthB
    Prior strength of B (default 0.5).

.PARAMETER DiscountFactor
    Confidence discount. Default 0.9.

.EXAMPLE
    $result = Invoke-PLNContraposition -StrengthAB 0.85 -ConfidenceAB 0.9
#>
function Invoke-PLNContraposition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $false)] [double]$StrengthA = 0.5,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthAB))
    $cAB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceAB))
    $sA  = [Math]::Max(0.001, [Math]::Min(0.999, $StrengthA))
    $sB  = [Math]::Max(0.001, [Math]::Min(0.999, $StrengthB))

    # PLN contraposition formula:
    # s(¬B→¬A) = P(¬A|¬B) = (P(¬B|A)*P(A)) / P(¬B)
    #           = ((1-sAB)*sA) / (1-sB)
    $sContra = ((1.0 - $sAB) * $sA) / (1.0 - $sB)
    $sContra = [Math]::Max(0.0, [Math]::Min(1.0, $sContra))
    $cContra = $cAB * [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    return @{
        Rule       = 'Contraposition'
        Premises   = @("A→B (s=$sAB, c=$cAB)")
        Conclusion = '¬B→¬A'
        TruthValue = New-SimpleTruthValue -Strength $sContra -Confidence $cContra
    }
}

# ---------------------------------------------------------------------------
# Hypothetical Syllogism (alias for Deduction with named interface)
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Hypothetical Syllogism: A→B, B→C ⊢ A→C (same as deduction).

.DESCRIPTION
    Named alias for Invoke-PLNDeduction to match classical logic naming.

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthBC
    Strength of B→C.

.PARAMETER ConfidenceBC
    Confidence of B→C.

.PARAMETER StrengthB
    Marginal strength of B (default 0.5).

.PARAMETER StrengthC
    Marginal strength of C (default 0.5).

.EXAMPLE
    $result = Invoke-HypotheticalSyllogism -StrengthAB 0.9 -ConfidenceAB 0.8 `
        -StrengthBC 0.85 -ConfidenceBC 0.75
#>
function Invoke-HypotheticalSyllogism {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthBC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBC,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$StrengthC = 0.5
    )

    $result = Invoke-PLNDeduction -StrengthAB $StrengthAB -ConfidenceAB $ConfidenceAB `
        -StrengthBC $StrengthBC -ConfidenceBC $ConfidenceBC `
        -StrengthB $StrengthB -StrengthC $StrengthC
    $result['Rule'] = 'HypotheticalSyllogism'
    return $result
}

# ---------------------------------------------------------------------------
# Apply deduction rule to AtomSpace atoms (higher-level helper)
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply PLN deduction to two InheritanceLink atoms in an AtomSpace,
    creating a new inferred InheritanceLink A→C.

.PARAMETER AtomSpace
    The AtomSpace containing the implication atoms.

.PARAMETER LinkAB
    An InheritanceLink or ImplicationLink atom representing A→B.

.PARAMETER LinkBC
    An InheritanceLink or ImplicationLink atom representing B→C.

.PARAMETER AddToAtomSpace
    If set, automatically adds the inferred link to the AtomSpace.

.EXAMPLE
    $inferred = Invoke-AtomSpaceDeduction -AtomSpace $kb -LinkAB $catIsAnimal `
        -LinkBC $animalIsLiving -AddToAtomSpace
#>
function Invoke-AtomSpaceDeduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$AtomSpace,

        [Parameter(Mandatory = $true)]
        [object]$LinkAB,

        [Parameter(Mandatory = $true)]
        [object]$LinkBC,

        [Parameter(Mandatory = $false)]
        [switch]$AddToAtomSpace
    )

    if ($null -eq $LinkAB -or $null -eq $LinkBC) {
        throw "LinkAB and LinkBC must not be null"
    }

    $tvAB = $LinkAB.GetTruthValue()
    $tvBC = $LinkBC.GetTruthValue()

    $atomA = $LinkAB.GetOutgoingAtom(0)
    $atomC = $LinkBC.GetOutgoingAtom(1)

    $dedResult = Invoke-PLNDeduction `
        -StrengthAB $tvAB.Strength -ConfidenceAB $tvAB.Confidence `
        -StrengthBC $tvBC.Strength -ConfidenceBC $tvBC.Confidence

    $newTV = $dedResult.TruthValue

    $newLink = New-InheritanceLink -Child $atomA -Parent $atomC `
        -Strength $newTV.Strength -Confidence $newTV.Confidence

    if ($AddToAtomSpace) {
        $newLink = $AtomSpace.AddAtom($newLink)
    }

    return @{
        Rule       = 'AtomSpaceDeduction'
        Premises   = @($LinkAB.Handle, $LinkBC.Handle)
        Conclusion = $newLink
        TruthValue = $newTV
    }
}
