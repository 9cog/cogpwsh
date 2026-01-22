<#
.SYNOPSIS
    Advanced Pattern Matching for OpenCog - Phase 3
    
.DESCRIPTION
    Implements advanced pattern matching capabilities including:
    - GetLink: Value extraction from patterns
    - BindLink: Pattern rewriting and transformation
    - SatisfactionLink: Boolean queries
    - DualLink: Dual queries
    - ChoiceLink: Alternative patterns
    - SequentialOrLink: Ordered disjunctions
    - AbsentLink: Negation-as-failure
    
.NOTES
    Part of OpenCog PowerShell Phase 3 implementation
#>

using module ./Atoms.psm1
using module ./AtomSpace.psm1
using module ./PatternMatcher.psm1

<#
.SYNOPSIS
    GetLink - Extract values from pattern matches
.DESCRIPTION
    GetLink executes a pattern and returns the specified atoms from successful matches
#>
class GetLink : Link {
    $VariableList    # ListLink of variables
    $Pattern         # Pattern to match
    $Output          # What to return
    
    GetLink($variableList, $pattern, $output) : base(@($variableList, $pattern, $output)) {
        $this.Type = [AtomType]::Link
        $this.VariableList = $variableList
        $this.Pattern = $pattern
        $this.Output = $output
        $this.SetMetadata('LinkSubType', 'GetLink')
    }
    
    [string] ToString() {
        return "(GetLink`n  Variables: {0}`n  Pattern: {1}`n  Output: {2})" -f `
            $this.VariableList.ToString(), $this.Pattern.ToString(), $this.Output.ToString()
    }
}

<#
.SYNOPSIS
    BindLink - Pattern rewriting and transformation
.DESCRIPTION
    BindLink matches patterns and rewrites them according to a template
#>
class BindLink : Link {
    $VariableList    # ListLink of variables
    $Pattern         # Pattern to match
    $Rewrite         # Rewrite template
    
    BindLink($variableList, $pattern, $rewrite) : base(@($variableList, $pattern, $rewrite)) {
        $this.Type = [AtomType]::Link
        $this.VariableList = $variableList
        $this.Pattern = $pattern
        $this.Rewrite = $rewrite
        $this.SetMetadata('LinkSubType', 'BindLink')
    }
    
    [string] ToString() {
        return "(BindLink`n  Variables: {0}`n  Pattern: {1}`n  Rewrite: {2})" -f `
            $this.VariableList.ToString(), $this.Pattern.ToString(), $this.Rewrite.ToString()
    }
}

<#
.SYNOPSIS
    SatisfactionLink - Boolean queries
.DESCRIPTION
    Returns true/false based on whether pattern has any groundings
#>
class SatisfactionLink : Link {
    $VariableList    # ListLink of variables
    $Pattern         # Pattern to satisfy
    
    SatisfactionLink($variableList, $pattern) : base(@($variableList, $pattern)) {
        $this.Type = [AtomType]::Link
        $this.VariableList = $variableList
        $this.Pattern = $pattern
        $this.SetMetadata('LinkSubType', 'SatisfactionLink')
    }
    
    [string] ToString() {
        return "(SatisfactionLink`n  Variables: {0}`n  Pattern: {1})" -f `
            $this.VariableList.ToString(), $this.Pattern.ToString()
    }
}

<#
.SYNOPSIS
    DualLink - Dual queries
.DESCRIPTION
    Matches patterns in both forward and backward directions
#>
class DualLink : Link {
    $Forward         # Forward pattern
    $Backward        # Backward pattern
    
    DualLink($forward, $backward) : base(@($forward, $backward)) {
        $this.Type = [AtomType]::Link
        $this.Forward = $forward
        $this.Backward = $backward
        $this.SetMetadata('LinkSubType', 'DualLink')
    }
    
    [string] ToString() {
        return "(DualLink`n  Forward: {0}`n  Backward: {1})" -f `
            $this.Forward.ToString(), $this.Backward.ToString()
    }
}

<#
.SYNOPSIS
    ChoiceLink - Alternative patterns
.DESCRIPTION
    Matches if any of the alternative patterns match
#>
class ChoiceLink : Link {
    [System.Collections.Generic.List[Atom]]$Alternatives
    
    ChoiceLink([Atom[]]$alternatives) : base($alternatives) {
        $this.Type = [AtomType]::Link
        $this.Alternatives = [System.Collections.Generic.List[Atom]]::new($alternatives)
        $this.SetMetadata('LinkSubType', 'ChoiceLink')
    }
    
