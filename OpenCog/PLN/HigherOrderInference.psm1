<#
.SYNOPSIS
    PLN Higher-Order Inference Rules for OpenCog PowerShell

.DESCRIPTION
    Implements higher-order PLN inference rules that operate on relationships
    between relationships:

    - InheritanceToSimilarity : A→B, B→A ⊢ A↔B
    - SimilarityToInheritance : A↔B ⊢ A→B
    - IntensionalInheritance  : shared predicates determine inheritance strength
    - ExtensionalInheritance  : shared set members determine inheritance strength
    - AttractorRule           : mutual high-strength links ⊢ attraction value
    - SymmetricSimilarity     : A↔B ⊢ B↔A (symmetry)

    All functions return a result hashtable:
      @{
          Rule       = <string>
          Premises   = <string[]>
          Conclusion = <string>
          TruthValue = <SimpleTruthValue>
      }

.NOTES
    Phase 5 — Advanced PLN Reasoning
    Version: 2.1.0
    Reference: Probabilistic Logic Networks (Goertzel et al.)
#>

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
function script:HOI_Clamp {
    param([double]$v)
    return [Math]::Max(0.0, [Math]::Min(1.0, $v))
}

function script:HOI_HarmonicMean {
    param([double]$a, [double]$b)
    if (($a + $b) -lt 1e-10) { return 0.0 }
    return (2.0 * $a * $b) / ($a + $b)
}

# ---------------------------------------------------------------------------
# InheritanceToSimilarity: A→B, B→A ⊢ A↔B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Derive A↔B similarity from A→B and B→A inheritance links.

.DESCRIPTION
    PLN inheritance-to-similarity:
      s(A↔B) = harmonic_mean(s(A→B), s(B→A))
      c(A↔B) = min(c(A→B), c(B→A)) * discount

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthBA
    Strength of B→A.

