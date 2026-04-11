<#
.SYNOPSIS
    PLN Temporal Reasoning for OpenCog PowerShell

.DESCRIPTION
    Implements temporal reasoning capabilities for Probabilistic Logic Networks:

    - TemporalInterval class  : represents a time interval [Start, End]
    - Allen's interval algebra : 13 qualitative temporal relations
    - New-TemporalInterval    : factory for interval atoms
    - Get-AllenRelation       : compute Allen relation between two intervals
    - Invoke-TemporalDeduction: deduction with time-discounted confidence
    - New-EventAtom           : create a timestamped event atom
    - Invoke-TemporalProjection : project future event strength from trend

.NOTES
    Phase 5 — Advanced PLN Reasoning
    Version: 2.1.0
    Reference: Allen (1983) "Maintaining Knowledge about Temporal Intervals"
               Probabilistic Logic Networks (Goertzel et al.)
#>

# ---------------------------------------------------------------------------
# TemporalInterval class
# ---------------------------------------------------------------------------

class TemporalInterval {
    [double]$Start
    [double]$End

    TemporalInterval([double]$start, [double]$end) {
        if ($end -lt $start) {
            throw "Interval End ($end) must be >= Start ($start)"
        }
        $this.Start = $start
        $this.End   = $end
    }

    [double] Duration()  { return $this.End - $this.Start }
    [double] Midpoint()  { return ($this.Start + $this.End) / 2.0 }

    [bool] Contains([double]$t) {
        return ($t -ge $this.Start) -and ($t -le $this.End)
    }

    [string] ToString() {
        return "TemporalInterval([$([Math]::Round($this.Start,4)), $([Math]::Round($this.End,4))])"
    }
}

# ---------------------------------------------------------------------------
# Allen relation enumeration (string constants)
# ---------------------------------------------------------------------------

# All 13 Allen relations (plus Equals)
$script:AllenRelations = @(
    'Before',          # A precedes B: A.End < B.Start
    'After',           # A follows B: A.Start > B.End
    'Meets',           # A meets B: A.End = B.Start
    'MetBy',           # A is met by B: A.Start = B.End
    'Overlaps',        # A overlaps B: A starts before B, ends inside B
    'OverlappedBy',    # A is overlapped by B
    'Starts',          # A starts B: A.Start = B.Start, A.End < B.End
    'StartedBy',       # A is started by B
    'Finishes',        # A finishes B: A.End = B.End, A.Start > B.Start
    'FinishedBy',      # A is finished by B
    'During',          # A is inside B
    'Contains',        # A contains B
    'Equals'           # A = B
)

# ---------------------------------------------------------------------------
# Factory functions
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Create a TemporalInterval with a start and end time.

.PARAMETER Start
    Start time of the interval (any numeric unit).

.PARAMETER End
    End time of the interval (>= Start).

.EXAMPLE
    $meeting = New-TemporalInterval -Start 9.0 -End 10.5
#>
function New-TemporalInterval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [double]$Start,
        [Parameter(Mandatory = $true)] [double]$End
    )
    return [TemporalInterval]::new($Start, $End)
}

<#
.SYNOPSIS
    Create a named event atom with an associated temporal interval.

.DESCRIPTION
    An event atom is a hashtable combining a concept name, a temporal interval,
    and an optional truth value (strength, confidence).

.PARAMETER Name
    Name of the event / concept.

.PARAMETER Start
    Start time of the event.

.PARAMETER End
    End time of the event (>= Start).

.PARAMETER Strength
    Truth value strength (default 1.0).

.PARAMETER Confidence
    Truth value confidence (default 0.9).

.EXAMPLE
    $meeting = New-EventAtom -Name "MeetingA" -Start 9.0 -End 10.0 -Strength 0.95 -Confidence 0.9
