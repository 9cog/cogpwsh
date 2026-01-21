<#
.SYNOPSIS
    AtomSpace - Hypergraph-based knowledge representation system
    
.DESCRIPTION
    The AtomSpace is the central knowledge repository in OpenCog.
    It stores atoms in a hypergraph structure and provides efficient
    querying, indexing, and relationship management.
    
.NOTES
    Part of OpenCog PowerShell implementation
#>

using module ./Atoms.psm1

<#
.SYNOPSIS
    AtomSpace class - the hypergraph knowledge base
#>
class AtomSpace {
    # Internal storage
    [hashtable]$AtomsByHandle
    [hashtable]$AtomsByType
    [hashtable]$NodesByName
    [hashtable]$IncomingIndex
    [int]$AtomCount
    
    AtomSpace() {
        $this.AtomsByHandle = @{}
        $this.AtomsByType = @{}
        $this.NodesByName = @{}
        $this.IncomingIndex = @{}
        $this.AtomCount = 0
    }
    
    <#
    .SYNOPSIS
        Add an atom to the AtomSpace
    .DESCRIPTION
        Adds an atom to the AtomSpace. If an equivalent atom already exists,
        merges the truth values and returns the existing atom.
    #>
    [Atom] AddAtom([Atom]$atom) {
        if ($null -eq $atom) {
            throw "Cannot add null atom"
        }
        
        # Check if equivalent atom exists
        $existing = $this.FindEquivalentAtom($atom)
        if ($null -ne $existing) {
            # Merge truth values
            $mergedTV = $existing.GetTruthValue().Merge($atom.GetTruthValue())
            $existing.TV = $mergedTV
            return $existing
        }
        
        # Add new atom
        $this.AtomsByHandle[$atom.Handle] = $atom
        
        # Index by type
        if (-not $this.AtomsByType.ContainsKey($atom.Type)) {
            $this.AtomsByType[$atom.Type] = [System.Collections.Generic.List[Atom]]::new()
        }
        $this.AtomsByType[$atom.Type].Add($atom)
        
        # Index nodes by name
        if ($atom -is [Node]) {
            $key = "$($atom.Type):$($atom.Name)"
            $this.NodesByName[$key] = $atom
        }
        
        # Update incoming index for links
        if ($atom -is [Link]) {
            foreach ($outAtom in $atom.GetOutgoingSet()) {
                $outHandle = $outAtom.GetHandle()
                if (-not $this.IncomingIndex.ContainsKey($outHandle)) {
                    $this.IncomingIndex[$outHandle] = [System.Collections.Generic.List[Link]]::new()
                }
                $this.IncomingIndex[$outHandle].Add($atom)
            }
        }
        
        $this.AtomCount++
        return $atom
    }
    
    <#
    .SYNOPSIS
        Find an atom equivalent to the given atom
    #>
    [Atom] FindEquivalentAtom([Atom]$atom) {
        if ($atom -is [Node]) {
            $key = "$($atom.Type):$($atom.Name)"
            return $this.NodesByName[$key]
        }
        elseif ($atom -is [Link]) {
            # Search through links of same type
            if ($this.AtomsByType.ContainsKey($atom.Type)) {
                foreach ($existing in $this.AtomsByType[$atom.Type]) {
                    if ($atom.Equals($existing)) {
                        return $existing
                    }
                }
            }
        }
        return $null
    }
    
    <#
    .SYNOPSIS
        Get an atom by its handle
    #>
    [Atom] GetAtom([guid]$handle) {
        return $this.AtomsByHandle[$handle]
    }
    
    <#
    .SYNOPSIS
        Remove an atom from the AtomSpace
    #>
    [bool] RemoveAtom([Atom]$atom) {
        if ($null -eq $atom) {
            return $false
        }
        
        $handle = $atom.GetHandle()
        if (-not $this.AtomsByHandle.ContainsKey($handle)) {
            return $false
        }
        
        # Remove from handle index
        $this.AtomsByHandle.Remove($handle)
        
        # Remove from type index
        if ($this.AtomsByType.ContainsKey($atom.Type)) {
            $this.AtomsByType[$atom.Type].Remove($atom)
        }
        
        # Remove from name index
        if ($atom -is [Node]) {
            $key = "$($atom.Type):$($atom.Name)"
            $this.NodesByName.Remove($key)
        }
        
        # Update incoming index
        if ($atom -is [Link]) {
            foreach ($outAtom in $atom.GetOutgoingSet()) {
                $outHandle = $outAtom.GetHandle()
                if ($this.IncomingIndex.ContainsKey($outHandle)) {
                    $this.IncomingIndex[$outHandle].Remove($atom)
                }
            }
        }
        
        # Remove from incoming index
        if ($this.IncomingIndex.ContainsKey($handle)) {
            $this.IncomingIndex.Remove($handle)
        }
        
        $this.AtomCount--
        return $true
    }
    