.PARAMETER ConfidenceBA
    Confidence of B→A.

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-InheritanceToSimilarity -StrengthAB 0.9 -ConfidenceAB 0.8 `
        -StrengthBA 0.85 -ConfidenceBA 0.75
#>
function Invoke-InheritanceToSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthBA,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBA,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB = script:HOI_Clamp $StrengthAB
    $cAB = script:HOI_Clamp $ConfidenceAB
    $sBA = script:HOI_Clamp $StrengthBA
    $cBA = script:HOI_Clamp $ConfidenceBA
    $k   = script:HOI_Clamp $DiscountFactor

    $sSim = script:HOI_HarmonicMean $sAB $sBA
    $cSim = [Math]::Min($cAB, $cBA) * $k

    return @{
        Rule       = 'InheritanceToSimilarity'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "B→A (s=$sBA, c=$cBA)")
        Conclusion = 'A↔B'
        TruthValue = New-SimpleTruthValue -Strength $sSim -Confidence $cSim
    }
}

# ---------------------------------------------------------------------------
# SimilarityToInheritance: A↔B ⊢ A→B
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Extract A→B inheritance from A↔B similarity.

.DESCRIPTION
    PLN similarity-to-inheritance:
      s(A→B) ≈ s(A↔B) * (1 + sB) / 2   (heuristic; favours common targets)
      Simplified: s(A→B) = s(A↔B)
      c(A→B) = c(A↔B) * discount

    The simplified form is used here for maximum generality.
    Callers may pass StrengthB to use the weighted formula.

.PARAMETER StrengthSim
    Strength of A↔B.

.PARAMETER ConfidenceSim
    Confidence of A↔B.

.PARAMETER StrengthB
    Optional marginal strength of B (default 0.5).

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-SimilarityToInheritance -StrengthSim 0.85 -ConfidenceSim 0.8
#>
function Invoke-SimilarityToInheritance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthSim,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceSim,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sSim = script:HOI_Clamp $StrengthSim
    $cSim = script:HOI_Clamp $ConfidenceSim
    $sB   = script:HOI_Clamp $StrengthB
    $k    = script:HOI_Clamp $DiscountFactor

    # Weighted formula: sim is symmetric so A→B strength is adjusted by P(B)
    $sAB = script:HOI_Clamp ($sSim * (1.0 + $sB) / 2.0)
    $cAB = $cSim * $k

    return @{
        Rule       = 'SimilarityToInheritance'
        Premises   = @("A↔B (s=$sSim, c=$cSim)")
        Conclusion = 'A→B'
        TruthValue = New-SimpleTruthValue -Strength $sAB -Confidence $cAB
    }
}

# ---------------------------------------------------------------------------
# IntensionalInheritance: predicate-overlap-based inheritance
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Compute intensional (predicate-overlap) inheritance strength A→B.

.DESCRIPTION
    Intensional inheritance measures how many predicates of A are also
    predicates of B:
      s_intensional(A→B) = |predicates(A) ∩ predicates(B)| / |predicates(A)|

    Inputs are provided as overlap count and total predicates of A.
    Confidence is provided directly.

.PARAMETER OverlapCount
    Number of predicates shared between A and B.

.PARAMETER TotalPredicatesA
    Total number of predicates of A.

.PARAMETER Confidence
    Confidence in the predicate counts (default 0.8).

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    # A has 10 predicates; 7 are also predicates of B
    $r = Invoke-IntensionalInheritance -OverlapCount 7 -TotalPredicatesA 10 -Confidence 0.9
#>
function Invoke-IntensionalInheritance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$OverlapCount,
        [Parameter(Mandatory = $true)]  [double]$TotalPredicatesA,
        [Parameter(Mandatory = $false)] [double]$Confidence = 0.8,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    if ($TotalPredicatesA -lt 1e-10) {
        return @{
            Rule       = 'IntensionalInheritance'
            Premises   = @("overlap=$OverlapCount", "|predicates(A)|=$TotalPredicatesA")
            Conclusion = 'A→B (intensional)'
            TruthValue = New-SimpleTruthValue -Strength 0.0 -Confidence 0.0
        }
    }

    $s = script:HOI_Clamp ($OverlapCount / $TotalPredicatesA)
    $c = script:HOI_Clamp ($Confidence * (script:HOI_Clamp $DiscountFactor))

    return @{
        Rule       = 'IntensionalInheritance'
        Premises   = @("overlap=$OverlapCount", "|predicates(A)|=$TotalPredicatesA")
        Conclusion = 'A→B (intensional)'
        TruthValue = New-SimpleTruthValue -Strength $s -Confidence $c
    }
}

# ---------------------------------------------------------------------------
# ExtensionalInheritance: set-overlap-based inheritance
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Compute extensional (set-overlap) inheritance strength A→B.

.DESCRIPTION
    Extensional inheritance measures how many members of A are also members of B:
      s_extensional(A→B) = |members(A) ∩ members(B)| / |members(A)|

    Inputs are provided as overlap count and total members of A.

.PARAMETER OverlapCount
    Number of members shared between A and B.

.PARAMETER TotalMembersA
    Total number of members of A (the subset candidate).

.PARAMETER Confidence
    Confidence in the member counts (default 0.8).

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    # A has 20 members; 15 are also in B
    $r = Invoke-ExtensionalInheritance -OverlapCount 15 -TotalMembersA 20 -Confidence 0.85
#>
function Invoke-ExtensionalInheritance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$OverlapCount,
        [Parameter(Mandatory = $true)]  [double]$TotalMembersA,
        [Parameter(Mandatory = $false)] [double]$Confidence = 0.8,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    if ($TotalMembersA -lt 1e-10) {
        return @{
            Rule       = 'ExtensionalInheritance'
            Premises   = @("overlap=$OverlapCount", "|members(A)|=$TotalMembersA")
            Conclusion = 'A→B (extensional)'
            TruthValue = New-SimpleTruthValue -Strength 0.0 -Confidence 0.0
        }
    }

    $s = script:HOI_Clamp ($OverlapCount / $TotalMembersA)
    $c = script:HOI_Clamp ($Confidence * (script:HOI_Clamp $DiscountFactor))

    return @{
        Rule       = 'ExtensionalInheritance'
        Premises   = @("overlap=$OverlapCount", "|members(A)|=$TotalMembersA")
        Conclusion = 'A→B (extensional)'
        TruthValue = New-SimpleTruthValue -Strength $s -Confidence $c
    }
}

# ---------------------------------------------------------------------------
# AttractorRule: A→B high, B→A high ⊢ high attraction
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Compute attraction between A and B from mutual inheritance.

.DESCRIPTION
    The attraction value captures mutual reinforcement between two concepts.
    PLN attraction:
      s_attr = s(A→B) * s(B→A)              (geometric mean of mutual strengths)
      c_attr = min(c(A→B), c(B→A)) * discount

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER StrengthBA
    Strength of B→A.

.PARAMETER ConfidenceBA
    Confidence of B→A.

.PARAMETER DiscountFactor
    Confidence discount factor. Default 0.9.

.EXAMPLE
    $r = Invoke-AttractorRule -StrengthAB 0.9 -ConfidenceAB 0.85 `
        -StrengthBA 0.8 -ConfidenceBA 0.75
