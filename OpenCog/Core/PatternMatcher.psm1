<#
.SYNOPSIS
    Pattern Matching system for OpenCog
    
.DESCRIPTION
    Implements pattern matching and query capabilities for the AtomSpace.
    Supports variable binding, pattern templates, and query execution.
    
.NOTES
    Part of OpenCog PowerShell implementation
#>

using module ./Atoms.psm1
using module ./AtomSpace.psm1

<#
.SYNOPSIS
    Pattern matcher for finding atoms matching a template
#>
class PatternMatcher {
    [AtomSpace]$AtomSpace
    
    PatternMatcher([AtomSpace]$atomspace) {
        $this.AtomSpace = $atomspace
    }
    
    <#
    .SYNOPSIS
        Match a pattern against the AtomSpace
    .DESCRIPTION
        Finds all groundings (variable bindings) that match the pattern
    .PARAMETER Pattern
        The pattern to match (may contain VariableNodes)
    .RETURNS
        List of variable binding hashtables
    #>
    [System.Collections.Generic.List[hashtable]] Match([Atom]$pattern) {
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        # Extract variables from pattern
        $variables = $this.ExtractVariables($pattern)
        
        if ($variables.Count -eq 0) {
            # No variables, just check if pattern exists
            $found = $this.AtomSpace.FindEquivalentAtom($pattern)
            if ($null -ne $found) {
                $results.Add(@{})
            }
            return $results
        }
        
        # Try to match pattern with variable bindings
        $bindings = @{}
        $this.MatchRecursive($pattern, $null, $variables, $bindings, $results)
        
        return $results
    }
    
    <#
    .SYNOPSIS
        Recursively match pattern with candidate atoms
    #>
    [void] MatchRecursive([Atom]$pattern, [Atom]$candidate, 
                          [System.Collections.Generic.HashSet[string]]$variables,
                          [hashtable]$currentBindings,
                          [System.Collections.Generic.List[hashtable]]$results) {
        
        # If pattern is a variable
        if ($pattern -is [Node] -and $pattern.Type -eq [AtomType]::VariableNode) {
            $varName = $pattern.Name
            
            if ($currentBindings.ContainsKey($varName)) {
                # Variable already bound, check if it matches
                if ($null -ne $candidate -and $currentBindings[$varName].Equals($candidate)) {
                    # Binding consistent
                    return
                }
                else {
                    # Binding inconsistent, fail
                    return
                }
            }
            else {
                # Bind variable to candidate
                if ($null -ne $candidate) {
                    $currentBindings[$varName] = $candidate
                }
                return
            }
        }
        
        # If pattern is a node (non-variable)
        if ($pattern -is [Node]) {
            # Get candidate from AtomSpace
            $candidate = $this.AtomSpace.GetNode($pattern.Type, $pattern.Name)
            if ($null -ne $candidate) {
                # Found match, continue with complete bindings
                if ($currentBindings.Count -eq $variables.Count) {
                    $results.Add($currentBindings.Clone())
                }
            }
            return
        }
        
        # If pattern is a link
        if ($pattern -is [Link]) {
            # Get all links of same type
            $candidates = $this.AtomSpace.GetAtomsByType($pattern.Type)
            
            foreach ($candLink in $candidates) {
                if ($candLink -isnot [Link]) {
                    continue
                }
                
                # Check arity matches
                if ($candLink.GetArity() -ne $pattern.GetArity()) {
                    continue
                }
                
                # Try to match each outgoing atom
                $localBindings = $currentBindings.Clone()
                $success = $true
                
                for ($i = 0; $i -lt $pattern.GetArity(); $i++) {
                    $patternOut = $pattern.GetOutgoingAtom($i)
                    $candOut = $candLink.GetOutgoingAtom($i)
                    
                    if (-not $this.MatchAtoms($patternOut, $candOut, $localBindings)) {
                        $success = $false
                        break
                    }
                }
                
                if ($success) {
                    # Check if all variables are bound
                    if ($localBindings.Count -eq $variables.Count) {
                        $results.Add($localBindings)
                    }
                }
            }
        }
    }
    