    [string] ToString() {
        $altStr = ($this.Alternatives | ForEach-Object { $_.ToString() }) -join ', '
        return "(ChoiceLink {0})" -f $altStr
    }
}

<#
.SYNOPSIS
    SequentialOrLink - Ordered disjunctions
.DESCRIPTION
    Tries alternatives in order, returns first successful match
#>
class SequentialOrLink : Link {
    SequentialOrLink([Atom[]]$alternatives) : base($alternatives) {
        $this.Type = [AtomType]::Link
        $this.SetMetadata('LinkSubType', 'SequentialOrLink')
    }
    
    [string] ToString() {
        $altStr = ($this.Outgoing | ForEach-Object { $_.ToString() }) -join ' OR '
        return "(SequentialOrLink {0})" -f $altStr
    }
}

<#
.SYNOPSIS
    AbsentLink - Negation-as-failure
.DESCRIPTION
    Succeeds if pattern does NOT match (closed-world assumption)
#>
class AbsentLink : Link {
    $Pattern         # Pattern that should be absent
    
    AbsentLink($pattern) : base(@($pattern)) {
        $this.Type = [AtomType]::Link
        $this.Pattern = $pattern
        $this.SetMetadata('LinkSubType', 'AbsentLink')
    }
    
    [string] ToString() {
        return "(AbsentLink {0})" -f $this.Pattern.ToString()
    }
}

<#
.SYNOPSIS
    Advanced Pattern Matcher - Executor for advanced pattern links
#>
class AdvancedPatternMatcher {
    $AtomSpace
    $BasicMatcher
    
    AdvancedPatternMatcher($atomspace) {
        $this.AtomSpace = $atomspace
        $this.BasicMatcher = [PatternMatcher]::new($atomspace)
    }
    
    <#
    .SYNOPSIS
        Execute a GetLink query
    .RETURNS
        List of atoms matching the output specification
    #>
    [System.Collections.Generic.List[Atom]] ExecuteGetLink([GetLink]$getLink) {
        $results = [System.Collections.Generic.List[Atom]]::new()
        
        # Match the pattern to get variable bindings
        $bindings = $this.BasicMatcher.Match($getLink.Pattern)
        
        # For each binding, instantiate the output and collect results
        foreach ($binding in $bindings) {
            $instantiated = $this.InstantiatePattern($getLink.Output, $binding)
            if ($null -ne $instantiated) {
                $results.Add($instantiated)
            }
        }
        
        return $results
    }
    
    <#
    .SYNOPSIS
        Execute a BindLink query
    .RETURNS
        List of rewritten atoms added to AtomSpace
    #>
    [System.Collections.Generic.List[Atom]] ExecuteBindLink([BindLink]$bindLink) {
        $results = [System.Collections.Generic.List[Atom]]::new()
        
        # Match the pattern to get variable bindings
        $bindings = $this.BasicMatcher.Match($bindLink.Pattern)
        
        # For each binding, instantiate the rewrite template and add to AtomSpace
        foreach ($binding in $bindings) {
            $rewritten = $this.InstantiatePattern($bindLink.Rewrite, $binding)
            if ($null -ne $rewritten) {
                $this.AtomSpace.AddAtom($rewritten)
                $results.Add($rewritten)
            }
        }
        
        return $results
    }
    
    <#
    .SYNOPSIS
        Execute a SatisfactionLink query
    .RETURNS
        Boolean indicating if pattern has any groundings
    #>
    [bool] ExecuteSatisfactionLink([SatisfactionLink]$satLink) {
        $bindings = $this.BasicMatcher.Match($satLink.Pattern)
        return $bindings.Count -gt 0
    }
    
    <#
    .SYNOPSIS
        Execute a DualLink query
    .RETURNS
        List of matches from both forward and backward patterns
    #>
    [System.Collections.Generic.List[hashtable]] ExecuteDualLink([DualLink]$dualLink) {
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        # Execute forward pattern
        $forwardBindings = $this.BasicMatcher.Match($dualLink.Forward)
        foreach ($binding in $forwardBindings) {
            $results.Add($binding)
        }
        
        # Execute backward pattern
        $backwardBindings = $this.BasicMatcher.Match($dualLink.Backward)
        foreach ($binding in $backwardBindings) {
            $results.Add($binding)
        }
        
        return $results
    }
    
    <#
    .SYNOPSIS
        Execute a ChoiceLink query
    .RETURNS
        List of all matches from any alternative
    #>
    [System.Collections.Generic.List[hashtable]] ExecuteChoiceLink([ChoiceLink]$choiceLink) {
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        # Try each alternative and collect all matches
        foreach ($alternative in $choiceLink.Alternatives) {
            $bindings = $this.BasicMatcher.Match($alternative)
            foreach ($binding in $bindings) {
                $results.Add($binding)
            }
        }
        
        return $results
    }
    
