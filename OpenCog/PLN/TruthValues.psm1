<#
.SYNOPSIS
    PLN Extended Truth Values for OpenCog PowerShell

.DESCRIPTION
    Implements extended truth value types for Probabilistic Logic Networks (PLN):
    - SimpleTruthValue    : (strength, confidence) — same semantics as core TruthValue
    - CountTruthValue     : (count, confidence) — derived from observation count
    - IndefiniteTruthValue: (L, U, confidence) — interval [L,U] with meta-confidence
    - FuzzyTruthValue     : (mean, stddev) — fuzzy membership with variance
    - ProbabilisticTruthValue : (count, probability) — based on raw event probability

    All types expose ToSimple() to convert to a (strength, confidence) pair,
    enabling interoperability with the core AtomSpace TruthValue.

.NOTES
    Phase 4 — PLN Infrastructure
    Version: 2.0.0
#>

# ---------------------------------------------------------------------------
# SimpleTruthValue
# ---------------------------------------------------------------------------

class SimpleTruthValue {
    [double]$Strength
    [double]$Confidence

    SimpleTruthValue([double]$strength, [double]$confidence) {
        $this.Strength    = [Math]::Max(0.0, [Math]::Min(1.0, $strength))
        $this.Confidence  = [Math]::Max(0.0, [Math]::Min(1.0, $confidence))
    }

    # Bayesian revision: merge two independent truth values
    static [SimpleTruthValue] Revise([SimpleTruthValue]$tv1, [SimpleTruthValue]$tv2) {
        $c1 = $tv1.Confidence
        $c2 = $tv2.Confidence
        $denom = $c1 + $c2 - $c1 * $c2
        if ($denom -lt 1e-10) { return [SimpleTruthValue]::new(0.5, 0.0) }
        $s = ($tv1.Strength * $c1 + $tv2.Strength * $c2 * (1.0 - $c1)) / $denom
        $c = $denom
        return [SimpleTruthValue]::new($s, $c)
    }

    [SimpleTruthValue] ToSimple() { return $this }

    [string] ToString() {
        return "SimpleTruthValue(s=$([Math]::Round($this.Strength,4)), c=$([Math]::Round($this.Confidence,4)))"
    }
}

# ---------------------------------------------------------------------------
# CountTruthValue
# ---------------------------------------------------------------------------

class CountTruthValue {
    [double]$Count
    [double]$Confidence

    CountTruthValue([double]$count, [double]$confidence) {
        if ($count -lt 0) { throw "Count must be >= 0" }
        $this.Count      = $count
        $this.Confidence = [Math]::Max(0.0, [Math]::Min(1.0, $confidence))
    }

    # Convert using the standard PLN count-to-strength formula:
    # strength = count / (count + k)  where k is a sensitivity constant (default 800)
    [SimpleTruthValue] ToSimple([double]$k) {
        $s = $this.Count / ($this.Count + $k)
        return [SimpleTruthValue]::new($s, $this.Confidence)
    }

    [SimpleTruthValue] ToSimple() { return $this.ToSimple(800.0) }

    [string] ToString() {
        return "CountTruthValue(n=$([Math]::Round($this.Count,2)), c=$([Math]::Round($this.Confidence,4)))"
    }
}

# ---------------------------------------------------------------------------
# IndefiniteTruthValue
# ---------------------------------------------------------------------------

class IndefiniteTruthValue {
    # [L, U] is the probability interval; Confidence is second-order confidence
    [double]$L
    [double]$U
    [double]$Confidence

    IndefiniteTruthValue([double]$l, [double]$u, [double]$confidence) {
        if ($l -gt $u) { throw "L must be <= U" }
        $this.L          = [Math]::Max(0.0, [Math]::Min(1.0, $l))
        $this.U          = [Math]::Max(0.0, [Math]::Min(1.0, $u))
        $this.Confidence = [Math]::Max(0.0, [Math]::Min(1.0, $confidence))
    }