    <#
    .SYNOPSIS
        Match two atoms with variable bindings
    #>
    [bool] MatchAtoms([Atom]$pattern, [Atom]$candidate, [hashtable]$bindings) {
        # If pattern is a variable
        if ($pattern -is [Node] -and $pattern.Type -eq [AtomType]::VariableNode) {
            $varName = $pattern.Name
            
            if ($bindings.ContainsKey($varName)) {
                # Check if binding is consistent
                return $bindings[$varName].Equals($candidate)
            }
            else {
                # Bind variable
                $bindings[$varName] = $candidate
                return $true
            }
        }
        
        # If pattern is a node
        if ($pattern -is [Node]) {
            if ($candidate -is [Node]) {
                return $pattern.Type -eq $candidate.Type -and $pattern.Name -eq $candidate.Name
            }
            return $false
        }
        
        # If pattern is a link
        if ($pattern -is [Link]) {
            if ($candidate -isnot [Link]) {
                return $false
            }
            
            # Check type and arity
            if ($pattern.Type -ne $candidate.Type -or 
                $pattern.GetArity() -ne $candidate.GetArity()) {
                return $false
            }
            
            # Match outgoing atoms recursively
            for ($i = 0; $i -lt $pattern.GetArity(); $i++) {
                if (-not $this.MatchAtoms($pattern.GetOutgoingAtom($i), 
                                         $candidate.GetOutgoingAtom($i), 
                                         $bindings)) {
                    return $false
                }
            }
            
            return $true
        }
        
        return $false
    }
    
    <#
    .SYNOPSIS
        Extract all variable nodes from a pattern
    #>
    [System.Collections.Generic.HashSet[string]] ExtractVariables([Atom]$pattern) {
        $variables = [System.Collections.Generic.HashSet[string]]::new()
        $this.ExtractVariablesRecursive($pattern, $variables)
        return $variables
    }
    
    [void] ExtractVariablesRecursive([Atom]$atom, [System.Collections.Generic.HashSet[string]]$variables) {
        if ($atom -is [Node] -and $atom.Type -eq [AtomType]::VariableNode) {
            [void]$variables.Add($atom.Name)
        }
        elseif ($atom -is [Link]) {
            foreach ($outAtom in $atom.GetOutgoingSet()) {
                $this.ExtractVariablesRecursive($outAtom, $variables)
            }
        }
    }
    
    <#
    .SYNOPSIS
        Find all atoms matching a simple query
    #>
    [System.Collections.Generic.List[Atom]] QueryByType([AtomType]$type) {
        return $this.AtomSpace.GetAtomsByType($type)
    }
    
    <#
    .SYNOPSIS
        Find all links containing a specific atom
    #>
    [System.Collections.Generic.List[Link]] QueryIncoming([Atom]$atom) {
        return $this.AtomSpace.GetIncomingSet($atom)
    }
    
    <#
    .SYNOPSIS
        Find all atoms matching a predicate function
    #>
    [System.Collections.Generic.List[Atom]] QueryByPredicate([scriptblock]$predicate) {
        $results = [System.Collections.Generic.List[Atom]]::new()
        
        foreach ($atom in $this.AtomSpace.GetAllAtoms()) {
            if ($predicate.Invoke($atom)) {
                $results.Add($atom)
            }
        }
        
        return $results
    }
}

<#
.SYNOPSIS
    Query builder for constructing complex queries
#>
class QueryBuilder {
    [AtomSpace]$AtomSpace
    [Atom]$Pattern
    [scriptblock]$Filter
    
    QueryBuilder([AtomSpace]$atomspace) {
        $this.AtomSpace = $atomspace
    }
    
    [QueryBuilder] WithPattern([Atom]$pattern) {
        $this.Pattern = $pattern
        return $this
    }
    
    [QueryBuilder] WithFilter([scriptblock]$filter) {
        $this.Filter = $filter
        return $this
    }
    