    <#
    .SYNOPSIS
        Execute a SequentialOrLink query
    .RETURNS
        First successful match from alternatives (in order)
    #>
    [hashtable] ExecuteSequentialOrLink([SequentialOrLink]$seqOrLink) {
        # Try alternatives in order, return first success
        foreach ($alternative in $seqOrLink.Outgoing) {
            $bindings = $this.BasicMatcher.Match($alternative)
            if ($bindings.Count -gt 0) {
                return $bindings[0]  # Return first match
            }
        }
        
        return $null  # No match found
    }
    
    <#
    .SYNOPSIS
        Execute an AbsentLink query
    .RETURNS
        True if pattern is absent (does not match)
    #>
    [bool] ExecuteAbsentLink([AbsentLink]$absentLink) {
        $bindings = $this.BasicMatcher.Match($absentLink.Pattern)
        return $bindings.Count -eq 0  # Succeeds if NO matches
    }
    
    <#
    .SYNOPSIS
        Instantiate a pattern with variable bindings
    .RETURNS
        New atom with variables replaced by their bindings
    #>
    [Atom] InstantiatePattern($pattern, [hashtable]$bindings) {
        # If pattern is a variable, return its binding
        if ($pattern -is [Node] -and $pattern.Type -eq [AtomType]::VariableNode) {
            if ($bindings.ContainsKey($pattern.Name)) {
                return $bindings[$pattern.Name]
            }
            return $null
        }
        
        # If pattern is a node (non-variable), return as-is
        if ($pattern -is [Node]) {
            return $pattern
        }
        
        # If pattern is a link, recursively instantiate outgoing
        if ($pattern -is [Link]) {
            $instantiatedOutgoing = [System.Collections.Generic.List[Atom]]::new()
            
            foreach ($out in $pattern.Outgoing) {
                $instantiated = $this.InstantiatePattern($out, $bindings)
                if ($null -ne $instantiated) {
                    $instantiatedOutgoing.Add($instantiated)
                }
                else {
                    return $null  # Failed to instantiate
                }
            }
            
            # Create new link with instantiated outgoing
            $newLink = [Link]::new($instantiatedOutgoing.ToArray())
            $newLink.Type = $pattern.Type
            
            # Copy metadata
            foreach ($key in $pattern.Metadata.Keys) {
                $newLink.Metadata[$key] = $pattern.Metadata[$key]
            }
            
            return $newLink
        }
        
        return $null
    }
}

#region Factory Functions

<#
.SYNOPSIS
    Create a GetLink for value extraction
.PARAMETER VariableList
    ListLink containing variables
.PARAMETER Pattern
    Pattern to match
.PARAMETER Output
    Specification of what to return
.EXAMPLE
    $vars = New-ListLink @($varX, $varY)
    $pattern = New-InheritanceLink -Child $varX -Parent $varY
    $getLink = New-GetLink -VariableList $vars -Pattern $pattern -Output $varX
#>
function New-GetLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $VariableList,
        
        [Parameter(Mandatory = $true)]
        $Pattern,
        
        [Parameter(Mandatory = $true)]
        $Output
    )
    
    return [GetLink]::new($VariableList, $Pattern, $Output)
}

<#
.SYNOPSIS
    Create a BindLink for pattern rewriting
.PARAMETER VariableList
    ListLink containing variables
.PARAMETER Pattern
    Pattern to match
.PARAMETER Rewrite
    Template for rewriting matched patterns
.EXAMPLE
    $vars = New-ListLink @($varX)
    $pattern = New-InheritanceLink -Child $varX -Parent $animal
    $rewrite = New-InheritanceLink -Child $varX -Parent $livingThing
    $bindLink = New-BindLink -VariableList $vars -Pattern $pattern -Rewrite $rewrite
#>
function New-BindLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $VariableList,
        
        [Parameter(Mandatory = $true)]
        $Pattern,
        
        [Parameter(Mandatory = $true)]
        $Rewrite
    )
    
    return [BindLink]::new($VariableList, $Pattern, $Rewrite)
}

<#
.SYNOPSIS
    Create a SatisfactionLink for boolean queries
.PARAMETER VariableList
    ListLink containing variables
.PARAMETER Pattern
    Pattern to check for satisfaction