    <#
    .SYNOPSIS
        Get all atoms of a specific type
    #>
    [System.Collections.Generic.List[Atom]] GetAtomsByType([AtomType]$type) {
        if ($this.AtomsByType.ContainsKey($type)) {
            return $this.AtomsByType[$type]
        }
        return [System.Collections.Generic.List[Atom]]::new()
    }
    
    [System.Collections.Generic.List[Atom]] GetAtomsByType([string]$typeName) {
        $type = [AtomType]::$typeName
        return $this.GetAtomsByType($type)
    }
    
    <#
    .SYNOPSIS
        Get a node by type and name
    #>
    [Node] GetNode([AtomType]$type, [string]$name) {
        $key = "$($type):$($name)"
        return $this.NodesByName[$key]
    }
    
    <#
    .SYNOPSIS
        Get all links that contain the given atom in their outgoing set
    #>
    [System.Collections.Generic.List[Link]] GetIncomingSet([Atom]$atom) {
        $handle = $atom.GetHandle()
        if ($this.IncomingIndex.ContainsKey($handle)) {
            return $this.IncomingIndex[$handle]
        }
        return [System.Collections.Generic.List[Link]]::new()
    }
    
    <#
    .SYNOPSIS
        Get all atoms in the AtomSpace
    #>
    [System.Collections.Generic.List[Atom]] GetAllAtoms() {
        return [System.Collections.Generic.List[Atom]]::new($this.AtomsByHandle.Values)
    }
    
    <#
    .SYNOPSIS
        Clear all atoms from the AtomSpace
    #>
    [void] Clear() {
        $this.AtomsByHandle.Clear()
        $this.AtomsByType.Clear()
        $this.NodesByName.Clear()
        $this.IncomingIndex.Clear()
        $this.AtomCount = 0
    }
    
    <#
    .SYNOPSIS
        Get the number of atoms in the AtomSpace
    #>
    [int] GetSize() {
        return $this.AtomCount
    }
    
    <#
    .SYNOPSIS
        Check if an atom is in the AtomSpace
    #>
    [bool] Contains([Atom]$atom) {
        if ($null -eq $atom) {
            return $false
        }
        return $this.AtomsByHandle.ContainsKey($atom.GetHandle())
    }
    
    <#
    .SYNOPSIS
        Get statistics about the AtomSpace
    #>
    [hashtable] GetStatistics() {
        $stats = @{
            TotalAtoms = $this.AtomCount
            AtomsByType = @{}
            NodeCount = 0
            LinkCount = 0
        }
        
        foreach ($type in $this.AtomsByType.Keys) {
            $count = $this.AtomsByType[$type].Count
            $stats.AtomsByType[$type] = $count
            
            # Sample first atom to determine if Node or Link
            if ($count -gt 0) {
                $sample = $this.AtomsByType[$type][0]
                if ($sample -is [Node]) {
                    $stats.NodeCount += $count
                }
                elseif ($sample -is [Link]) {
                    $stats.LinkCount += $count
                }
            }
        }
        
        return $stats
    }
    
    <#
    .SYNOPSIS
        Pretty print the AtomSpace contents
    #>
    [string] ToString() {
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine("AtomSpace ($(($this.AtomCount)) atoms):")
        
        foreach ($atom in $this.GetAllAtoms()) {
            [void]$sb.AppendLine("  $($atom.ToString())")
        }
        
        return $sb.ToString()
    }
    
    <#
    .SYNOPSIS
        Export AtomSpace to a structured format
    #>
    [hashtable] Export() {
        $export = @{
            Nodes = @()
            Links = @()
        }
        
        foreach ($atom in $this.GetAllAtoms()) {
            if ($atom -is [Node]) {
                $export.Nodes += @{
                    Type = $atom.Type
                    Name = $atom.Name
                    Handle = $atom.Handle
                    TruthValue = @{
                        Strength = $atom.TV.Strength
                        Confidence = $atom.TV.Confidence
                    }
                }
            }
            elseif ($atom -is [Link]) {
                $outgoing = @()
                foreach ($out in $atom.GetOutgoingSet()) {
                    $outgoing += $out.Handle
                }
                
                $export.Links += @{
                    Type = $atom.Type
                    Outgoing = $outgoing
                    Handle = $atom.Handle
                    TruthValue = @{
                        Strength = $atom.TV.Strength
                        Confidence = $atom.TV.Confidence
                    }
                }
            }
        }
        
        return $export
    }
}

