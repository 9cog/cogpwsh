<#
.SYNOPSIS
    PLN Induction and Abduction Rules for OpenCog PowerShell

.DESCRIPTION
    Implements induction, abduction, inversion, and introduction rules for
    Probabilistic Logic Networks (PLN):

    - Induction      : A→C, B→C ⊢ A→B  (shared effect generalises from A to B)
    - Abduction      : A→B, A→C ⊢ B→C  (shared cause generates B→C hypothesis)
    - Inversion      : A→B ⊢ B→A  (Bayesian inversion / symmetry)
    - AndIntroduction: A, B ⊢ A∧B  (conjunction of two evidence atoms)
    - OrIntroduction : A ⊢ A∨B   (add disjunction with a prior)
    - NotIntroduction: A ⊢ ¬A    (negation complement)

    All functions return a result hashtable:
      @{
          Rule       = <string>
          Premises   = <string[]>
          Conclusion = <string>
          TruthValue = <SimpleTruthValue>
      }

    Truth value propagation follows standard PLN formulas.

.NOTES
    Phase 5 — Advanced PLN Reasoning
    Version: 2.1.0
    Reference: Probabilistic Logic Networks (Goertzel et al.)
#>

# ---------------------------------------------------------------------------
# Internal helper
# ---------------------------------------------------------------------------
function script:Clamp01 {
    param([double]$v)
    return [Math]::Max(0.0, [Math]::Min(1.0, $v))
}

# ---------------------------------------------------------------------------
# Induction: A→C, B→C ⊢ A→B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply PLN induction: given A→C and B→C, conclude A→B.

.DESCRIPTION
    PLN induction (shared consequent) formula:
      sAB = sAC / sBC  (when sBC > 0; generalise A from shared effect C)
      Capped to [0,1].
      cAB = min(cAC, cBC) * discount

.PARAMETER StrengthAC
    Strength of A→C.

.PARAMETER ConfidenceAC
    Confidence of A→C.

.PARAMETER StrengthBC
    Strength of B→C.

.PARAMETER ConfidenceBC
    Confidence of B→C.

.PARAMETER DiscountFactor
    Confidence discount factor k ∈ (0,1]. Default 0.9.

.EXAMPLE
    # Cat→Breathes (0.95), Dog→Breathes (0.95) ⊢ Cat→Dog
    $r = Invoke-PLNInduction -StrengthAC 0.95 -ConfidenceAC 0.8 `
        -StrengthBC 0.95 -ConfidenceBC 0.8
#>
function Invoke-PLNInduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAC,
        [Parameter(Mandatory = $true)]  [double]$StrengthBC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBC,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAC = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthAC))
    $cAC = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceAC))
    $sBC = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthBC))
    $cBC = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceBC))
    $k   = [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    if ($sBC -lt 1e-10) {
        $sAB = 1.0
    } else {
        $sAB = [Math]::Max(0.0, [Math]::Min(1.0, ($sAC / $sBC)))
    }
    $cAB = [Math]::Min($cAC, $cBC) * $k

    return @{
        Rule       = 'Induction'
        Premises   = @("A→C (s=$sAC, c=$cAC)", "B→C (s=$sBC, c=$cBC)")
        Conclusion = 'A→B'
        TruthValue = New-SimpleTruthValue -Strength $sAB -Confidence $cAB
    }
}

# ---------------------------------------------------------------------------
# Abduction: A→B, A→C ⊢ B→C
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply PLN abduction: given A→B and A→C, conclude B→C.

.DESCRIPTION
    PLN abduction (shared antecedent) formula:
      sBC = sAC / sAB  (when sAB > 0; hypothesize link from B to C via A)
      cBC = min(cAB, cAC) * discount

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthAC
    Strength of A→C.

.PARAMETER ConfidenceAC
    Confidence of A→C.

.PARAMETER DiscountFactor
    Confidence discount factor k ∈ (0,1]. Default 0.9.

.EXAMPLE
    # Fluffy→Animal (0.9), Fluffy→Breathes (0.95) ⊢ Animal→Breathes
    $r = Invoke-PLNAbduction -StrengthAB 0.9 -ConfidenceAB 0.85 `
        -StrengthAC 0.95 -ConfidenceAC 0.8
#>
function Invoke-PLNAbduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthAC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAC,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthAB))
    $cAB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceAB))
    $sAC = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthAC))
    $cAC = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceAC))
    $k   = [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    if ($sAB -lt 1e-10) {
        $sBC = 1.0
    } else {
        $sBC = [Math]::Max(0.0, [Math]::Min(1.0, ($sAC / $sAB)))
    }
    $cBC = [Math]::Min($cAB, $cAC) * $k

    return @{
        Rule       = 'Abduction'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "A→C (s=$sAC, c=$cAC)")
        Conclusion = 'B→C'
        TruthValue = New-SimpleTruthValue -Strength $sBC -Confidence $cBC
    }
}

# ---------------------------------------------------------------------------
# Inversion (Bayesian inversion): A→B ⊢ B→A
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply PLN Bayesian inversion: given A→B, conclude B→A.

.DESCRIPTION
    PLN inversion formula using Bayes' theorem:
      s(B→A) = s(A→B) * sA / sB
    where sA and sB are marginal strengths (prior probabilities).

    cBA = cAB * discount

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthA
    Marginal strength/probability of A (default 0.5).