#>
function New-EventAtom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$Name,
        [Parameter(Mandatory = $true)]  [double]$Start,
        [Parameter(Mandatory = $true)]  [double]$End,
        [Parameter(Mandatory = $false)] [double]$Strength = 1.0,
        [Parameter(Mandatory = $false)] [double]$Confidence = 0.9
    )

    $interval  = [TemporalInterval]::new($Start, $End)
    $tv        = New-SimpleTruthValue -Strength ([Math]::Max(0.0,[Math]::Min(1.0,$Strength))) `
                                      -Confidence ([Math]::Max(0.0,[Math]::Min(1.0,$Confidence)))

    return @{
        Name     = $Name
        Interval = $interval
        TV       = $tv
        Type     = 'EventAtom'
    }
}

# ---------------------------------------------------------------------------
# Allen's 13 relations
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Compute the Allen temporal relation between two TemporalIntervals.

.DESCRIPTION
    Returns one of the 13 Allen relation strings:
    Before, After, Meets, MetBy, Overlaps, OverlappedBy,
    Starts, StartedBy, Finishes, FinishedBy, During, Contains, Equals

    Uses a configurable epsilon for point-equality comparisons.

.PARAMETER IntervalA
    First TemporalInterval.

.PARAMETER IntervalB
    Second TemporalInterval.

.PARAMETER Epsilon
    Tolerance for equality comparisons (default 1e-9).

.EXAMPLE
    $a = New-TemporalInterval -Start 1 -End 3
    $b = New-TemporalInterval -Start 5 -End 8
    $rel = Get-AllenRelation -IntervalA $a -IntervalB $b
    # Returns 'Before'
#>
function Get-AllenRelation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [TemporalInterval]$IntervalA,
        [Parameter(Mandatory = $true)]  [TemporalInterval]$IntervalB,
        [Parameter(Mandatory = $false)] [double]$Epsilon = 1e-9
    )

    $as = $IntervalA.Start; $ae = $IntervalA.End
    $bs = $IntervalB.Start; $be = $IntervalB.End

    # Helper: near-equal within epsilon
    $eq = { param($x,$y) [Math]::Abs($x - $y) -le $Epsilon }

    # Equals
    if ((& $eq $as $bs) -and (& $eq $ae $be)) { return 'Equals' }

    # Before / After
    if ($ae -lt $bs - $Epsilon)  { return 'Before' }
    if ($as -gt $be + $Epsilon)  { return 'After'  }

    # Meets / MetBy
    if (& $eq $ae $bs)  { return 'Meets'  }
    if (& $eq $as $be)  { return 'MetBy'  }

    # Starts / StartedBy
    if ((& $eq $as $bs) -and ($ae -lt $be - $Epsilon)) { return 'Starts'    }
    if ((& $eq $as $bs) -and ($ae -gt $be + $Epsilon)) { return 'StartedBy' }

    # Finishes / FinishedBy
    if ((& $eq $ae $be) -and ($as -gt $bs + $Epsilon)) { return 'Finishes'   }
    if ((& $eq $ae $be) -and ($as -lt $bs - $Epsilon)) { return 'FinishedBy' }

    # During / Contains
    if (($as -gt $bs + $Epsilon) -and ($ae -lt $be - $Epsilon)) { return 'During'   }
    if (($as -lt $bs - $Epsilon) -and ($ae -gt $be + $Epsilon)) { return 'Contains' }

    # Overlaps / OverlappedBy
    if ($as -lt $bs -and $ae -gt $bs -and $ae -lt $be) { return 'Overlaps'    }
    if ($bs -lt $as -and $be -gt $as -and $be -lt $ae) { return 'OverlappedBy'}

    # Fallback (should not happen for well-formed intervals)
    return 'Unknown'
}

# ---------------------------------------------------------------------------
# Allen relation set — compute all relations between two interval sets
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Get all Allen relations between every pair from two interval lists.

.PARAMETER IntervalsA
    Array of TemporalInterval objects for the first set.

.PARAMETER IntervalsB
    Array of TemporalInterval objects for the second set.

.EXAMPLE
    $rels = Get-AllAllenRelations -IntervalsA @($a1, $a2) -IntervalsB @($b1, $b2)
#>
function Get-AllAllenRelations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [TemporalInterval[]]$IntervalsA,
        [Parameter(Mandatory = $true)] [TemporalInterval[]]$IntervalsB
    )

    $results = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($a in $IntervalsA) {
        foreach ($b in $IntervalsB) {
            $results.Add(@{
                IntervalA = $a
                IntervalB = $b
                Relation  = Get-AllenRelation -IntervalA $a -IntervalB $b
            })
        }
    }
    return $results
}

# ---------------------------------------------------------------------------
# TemporalDeduction: PLN deduction with time-decay confidence
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Apply PLN deduction with temporal confidence decay.

.DESCRIPTION
    Extends standard PLN deduction to account for temporal distance:
      c_decay = c_original * exp(-decay_rate * |t2 - t1|)

    A→B truth at time t1 and B→C truth at time t2 produce A→C with
    both the standard PLN deduction formula and a time-decay factor.

.PARAMETER StrengthAB
    Strength of A→B.

.PARAMETER ConfidenceAB
    Confidence of A→B.

.PARAMETER TimeAB
    Timestamp / reference time for A→B.

.PARAMETER StrengthBC
    Strength of B→C.

.PARAMETER ConfidenceBC
    Confidence of B→C.

.PARAMETER TimeBC
    Timestamp / reference time for B→C.

.PARAMETER StrengthB
    Marginal strength of B (default 0.5).

.PARAMETER StrengthC
    Marginal strength of C (default 0.5).

.PARAMETER DecayRate
    Exponential decay rate per unit time (default 0.05).

.PARAMETER DiscountFactor
    Standard PLN confidence discount (default 0.9).

.EXAMPLE
    $r = Invoke-TemporalDeduction -StrengthAB 0.9 -ConfidenceAB 0.85 -TimeAB 0 `
        -StrengthBC 0.8 -ConfidenceBC 0.8 -TimeBC 10 -DecayRate 0.02
