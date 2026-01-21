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

# Export module members
Export-ModuleMember -Function @(
    'New-PatternMatcher',
    'Find-Pattern',
    'New-QueryBuilder',
    'Find-AtomsByPredicate',
    'Get-MatchResults',
    'Invoke-Query'
)