.PARAMETER StrengthB
    Marginal strength/probability of B (default 0.5).

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-PLNInversion -StrengthAB 0.9 -ConfidenceAB 0.85 `
        -StrengthA 0.3 -StrengthB 0.7
#>
function Invoke-PLNInversion {
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
    $sA  = [Math]::Max(1e-10, [Math]::Max(0.0, [Math]::Min(1.0, $StrengthA)))
    $sB  = [Math]::Max(1e-10, [Math]::Max(0.0, [Math]::Min(1.0, $StrengthB)))
    $k   = [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    $sBA = [Math]::Max(0.0, [Math]::Min(1.0, ($sAB * $sA / $sB)))
    $cBA = $cAB * $k

    return @{
        Rule       = 'Inversion'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "P(A)=$sA", "P(B)=$sB")
        Conclusion = 'B→A'
        TruthValue = New-SimpleTruthValue -Strength $sBA -Confidence $cBA
    }
}

# ---------------------------------------------------------------------------
# AndIntroduction: A, B ⊢ A∧B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Introduce a conjunction: given A and B, conclude A∧B.

.DESCRIPTION
    PLN conjunction introduction:
      s(A∧B) = sA * sB           (assuming independence)
      c(A∧B) = min(cA, cB) * discount

.PARAMETER StrengthA
    Strength of A.

.PARAMETER ConfidenceA
    Confidence of A.

.PARAMETER StrengthB
    Strength of B.

.PARAMETER ConfidenceB
    Confidence of B.

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-PLNAndIntroduction -StrengthA 0.9 -ConfidenceA 0.8 `
        -StrengthB 0.8 -ConfidenceB 0.75
#>
function Invoke-PLNAndIntroduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthA,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceA,
        [Parameter(Mandatory = $true)]  [double]$StrengthB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceB,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sA = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthA))
    $cA = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceA))
    $sB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthB))
    $cB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceB))
    $k  = [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    $sAnd = $sA * $sB
    $cAnd = [Math]::Min($cA, $cB) * $k

    return @{
        Rule       = 'AndIntroduction'
        Premises   = @("A (s=$sA, c=$cA)", "B (s=$sB, c=$cB)")
        Conclusion = 'A∧B'
        TruthValue = New-SimpleTruthValue -Strength $sAnd -Confidence $cAnd
    }
}

# ---------------------------------------------------------------------------
# OrIntroduction: A ⊢ A∨B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Introduce a disjunction: given A, conclude A∨B.

.DESCRIPTION
    PLN disjunction introduction:
      s(A∨B) = sA + sB - sA * sB   (inclusion-exclusion, assuming independence)
      c(A∨B) = min(cA, cB) * discount

    When B is unknown, sB defaults to 0.5.

.PARAMETER StrengthA
    Strength of A.

.PARAMETER ConfidenceA
    Confidence of A.

.PARAMETER StrengthB
    Strength of B (default 0.5 for unknown).

.PARAMETER ConfidenceB
    Confidence of B (default 0.5 for unknown).

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-PLNOrIntroduction -StrengthA 0.8 -ConfidenceA 0.9 `
        -StrengthB 0.6 -ConfidenceB 0.7
#>
function Invoke-PLNOrIntroduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthA,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceA,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$ConfidenceB = 0.5,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sA = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthA))
    $cA = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceA))
    $sB = [Math]::Max(0.0, [Math]::Min(1.0, $StrengthB))
    $cB = [Math]::Max(0.0, [Math]::Min(1.0, $ConfidenceB))
    $k  = [Math]::Max(0.0, [Math]::Min(1.0, $DiscountFactor))

    $sOr = [Math]::Max(0.0, [Math]::Min(1.0, ($sA + $sB - $sA * $sB)))
    $cOr = [Math]::Min($cA, $cB) * $k

    return @{
        Rule       = 'OrIntroduction'
        Premises   = @("A (s=$sA, c=$cA)", "B (s=$sB, c=$cB)")
        Conclusion = 'A∨B'
        TruthValue = New-SimpleTruthValue -Strength $sOr -Confidence $cOr
    }
}

# ---------------------------------------------------------------------------
# NotIntroduction: A ⊢ ¬A
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Introduce negation: given A, conclude ¬A (complement).

.DESCRIPTION
    PLN negation:
      s(¬A) = 1 - sA
      c(¬A) = cA  (confidence is unchanged)

.PARAMETER Strength
    Strength of A.

.PARAMETER Confidence
    Confidence of A.

.EXAMPLE
    $r = Invoke-PLNNotIntroduction -Strength 0.7 -Confidence 0.9
#>
function Invoke-PLNNotIntroduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [double]$Strength,
        [Parameter(Mandatory = $true)] [double]$Confidence
    )

    $sA = [Math]::Max(0.0, [Math]::Min(1.0, $Strength))
    $cA = [Math]::Max(0.0, [Math]::Min(1.0, $Confidence))

    return @{
        Rule       = 'NotIntroduction'
        Premises   = @("A (s=$sA, c=$cA)")
        Conclusion = '¬A'
        TruthValue = New-SimpleTruthValue -Strength (1.0 - $sA) -Confidence $cA
    }
}