    [System.Collections.Generic.List[hashtable]] Execute() {
        $matcher = [PatternMatcher]::new($this.AtomSpace)
        $results = $matcher.Match($this.Pattern)
        
        if ($null -ne $this.Filter) {
            $filtered = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($binding in $results) {
                if ($this.Filter.Invoke($binding)) {
                    $filtered.Add($binding)
                }
            }
            return $filtered
        }
        
        return $results
    }
}

#region Phase 3 - Advanced Pattern Matcher

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
    [System.Collections.Generic.List[Atom]] ExecuteGetLink($getLink) {
        $results = [System.Collections.Generic.List[Atom]]::new()
        
        # Get components from metadata
        $pattern = $getLink.GetMetadata('Pattern')
        $output = $getLink.GetMetadata('Output')
        
        # Match the pattern to get variable bindings
        $bindings = $this.BasicMatcher.Match($pattern)
        
        # For each binding, instantiate the output and collect results
        foreach ($binding in $bindings) {
            $instantiated = $this.InstantiatePattern($output, $binding)
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
    [System.Collections.Generic.List[Atom]] ExecuteBindLink($bindLink) {
        $results = [System.Collections.Generic.List[Atom]]::new()
        
        # Get components from metadata
        $pattern = $bindLink.GetMetadata('Pattern')
        $rewrite = $bindLink.GetMetadata('Rewrite')
        
        # Match the pattern to get variable bindings
        $bindings = $this.BasicMatcher.Match($pattern)
        
        # For each binding, instantiate the rewrite template and add to AtomSpace
        foreach ($binding in $bindings) {
            $rewritten = $this.InstantiatePattern($rewrite, $binding)
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
    [bool] ExecuteSatisfactionLink($satLink) {
        $pattern = $satLink.GetMetadata('Pattern')
        $bindings = $this.BasicMatcher.Match($pattern)
        return $bindings.Count -gt 0
    }
    
    <#
    .SYNOPSIS
        Execute a DualLink query
    .RETURNS
        List of matches from both forward and backward patterns
    #>
    [System.Collections.Generic.List[hashtable]] ExecuteDualLink($dualLink) {
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        # Get components from metadata
        $forward = $dualLink.GetMetadata('Forward')
        $backward = $dualLink.GetMetadata('Backward')
        
        # Execute forward pattern
        $forwardBindings = $this.BasicMatcher.Match($forward)
        foreach ($binding in $forwardBindings) {
            $results.Add($binding)
        }
        
        # Execute backward pattern
        $backwardBindings = $this.BasicMatcher.Match($backward)
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
    [System.Collections.Generic.List[hashtable]] ExecuteChoiceLink($choiceLink) {
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        # Try each alternative and collect all matches
        # Alternatives are stored in the outgoing set
        foreach ($alternative in $choiceLink.Outgoing) {
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
    [hashtable] ExecuteSequentialOrLink($seqOrLink) {
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
    [bool] ExecuteAbsentLink($absentLink) {
        $pattern = $absentLink.GetMetadata('Pattern')
        $bindings = $this.BasicMatcher.Match($pattern)
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

#endregion

# PowerShell functions for pattern matching

function New-PatternMatcher {
    <#
    .SYNOPSIS
        Creates a new pattern matcher for an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to search
    .EXAMPLE
        $matcher = New-PatternMatcher -AtomSpace $space
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace
    )
    
    return [PatternMatcher]::new($AtomSpace)
}

function Find-Pattern {
    <#
    .SYNOPSIS
        Finds all matches for a pattern in an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Pattern
        The pattern to match (may contain VariableNodes)
    .EXAMPLE
        # Find all inheritance relationships
        $var = New-VariableNode '$x'
        $pattern = New-InheritanceLink -Child $var -Parent (New-ConceptNode "Animal")
        $matches = Find-Pattern -AtomSpace $space -Pattern $pattern
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [Atom]$Pattern
    )
    
    $matcher = [PatternMatcher]::new($AtomSpace)
    return $matcher.Match($Pattern)
}

function New-QueryBuilder {
    <#
    .SYNOPSIS
        Creates a new query builder for complex queries
    .PARAMETER AtomSpace
        The AtomSpace to query
    .EXAMPLE
        $query = New-QueryBuilder -AtomSpace $space
        $results = $query.WithPattern($pattern).Execute()
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace
    )
    
    return [QueryBuilder]::new($AtomSpace)
}

function Find-AtomsByPredicate {
    <#
    .SYNOPSIS
        Finds atoms matching a predicate function
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Predicate
        A scriptblock that takes an atom and returns true/false
    .EXAMPLE
        # Find all atoms with high confidence
        $highConf = Find-AtomsByPredicate -AtomSpace $space -Predicate {
            param($atom)
            $atom.GetTruthValue().Confidence -gt 0.8
        }
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [scriptblock]$Predicate
    )
    
    $matcher = [PatternMatcher]::new($AtomSpace)
    return $matcher.QueryByPredicate($Predicate)
}

function Get-MatchResults {
    <#
    .SYNOPSIS
        Pretty prints match results from pattern matching
    .PARAMETER Results
        The results from Find-Pattern
    .EXAMPLE
        $matches = Find-Pattern -AtomSpace $space -Pattern $pattern
        Get-MatchResults -Results $matches
    #>
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[hashtable]]$Results
    )
    
    if ($Results.Count -eq 0) {
        Write-Host "No matches found."
        return
    }
    
    Write-Host "Found $($Results.Count) match(es):"
    $i = 1
    foreach ($binding in $Results) {
        Write-Host "`nMatch $($i):"
        foreach ($key in $binding.Keys) {
            Write-Host "  $key = $($binding[$key].ToString())"
        }
        $i++
    }
}

function Invoke-Query {
    <#
    .SYNOPSIS
        Executes a query against an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to query
    .PARAMETER Pattern
        The pattern to match
    .PARAMETER Filter
        Optional filter scriptblock
    .PARAMETER ShowResults
        If true, displays results formatted
    .EXAMPLE
        $results = Invoke-Query -AtomSpace $space -Pattern $pattern -ShowResults
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [Atom]$Pattern,
        
        [scriptblock]$Filter,
        
        [switch]$ShowResults
    )
    
    $matcher = [PatternMatcher]::new($AtomSpace)
    $results = $matcher.Match($Pattern)
    
    if ($null -ne $Filter) {
        $filtered = [System.Collections.Generic.List[hashtable]]::new()
        foreach ($binding in $results) {
            if ($Filter.Invoke($binding)) {
                $filtered.Add($binding)
            }
        }
        $results = $filtered
    }
    
    if ($ShowResults) {
        Get-MatchResults -Results $results
    }
    
    return $results
}

#region Phase 3 - Advanced Pattern Matching Functions

<#
.SYNOPSIS
    Execute an advanced pattern link
.PARAMETER AtomSpace
    The AtomSpace to query
.PARAMETER PatternLink
    The pattern link to execute (GetLink, BindLink, etc.)
.EXAMPLE
    $results = Invoke-AdvancedPattern -AtomSpace $kb -PatternLink $getLink
#>
function Invoke-AdvancedPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $AtomSpace,
        
        [Parameter(Mandatory = $true)]
        $PatternLink
    )
    
    # Get the pattern link subtype and dispatch based on it
    $subType = $PatternLink.GetMetadata('LinkSubType')
    
    switch ($subType) {
        'GetLink' {
            # Execute GetLink - extract values
            $results = [System.Collections.Generic.List[Atom]]::new()
            $pattern = $PatternLink.GetMetadata('Pattern')
            $output = $PatternLink.GetMetadata('Output')
            $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $pattern
            
            foreach ($binding in $bindings) {
                $instantiated = Invoke-PatternInstantiation -Pattern $output -Bindings $binding
                if ($null -ne $instantiated) {
                    $results.Add($instantiated)
                }
            }
            return $results
        }
        'BindLink' {
            # Execute BindLink - pattern rewriting
            $results = [System.Collections.Generic.List[Atom]]::new()
            $pattern = $PatternLink.GetMetadata('Pattern')
            $rewrite = $PatternLink.GetMetadata('Rewrite')
            $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $pattern
            
            foreach ($binding in $bindings) {
                $rewritten = Invoke-PatternInstantiation -Pattern $rewrite -Bindings $binding
                if ($null -ne $rewritten) {
                    $AtomSpace.AddAtom($rewritten)
                    $results.Add($rewritten)
                }
            }
            return $results
        }
        'SatisfactionLink' {
            # Execute SatisfactionLink - boolean query
            $pattern = $PatternLink.GetMetadata('Pattern')
            $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $pattern
            return $bindings.Count -gt 0
        }
        'DualLink' {
            # Execute DualLink - bidirectional
            $results = [System.Collections.Generic.List[hashtable]]::new()
            $forward = $PatternLink.GetMetadata('Forward')
            $backward = $PatternLink.GetMetadata('Backward')
            
            $forwardBindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $forward
            foreach ($binding in $forwardBindings) {
                $results.Add($binding)
            }
            
            $backwardBindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $backward
            foreach ($binding in $backwardBindings) {
                $results.Add($binding)
            }
            return $results
        }
        'ChoiceLink' {
            # Execute ChoiceLink - alternatives
            $results = [System.Collections.Generic.List[hashtable]]::new()
            
            foreach ($alternative in $PatternLink.Outgoing) {
                $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $alternative
                foreach ($binding in $bindings) {
                    $results.Add($binding)
                }
            }
            return $results
        }
        'SequentialOrLink' {
            # Execute SequentialOrLink - first match
            foreach ($alternative in $PatternLink.Outgoing) {
                $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $alternative
                if ($bindings.Count -gt 0) {
                    return $bindings[0]
                }
            }
            return $null
        }
        'AbsentLink' {
            # Execute AbsentLink - negation
            $pattern = $PatternLink.GetMetadata('Pattern')
            $bindings = Find-Pattern -AtomSpace $AtomSpace -Pattern $pattern
            return $bindings.Count -eq 0
        }
        default {
            throw "Unknown pattern link type: $subType"
        }
    }
}