    [double] Mean()   { return ($this.L + $this.U) / 2.0 }
    [double] Width()  { return $this.U - $this.L }

    [SimpleTruthValue] ToSimple() {
        return [SimpleTruthValue]::new($this.Mean(), $this.Confidence)
    }

    [string] ToString() {
        return "IndefiniteTruthValue([$([Math]::Round($this.L,4)), $([Math]::Round($this.U,4))], c=$([Math]::Round($this.Confidence,4)))"
    }
}

# ---------------------------------------------------------------------------
# FuzzyTruthValue
# ---------------------------------------------------------------------------

class FuzzyTruthValue {
    # Fuzzy membership: Mean (degree of membership) + StdDev (uncertainty)
    [double]$Mean
    [double]$StdDev

    FuzzyTruthValue([double]$mean, [double]$stddev) {
        $this.Mean   = [Math]::Max(0.0, [Math]::Min(1.0, $mean))
        $this.StdDev = [Math]::Max(0.0, $stddev)
    }

    # Confidence derived from standard deviation: c = 1 - min(1, 2*sigma)
    [double] Confidence() {
        return [Math]::Max(0.0, 1.0 - [Math]::Min(1.0, 2.0 * $this.StdDev))
    }

    [SimpleTruthValue] ToSimple() {
        return [SimpleTruthValue]::new($this.Mean, $this.Confidence())
    }

    # Fuzzy AND (minimum t-norm)
    static [FuzzyTruthValue] FuzzyAnd([FuzzyTruthValue]$a, [FuzzyTruthValue]$b) {
        $m = [Math]::Min($a.Mean, $b.Mean)
        $s = [Math]::Sqrt($a.StdDev * $a.StdDev + $b.StdDev * $b.StdDev)
        return [FuzzyTruthValue]::new($m, $s)
    }

    # Fuzzy OR (maximum t-conorm)
    static [FuzzyTruthValue] FuzzyOr([FuzzyTruthValue]$a, [FuzzyTruthValue]$b) {
        $m = [Math]::Max($a.Mean, $b.Mean)
        $s = [Math]::Sqrt($a.StdDev * $a.StdDev + $b.StdDev * $b.StdDev)
        return [FuzzyTruthValue]::new($m, $s)
    }

    # Fuzzy NOT (standard complement)
    static [FuzzyTruthValue] FuzzyNot([FuzzyTruthValue]$a) {
        return [FuzzyTruthValue]::new(1.0 - $a.Mean, $a.StdDev)
    }

    [string] ToString() {
        return "FuzzyTruthValue(mean=$([Math]::Round($this.Mean,4)), stddev=$([Math]::Round($this.StdDev,4)))"
    }
}

# ---------------------------------------------------------------------------
# ProbabilisticTruthValue
# ---------------------------------------------------------------------------

class ProbabilisticTruthValue {
    [double]$Count
    [double]$Probability

    ProbabilisticTruthValue([double]$count, [double]$probability) {
        if ($count -lt 0) { throw "Count must be >= 0" }
        $this.Count       = $count
        $this.Probability = [Math]::Max(0.0, [Math]::Min(1.0, $probability))
    }

    # Confidence from count using Wilson score interval width
    [double] Confidence() {
        if ($this.Count -lt 1.0) { return 0.0 }
        $n = $this.Count
        $p = $this.Probability
        # Simplified: confidence rises asymptotically toward 1.0 as count grows
        return $n / ($n + 1.0)
    }

    [SimpleTruthValue] ToSimple() {
        return [SimpleTruthValue]::new($this.Probability, $this.Confidence())
    }

    [string] ToString() {
        return "ProbabilisticTruthValue(n=$([Math]::Round($this.Count,2)), p=$([Math]::Round($this.Probability,4)))"
    }
}

# ---------------------------------------------------------------------------
# Factory functions
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Create a SimpleTruthValue.