#>
function Invoke-AttractorRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthBA,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBA,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    $sAB = script:HOI_Clamp $StrengthAB
    $cAB = script:HOI_Clamp $ConfidenceAB
    $sBA = script:HOI_Clamp $StrengthBA
    $cBA = script:HOI_Clamp $ConfidenceBA
    $k   = script:HOI_Clamp $DiscountFactor

    $sAttr = [Math]::Sqrt($sAB * $sBA)   # geometric mean
    $cAttr = [Math]::Min($cAB, $cBA) * $k

    return @{
        Rule       = 'Attractor'
        Premises   = @("A→B (s=$sAB, c=$cAB)", "B→A (s=$sBA, c=$cBA)")
        Conclusion = 'Attract(A,B)'
        TruthValue = New-SimpleTruthValue -Strength $sAttr -Confidence $cAttr
    }
}

# ---------------------------------------------------------------------------
# SymmetricSimilarity: A↔B ⊢ B↔A
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply symmetry of similarity: A↔B ⊢ B↔A.

.DESCRIPTION
    Similarity is inherently symmetric in PLN. This rule makes the symmetry
    explicit by returning the same truth value under the reversed conclusion.
    The confidence is unchanged; no discount is applied.

.PARAMETER StrengthSim
    Strength of A↔B.

.PARAMETER ConfidenceSim
    Confidence of A↔B.

.EXAMPLE
    $r = Invoke-SymmetricSimilarity -StrengthSim 0.85 -ConfidenceSim 0.9
#>
function Invoke-SymmetricSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [double]$StrengthSim,
        [Parameter(Mandatory = $true)] [double]$ConfidenceSim
    )

    $s = script:HOI_Clamp $StrengthSim
    $c = script:HOI_Clamp $ConfidenceSim

    return @{
        Rule       = 'SymmetricSimilarity'
        Premises   = @("A↔B (s=$s, c=$c)")
        Conclusion = 'B↔A'
        TruthValue = New-SimpleTruthValue -Strength $s -Confidence $c
    }
}

# ---------------------------------------------------------------------------
# Combine: merge intensional and extensional inheritance
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Combine intensional and extensional inheritance into a unified strength.

.DESCRIPTION
    OpenCog uses a weighted combination of intensional and extensional links:
      s_combined = w_int * s_int + w_ext * s_ext
    where w_int + w_ext = 1.  Default weights are equal (0.5 / 0.5).

    c_combined = min(c_int, c_ext)

.PARAMETER IntensionalStrength
    Strength from intensional analysis.

.PARAMETER IntensionalConfidence
    Confidence from intensional analysis.

.PARAMETER ExtensionalStrength
    Strength from extensional analysis.

.PARAMETER ExtensionalConfidence
    Confidence from extensional analysis.

.PARAMETER IntensionalWeight
    Weight for intensional component (default 0.5).

.EXAMPLE
    $r = Invoke-CombinedInheritance -IntensionalStrength 0.7 -IntensionalConfidence 0.8 `
        -ExtensionalStrength 0.85 -ExtensionalConfidence 0.9
#>
function Invoke-CombinedInheritance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$IntensionalStrength,
        [Parameter(Mandatory = $true)]  [double]$IntensionalConfidence,
        [Parameter(Mandatory = $true)]  [double]$ExtensionalStrength,
        [Parameter(Mandatory = $true)]  [double]$ExtensionalConfidence,
        [Parameter(Mandatory = $false)] [double]$IntensionalWeight = 0.5
    )

    $si  = script:HOI_Clamp $IntensionalStrength
    $ci  = script:HOI_Clamp $IntensionalConfidence
    $se  = script:HOI_Clamp $ExtensionalStrength
    $ce  = script:HOI_Clamp $ExtensionalConfidence
    $wi  = script:HOI_Clamp $IntensionalWeight
    $we  = 1.0 - $wi

    $sC = script:HOI_Clamp ($wi * $si + $we * $se)
    $cC = [Math]::Min($ci, $ce)

    return @{
        Rule       = 'CombinedInheritance'
        Premises   = @("Int (s=$si, c=$ci, w=$wi)", "Ext (s=$se, c=$ce, w=$we)")
        Conclusion = 'A→B (combined)'
        TruthValue = New-SimpleTruthValue -Strength $sC -Confidence $cC
    }
}