<#
.SYNOPSIS
    Instantiate a pattern with variable bindings (helper function)
.PARAMETER Pattern
    The pattern to instantiate
.PARAMETER Bindings
    Hashtable of variable bindings
.RETURNS
    New atom with variables replaced by their bindings
#>
function Invoke-PatternInstantiation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Pattern,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Bindings
    )
    
    # If pattern is a variable, return its binding
    if ($Pattern -is [Node] -and $Pattern.Type -eq [AtomType]::VariableNode) {
        if ($Bindings.ContainsKey($Pattern.Name)) {
            return $Bindings[$Pattern.Name]
        }
        return $null
    }
    
    # If pattern is a node (non-variable), return as-is
    if ($Pattern -is [Node]) {
        return $Pattern
    }
    
    # If pattern is a link, recursively instantiate outgoing
    if ($Pattern -is [Link]) {
        $instantiatedOutgoing = [System.Collections.Generic.List[Atom]]::new()
        
        foreach ($out in $Pattern.Outgoing) {
            $instantiated = Invoke-PatternInstantiation -Pattern $out -Bindings $Bindings
            if ($null -ne $instantiated) {
                $instantiatedOutgoing.Add($instantiated)
            }
            else {
                return $null  # Failed to instantiate
            }
        }
        
        # Create new link with instantiated outgoing
        $newLink = [Link]::new($instantiatedOutgoing.ToArray())
        $newLink.Type = $Pattern.Type
        
        # Copy metadata
        foreach ($key in $Pattern.Metadata.Keys) {
            $newLink.Metadata[$key] = $Pattern.Metadata[$key]
        }
        
        return $newLink
    }
    
    return $null
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-PatternMatcher',
    'Find-Pattern',
    'New-QueryBuilder',
    'Find-AtomsByPredicate',
    'Get-MatchResults',
    'Invoke-Query',
    # Phase 3 - Advanced Pattern Matching
    'Invoke-AdvancedPattern',
    'Invoke-PatternInstantiation'
)