.PARAMETER Strength
    Probability estimate in [0,1].

.PARAMETER Confidence
    Confidence in the estimate in [0,1].

.EXAMPLE
    $tv = New-SimpleTruthValue -Strength 0.8 -Confidence 0.9
#>
function New-SimpleTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Strength,

        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    return [SimpleTruthValue]::new($Strength, $Confidence)
}

<#
.SYNOPSIS
    Create a CountTruthValue from observation count and confidence.

.PARAMETER Count
    Number of positive observations (>= 0).

.PARAMETER Confidence
    Confidence in the estimate in [0,1].

.EXAMPLE
    $tv = New-CountTruthValue -Count 50 -Confidence 0.9
#>
function New-CountTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Count,

        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    return [CountTruthValue]::new($Count, $Confidence)
}

<#
.SYNOPSIS
    Create an IndefiniteTruthValue representing a probability interval [L, U].

.PARAMETER L
    Lower bound of the probability interval (0..1).

.PARAMETER U
    Upper bound of the probability interval (0..1, >= L).

.PARAMETER Confidence
    Second-order confidence in [0,1]. Default 0.9.

.EXAMPLE
    $tv = New-IndefiniteTruthValue -L 0.6 -U 0.9 -Confidence 0.85
#>
function New-IndefiniteTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$L,

        [Parameter(Mandatory = $true)]
        [double]$U,

        [Parameter(Mandatory = $false)]
        [double]$Confidence = 0.9
    )
    return [IndefiniteTruthValue]::new($L, $U, $Confidence)
}

<#
.SYNOPSIS
    Create a FuzzyTruthValue with fuzzy membership degree and uncertainty.

.PARAMETER Mean
    Fuzzy membership degree in [0,1].

.PARAMETER StdDev
    Standard deviation representing uncertainty (>= 0). Default 0.0.

.EXAMPLE
    $tv = New-FuzzyTruthValue -Mean 0.75 -StdDev 0.1
#>
function New-FuzzyTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Mean,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 0.0
    )
    return [FuzzyTruthValue]::new($Mean, $StdDev)
}

<#
.SYNOPSIS
    Create a ProbabilisticTruthValue from event count and probability.

.PARAMETER Count
    Total number of observations (>= 0).

.PARAMETER Probability
    Estimated probability in [0,1].

.EXAMPLE
    $tv = New-ProbabilisticTruthValue -Count 100 -Probability 0.7
#>
function New-ProbabilisticTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Count,

        [Parameter(Mandatory = $true)]
        [double]$Probability
    )
    return [ProbabilisticTruthValue]::new($Count, $Probability)
}

<#
.SYNOPSIS
    Revise two SimpleTruthValues using Bayesian revision.

.PARAMETER TV1
    First truth value.

.PARAMETER TV2
    Second truth value.

.EXAMPLE
    $merged = Invoke-TVRevision -TV1 $tv1 -TV2 $tv2
#>
function Invoke-TVRevision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SimpleTruthValue]$TV1,

        [Parameter(Mandatory = $true)]
        [SimpleTruthValue]$TV2
    )
    return [SimpleTruthValue]::Revise($TV1, $TV2)
}

<#
.SYNOPSIS
    Convert any PLN truth value type to a SimpleTruthValue.

.PARAMETER TruthValue
    Any PLN truth value object (SimpleTruthValue, CountTruthValue, etc.).

.EXAMPLE
    $simple = ConvertTo-SimpleTruthValue -TruthValue $countTV
#>
function ConvertTo-SimpleTruthValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TruthValue
    )
    if ($TruthValue -is [SimpleTruthValue]) { return $TruthValue }
    if ($null -ne ($TruthValue | Get-Member -Name 'ToSimple' -ErrorAction SilentlyContinue)) {
        return $TruthValue.ToSimple()
    }
    throw "Cannot convert type '$($TruthValue.GetType().Name)' to SimpleTruthValue"
}