.EXAMPLE
    $vars = New-ListLink @($varX)
    $pattern = New-InheritanceLink -Child $varX -Parent $animal
    $satLink = New-SatisfactionLink -VariableList $vars -Pattern $pattern
#>
function New-SatisfactionLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $VariableList,
        
        [Parameter(Mandatory = $true)]
        $Pattern
    )
    
    return [SatisfactionLink]::new($VariableList, $Pattern)
}

<#
.SYNOPSIS
    Create a DualLink for bidirectional queries
.PARAMETER Forward
    Forward pattern
.PARAMETER Backward
    Backward pattern
.EXAMPLE
    $forward = New-InheritanceLink -Child $cat -Parent $animal
    $backward = New-InheritanceLink -Child $animal -Parent $livingThing
    $dualLink = New-DualLink -Forward $forward -Backward $backward
#>
function New-DualLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Forward,
        
        [Parameter(Mandatory = $true)]
        $Backward
    )
    
    return [DualLink]::new($Forward, $Backward)
}

<#
.SYNOPSIS
    Create a ChoiceLink for alternative patterns
.PARAMETER Alternatives
    Array of alternative patterns
.EXAMPLE
    $alt1 = New-InheritanceLink -Child $x -Parent $cat
    $alt2 = New-InheritanceLink -Child $x -Parent $dog
    $choiceLink = New-ChoiceLink -Alternatives @($alt1, $alt2)
#>
function New-ChoiceLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Atom[]]$Alternatives
    )
    
    return [ChoiceLink]::new($Alternatives)
}

<#
.SYNOPSIS
    Create a SequentialOrLink for ordered disjunctions
.PARAMETER Alternatives
    Array of alternative patterns (tried in order)
.EXAMPLE
    $alt1 = New-ConceptNode "FirstChoice"
    $alt2 = New-ConceptNode "SecondChoice"
    $seqOrLink = New-SequentialOrLink -Alternatives @($alt1, $alt2)
#>
function New-SequentialOrLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Atom[]]$Alternatives
    )
    
    return [SequentialOrLink]::new($Alternatives)
}

<#
.SYNOPSIS
    Create an AbsentLink for negation-as-failure
.PARAMETER Pattern
    Pattern that should be absent
.EXAMPLE
    $pattern = New-InheritanceLink -Child $cat -Parent $robot
    $absentLink = New-AbsentLink -Pattern $pattern
#>
function New-AbsentLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Pattern
    )
    
    return [AbsentLink]::new($Pattern)
}

<#
.SYNOPSIS
    Create an AdvancedPatternMatcher for executing advanced queries
.PARAMETER AtomSpace
    The AtomSpace to query
.EXAMPLE
    $kb = New-AtomSpace
    $matcher = New-AdvancedPatternMatcher -AtomSpace $kb
#>
function New-AdvancedPatternMatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $AtomSpace
    )
    
    return [AdvancedPatternMatcher]::new($AtomSpace)
}

<#
.SYNOPSIS
    Execute an advanced pattern link
.PARAMETER Matcher
    The AdvancedPatternMatcher instance
.PARAMETER PatternLink
    The pattern link to execute (GetLink, BindLink, etc.)
.EXAMPLE
    $results = Invoke-AdvancedPattern -Matcher $matcher -PatternLink $getLink
#>
function Invoke-AdvancedPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Matcher,
        
        [Parameter(Mandatory = $true)]
        $PatternLink
    )
    
    # Dispatch based on pattern link type
    $subType = $PatternLink.GetMetadata('LinkSubType')
    
    switch ($subType) {
        'GetLink' {
            return $Matcher.ExecuteGetLink($PatternLink)
        }
        'BindLink' {
            return $Matcher.ExecuteBindLink($PatternLink)
        }
        'SatisfactionLink' {
            return $Matcher.ExecuteSatisfactionLink($PatternLink)
        }
        'DualLink' {
            return $Matcher.ExecuteDualLink($PatternLink)
        }
        'ChoiceLink' {
            return $Matcher.ExecuteChoiceLink($PatternLink)
        }
        'SequentialOrLink' {
            return $Matcher.ExecuteSequentialOrLink($PatternLink)
        }
        'AbsentLink' {
            return $Matcher.ExecuteAbsentLink($PatternLink)
        }
        default {
            throw "Unknown pattern link type: $subType"
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-GetLink',
    'New-BindLink',
    'New-SatisfactionLink',
    'New-DualLink',
    'New-ChoiceLink',
    'New-SequentialOrLink',
    'New-AbsentLink',
    'New-AdvancedPatternMatcher',
    'Invoke-AdvancedPattern'
)