#>
function Invoke-TemporalDeduction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthAB,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceAB,
        [Parameter(Mandatory = $true)]  [double]$TimeAB,
        [Parameter(Mandatory = $true)]  [double]$StrengthBC,
        [Parameter(Mandatory = $true)]  [double]$ConfidenceBC,
        [Parameter(Mandatory = $true)]  [double]$TimeBC,
        [Parameter(Mandatory = $false)] [double]$StrengthB = 0.5,
        [Parameter(Mandatory = $false)] [double]$StrengthC = 0.5,
        [Parameter(Mandatory = $false)] [double]$DecayRate = 0.05,
        [Parameter(Mandatory = $false)] [double]$DiscountFactor = 0.9
    )

    # Clamp
    $sAB = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthAB))
    $cAB = [Math]::Max(0.0,[Math]::Min(1.0,$ConfidenceAB))
    $sBC = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthBC))
    $cBC = [Math]::Max(0.0,[Math]::Min(1.0,$ConfidenceBC))
    $sB  = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthB))
    $sC  = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthC))
    $k   = [Math]::Max(0.0,[Math]::Min(1.0,$DiscountFactor))
    $dr  = [Math]::Max(0.0, $DecayRate)

    # Standard PLN deduction strength
    if ((1.0 - $sB) -lt 1e-10) {
        $sAC = $sAB * $sBC
    } else {
        $sAC = $sAB * $sBC + (1.0 - $sAB) * ($sC - $sB * $sBC) / (1.0 - $sB)
    }
    $sAC = [Math]::Max(0.0,[Math]::Min(1.0,$sAC))

    # Time decay: larger gap → lower confidence
    $timeDelta  = [Math]::Abs($TimeBC - $TimeAB)
    $decayFactor = [Math]::Exp(-$dr * $timeDelta)

    $cAC = [Math]::Min($cAB, $cBC) * $k * $decayFactor

    return @{
        Rule        = 'TemporalDeduction'
        Premises    = @("A→B (s=$sAB, c=$cAB, t=$TimeAB)", "B→C (s=$sBC, c=$cBC, t=$TimeBC)")
        Conclusion  = 'A→C'
        TruthValue  = New-SimpleTruthValue -Strength $sAC -Confidence $cAC
        TimeDelta   = $timeDelta
        DecayFactor = $decayFactor
    }
}