# PowerShell functions for working with AtomSpace

function New-AtomSpace {
    <#
    .SYNOPSIS
        Creates a new AtomSpace instance
    .DESCRIPTION
        Creates a new AtomSpace for storing and managing atoms
    .EXAMPLE
        $space = New-AtomSpace
    #>
    return [AtomSpace]::new()
}

function Add-Atom {
    <#
    .SYNOPSIS
        Adds an atom to an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to add to
    .PARAMETER Atom
        The atom to add
    .EXAMPLE
        $node = New-ConceptNode "Cat"
        Add-Atom -AtomSpace $space -Atom $node
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [Atom]$Atom
    )
    
    return $AtomSpace.AddAtom($Atom)
}

function Get-Atom {
    <#
    .SYNOPSIS
        Gets an atom from an AtomSpace by handle
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Handle
        The atom handle (GUID)
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [guid]$Handle
    )
    
    return $AtomSpace.GetAtom($Handle)
}

function Get-AtomsByType {
    <#
    .SYNOPSIS
        Gets all atoms of a specific type from an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Type
        The atom type to filter by
    .EXAMPLE
        Get-AtomsByType -AtomSpace $space -Type ConceptNode
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [AtomType]$Type
    )
    
    return $AtomSpace.GetAtomsByType($Type)
}

function Get-Node {
    <#
    .SYNOPSIS
        Gets a node by type and name from an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Type
        The node type
    .PARAMETER Name
        The node name
    .EXAMPLE
        Get-Node -AtomSpace $space -Type ConceptNode -Name "Cat"
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [AtomType]$Type,
        
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    return $AtomSpace.GetNode($Type, $Name)
}

function Get-IncomingSet {
    <#
    .SYNOPSIS
        Gets all links that contain the given atom in their outgoing set
    .PARAMETER AtomSpace
        The AtomSpace to search
    .PARAMETER Atom
        The atom to find incoming links for
    .EXAMPLE
        $incoming = Get-IncomingSet -AtomSpace $space -Atom $node
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [Atom]$Atom
    )
    
    return $AtomSpace.GetIncomingSet($Atom)
}

function Remove-Atom {
    <#
    .SYNOPSIS
        Removes an atom from an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to remove from
    .PARAMETER Atom
        The atom to remove
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [Parameter(Mandatory)]
        [Atom]$Atom
    )
    
    return $AtomSpace.RemoveAtom($Atom)
}

function Clear-AtomSpace {
    <#
    .SYNOPSIS
        Clears all atoms from an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to clear
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace
    )
    
    $AtomSpace.Clear()
}

function Get-AtomSpaceStatistics {
    <#
    .SYNOPSIS
        Gets statistics about an AtomSpace
    .PARAMETER AtomSpace
        The AtomSpace to analyze
    .EXAMPLE
        $stats = Get-AtomSpaceStatistics -AtomSpace $space
        Write-Host "Total atoms: $($stats.TotalAtoms)"
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace
    )
    
    return $AtomSpace.GetStatistics()
}

function Export-AtomSpace {
    <#
    .SYNOPSIS
        Exports an AtomSpace to a structured format
    .PARAMETER AtomSpace
        The AtomSpace to export
    .PARAMETER Path
        Optional file path to save JSON export
    .EXAMPLE
        $export = Export-AtomSpace -AtomSpace $space
        Export-AtomSpace -AtomSpace $space -Path "atomspace.json"
    #>
    param(
        [Parameter(Mandatory)]
        [AtomSpace]$AtomSpace,
        
        [string]$Path
    )
    
    $export = $AtomSpace.Export()
    
    if ($Path) {
        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding utf8
        Write-Host "AtomSpace exported to: $Path"
    }
    
    return $export
}

# Export module members
Export-ModuleMember -Function @(
    'New-AtomSpace',
    'Add-Atom',
    'Get-Atom',
    'Get-AtomsByType',
    'Get-Node',
    'Get-IncomingSet',
    'Remove-Atom',
    'Clear-AtomSpace',
    'Get-AtomSpaceStatistics',
    'Export-AtomSpace'
)