# ---------------------------------------------------------------------------
# TemporalProjection: project a future event from a trend
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Project the strength of an event at a future time using linear trend.

.DESCRIPTION
    Given two observations of an event at times t1 and t2 with strengths
    s1 and s2, this function projects the strength at a future time tFuture
    using linear extrapolation, clamped to [0,1].

    Confidence decays exponentially with the projection horizon.

.PARAMETER StrengthT1
    Observed strength at time T1.

.PARAMETER StrengthT2
    Observed strength at time T2 (T2 > T1).

.PARAMETER TimeT1
    First observation time.

.PARAMETER TimeT2
    Second observation time (must be > T1).

.PARAMETER TimeFuture
    Target future time for projection.

.PARAMETER ConfidenceBase
    Base confidence at the last observation (default 0.8).

.PARAMETER DecayRate
    Exponential decay rate of confidence per unit time (default 0.05).

.EXAMPLE
    # Event grew from 0.5 to 0.7 over 10 time units; project at t=20
    $r = Invoke-TemporalProjection -StrengthT1 0.5 -StrengthT2 0.7 `
        -TimeT1 0 -TimeT2 10 -TimeFuture 20
#>
function Invoke-TemporalProjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [double]$StrengthT1,
        [Parameter(Mandatory = $true)]  [double]$StrengthT2,
        [Parameter(Mandatory = $true)]  [double]$TimeT1,
        [Parameter(Mandatory = $true)]  [double]$TimeT2,
        [Parameter(Mandatory = $true)]  [double]$TimeFuture,
        [Parameter(Mandatory = $false)] [double]$ConfidenceBase = 0.8,
        [Parameter(Mandatory = $false)] [double]$DecayRate = 0.05
    )

    if ($TimeT2 -le $TimeT1) {
        throw "TimeT2 ($TimeT2) must be > TimeT1 ($TimeT1)"
    }
    if ($TimeFuture -le $TimeT2) {
        throw "TimeFuture ($TimeFuture) must be > TimeT2 ($TimeT2)"
    }

    $s1 = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthT1))
    $s2 = [Math]::Max(0.0,[Math]::Min(1.0,$StrengthT2))
    $cB = [Math]::Max(0.0,[Math]::Min(1.0,$ConfidenceBase))
    $dr = [Math]::Max(0.0, $DecayRate)

    # Linear slope per unit time
    $slope    = ($s2 - $s1) / ($TimeT2 - $TimeT1)
    $horizon  = $TimeFuture - $TimeT2
    $sFuture  = [Math]::Max(0.0, [Math]::Min(1.0, $s2 + $slope * $horizon))

    # Confidence decays with projection horizon
    $cFuture  = $cB * [Math]::Exp(-$dr * $horizon)
    $cFuture  = [Math]::Max(0.0, [Math]::Min(1.0, $cFuture))

    return @{
        Rule        = 'TemporalProjection'
        Premises    = @("s(t=$TimeT1)=$s1", "s(t=$TimeT2)=$s2")
        Conclusion  = "s(t=$TimeFuture)"
        Slope       = $slope
        Horizon     = $horizon
        TruthValue  = New-SimpleTruthValue -Strength $sFuture -Confidence $cFuture
    }
}

# ---------------------------------------------------------------------------
# Test whether two intervals overlap (Boolean)
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
    Test whether two TemporalIntervals overlap in time.

.PARAMETER IntervalA
    First TemporalInterval.

.PARAMETER IntervalB
    Second TemporalInterval.

.EXAMPLE
    Test-TemporalOverlap -IntervalA (New-TemporalInterval 1 5) `
                         -IntervalB (New-TemporalInterval 3 7)
    # Returns $true
#>
function Test-TemporalOverlap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [TemporalInterval]$IntervalA,
        [Parameter(Mandatory = $true)] [TemporalInterval]$IntervalB
    )
    return ($IntervalA.Start -le $IntervalB.End) -and ($IntervalA.End -ge $IntervalB.Start)
}
