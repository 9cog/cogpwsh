<#
.SYNOPSIS
    Exotic Atom Types - Extensible atom framework for domain-specific entities
    
.DESCRIPTION
    Implements an extensible framework for defining "exotic" atom types that
    represent real-world entities and services. Key features:
    
    - URI-addressable atoms for external resources
    - Hierarchical atomspaces (atoms containing atomspaces)
    - Domain-specific atom types (GitHub, Azure, Exchange, etc.)
    - Distributed/federated atomspace support
    - Extensible registry for custom atom types
    
.NOTES
    Part of OpenCog PowerShell implementation - Phase 4: Exotic Atoms
    
.EXAMPLE
    # Create a GitHub organization as an atomspace of repos
    $org = New-GitHubOrgAtom -Name "microsoft" -Description "Microsoft Organization"
    
    # Add repos as member atoms within the org's atomspace
    $repo = New-GitHubRepoAtom -Owner "microsoft" -Name "vscode"
    $org.AtomSpace.AddAtom($repo)
    
    # Create hierarchical enterprise structure
    $enterprise = New-GitHubEnterpriseAtom -Name "microsoft-enterprise"
    $enterprise.AtomSpace.AddAtom($org)
#>

using module ./Atoms.psm1
using module ./AtomSpace.psm1

# =============================================================================
# Exotic Atom Type Registry
# =============================================================================

<#
.SYNOPSIS
    Registry for exotic atom type definitions
.DESCRIPTION
    Maintains a registry of exotic atom types with their schemas, validators,
    and factory functions. Enables extensibility for custom domain types.
#>
class ExoticAtomRegistry {
    static [hashtable]$Types = @{}
    static [hashtable]$Schemas = @{}
    
    <#
    .SYNOPSIS
        Register a new exotic atom type
    #>
    static [void] Register([string]$typeName, [hashtable]$definition) {
        [ExoticAtomRegistry]::Types[$typeName] = $definition
        if ($definition.ContainsKey('Schema')) {
            [ExoticAtomRegistry]::Schemas[$typeName] = $definition.Schema
        }
    }
    
    <#
    .SYNOPSIS
        Check if an exotic type is registered
    #>
    static [bool] IsRegistered([string]$typeName) {
        return [ExoticAtomRegistry]::Types.ContainsKey($typeName)
    }
    
    <#
    .SYNOPSIS
        Get all registered exotic types
    #>
    static [string[]] GetRegisteredTypes() {
        return [ExoticAtomRegistry]::Types.Keys
    }
    
    <#
    .SYNOPSIS
        Get the schema for an exotic type
    #>
    static [hashtable] GetSchema([string]$typeName) {
        return [ExoticAtomRegistry]::Schemas[$typeName]
    }
}

# =============================================================================
# Base Exotic Atom Classes
# =============================================================================

<#
.SYNOPSIS
    ExoticNode - URI-addressable atom for external resources
.DESCRIPTION
    Base class for atoms that represent external entities with URI addressing.
    Supports hierarchical composition and domain-specific metadata.
#>
class ExoticNode : Node {
    [string]$Uri
    [string]$ExoticType
    [string]$Domain
    [hashtable]$Properties
    
    ExoticNode([string]$exoticType, [string]$name, [string]$uri) : base([AtomType]::ConceptNode, $name) {
        $this.ExoticType = $exoticType
        $this.Uri = $uri
        $this.Domain = $this.ExtractDomain($uri)
        $this.Properties = @{}
        $this.SetMetadata('NodeSubType', 'ExoticNode')
        $this.SetMetadata('ExoticType', $exoticType)
        $this.SetMetadata('Uri', $uri)
    }
    
    [string] ExtractDomain([string]$uri) {
        if ([string]::IsNullOrEmpty($uri)) { return 'unknown' }
        if ($uri -match '^([a-zA-Z]+)://') { return $Matches[1] }
        if ($uri -match '^([a-zA-Z0-9.-]+)\.([a-zA-Z]+)/') { return "$($Matches[1]).$($Matches[2])" }
        return 'unknown'
    }
    
    [string] GetUri() { return $this.Uri }
    [string] GetExoticType() { return $this.ExoticType }
    [string] GetDomain() { return $this.Domain }
    
    [void] SetProperty([string]$key, [object]$value) {
        $this.Properties[$key] = $value
    }
    
    [object] GetProperty([string]$key) {
        return $this.Properties[$key]
    }
    
    [string] ToString() {
        return "({0} `"{1}`" uri:`"{2}`" {3})" -f $this.ExoticType, $this.Name, $this.Uri, $this.TV
    }
}

<#
.SYNOPSIS
    AtomSpaceNode - An atom that contains its own AtomSpace
.DESCRIPTION
    Enables hierarchical composition where an atom can contain a full atomspace.
    Perfect for representing organizations, containers, or scopes that have
    nested entities.
    
    Examples:
    - GitHub org = AtomSpace of repo atoms
    - Enterprise = AtomSpace of org atoms
    - Azure tenant = AtomSpace of subscription atoms
#>
class AtomSpaceNode : ExoticNode {
    [AtomSpace]$AtomSpace
    
    AtomSpaceNode([string]$exoticType, [string]$name, [string]$uri) : base($exoticType, $name, $uri) {
        $this.AtomSpace = [AtomSpace]::new()
        $this.SetMetadata('NodeSubType', 'AtomSpaceNode')
        $this.SetMetadata('IsContainer', $true)
    }
    
    <#
    .SYNOPSIS
        Get the contained AtomSpace
    #>
    [AtomSpace] GetAtomSpace() {
        return $this.AtomSpace
    }
    
    <#
    .SYNOPSIS
        Add an atom to the contained AtomSpace
    #>
    [Atom] AddMemberAtom([Atom]$atom) {
        return $this.AtomSpace.AddAtom($atom)
    }
    
    <#
    .SYNOPSIS
        Get all member atoms
    #>
    [System.Collections.Generic.List[object]] GetMemberAtoms() {
        return $this.AtomSpace.GetAllAtoms()
    }
    
    <#
    .SYNOPSIS
        Get count of contained atoms
    #>
    [int] GetMemberCount() {
        return $this.AtomSpace.GetSize()
    }
    
    [string] ToString() {
        return "({0} `"{1}`" uri:`"{2}`" members:{3} {4})" -f `
            $this.ExoticType, $this.Name, $this.Uri, $this.GetMemberCount(), $this.TV
    }
}

<#
.SYNOPSIS
    DistributedAtomSpaceNode - Federated/distributed atomspace container
.DESCRIPTION
    Represents a distributed atomspace that aggregates multiple remote atomspaces.
    Supports federation across networks and synchronization metadata.
#>
class DistributedAtomSpaceNode : AtomSpaceNode {
    [System.Collections.Generic.List[string]]$RemoteEndpoints
    [hashtable]$SyncState
    [DateTime]$LastSyncTime
    
    DistributedAtomSpaceNode([string]$name, [string]$uri) : base('DistributedAtomSpace', $name, $uri) {
        $this.RemoteEndpoints = [System.Collections.Generic.List[string]]::new()
        $this.SyncState = @{}
        $this.LastSyncTime = [DateTime]::MinValue
        $this.SetMetadata('NodeSubType', 'DistributedAtomSpaceNode')
        $this.SetMetadata('IsDistributed', $true)
    }
    
    [void] AddRemoteEndpoint([string]$endpoint) {
        if (-not $this.RemoteEndpoints.Contains($endpoint)) {
            $this.RemoteEndpoints.Add($endpoint)
            $this.SyncState[$endpoint] = @{
                LastSync = [DateTime]::MinValue
                Status = 'NotSynced'
            }
        }
    }
    
    [string[]] GetRemoteEndpoints() {
        return $this.RemoteEndpoints.ToArray()
    }
    
    [void] UpdateSyncState([string]$endpoint, [string]$status) {
        if ($this.SyncState.ContainsKey($endpoint)) {
            $this.SyncState[$endpoint].LastSync = [DateTime]::UtcNow
            $this.SyncState[$endpoint].Status = $status
        }
        $this.LastSyncTime = [DateTime]::UtcNow
    }
    
    [hashtable] GetSyncState([string]$endpoint) {
        return $this.SyncState[$endpoint]
    }
}

# =============================================================================
# GitHub Exotic Atom Types
# =============================================================================

<#
.SYNOPSIS
    GitHub Repository Atom
#>
class GitHubRepoAtom : ExoticNode {
    [string]$Owner
    [string]$RepoName
    [string]$DefaultBranch
    [bool]$IsPrivate
    
    GitHubRepoAtom([string]$owner, [string]$repoName) : base(
        'GitHubRepo',
        "$owner/$repoName",
        "https://github.com/$owner/$repoName"
    ) {
        $this.Owner = $owner
        $this.RepoName = $repoName
        $this.DefaultBranch = 'main'
        $this.IsPrivate = $false
        $this.SetMetadata('NodeSubType', 'GitHubRepoAtom')
        $this.SetMetadata('Platform', 'GitHub')
    }
    
    [string] GetFullName() { return "$($this.Owner)/$($this.RepoName)" }
}

<#
.SYNOPSIS
    GitHub Organization Atom - AtomSpace of repositories
#>
class GitHubOrgAtom : AtomSpaceNode {
    [string]$OrgName
    [string]$DisplayName
    
    GitHubOrgAtom([string]$orgName) : base(
        'GitHubOrg',
        $orgName,
        "https://github.com/$orgName"
    ) {
        $this.OrgName = $orgName
        $this.DisplayName = $orgName
        $this.SetMetadata('NodeSubType', 'GitHubOrgAtom')
        $this.SetMetadata('Platform', 'GitHub')
    }
    
    [void] SetDisplayName([string]$displayName) {
        $this.DisplayName = $displayName
    }
    
    <#
    .SYNOPSIS
        Add a repository to this organization
    #>
    [GitHubRepoAtom] AddRepository([string]$repoName) {
        $repo = [GitHubRepoAtom]::new($this.OrgName, $repoName)
        $this.AtomSpace.AddAtom($repo)
        return $repo
    }
    
    <#
    .SYNOPSIS
        Get all repositories in this organization
    #>
    [System.Collections.Generic.List[object]] GetRepositories() {
        $repos = [System.Collections.Generic.List[object]]::new()
        foreach ($atom in $this.AtomSpace.GetAllAtoms()) {
            if ($atom -is [GitHubRepoAtom]) {
                $repos.Add($atom)
            }
        }
        return $repos
    }
}

<#
.SYNOPSIS
    GitHub Enterprise Atom - AtomSpace of organizations
#>
class GitHubEnterpriseAtom : AtomSpaceNode {
    [string]$EnterpriseName
    [string]$EnterpriseUrl
    
    GitHubEnterpriseAtom([string]$enterpriseName, [string]$enterpriseUrl) : base(
        'GitHubEnterprise',
        $enterpriseName,
        $enterpriseUrl
    ) {
        $this.EnterpriseName = $enterpriseName
        $this.EnterpriseUrl = $enterpriseUrl
        $this.SetMetadata('NodeSubType', 'GitHubEnterpriseAtom')
        $this.SetMetadata('Platform', 'GitHub')
    }
    
    <#
    .SYNOPSIS
        Add an organization to this enterprise
    #>
    [GitHubOrgAtom] AddOrganization([string]$orgName) {
        $org = [GitHubOrgAtom]::new($orgName)
        $this.AtomSpace.AddAtom($org)
        return $org
    }
    
    <#
    .SYNOPSIS
        Get all organizations in this enterprise
    #>
    [System.Collections.Generic.List[object]] GetOrganizations() {
        $orgs = [System.Collections.Generic.List[object]]::new()
        foreach ($atom in $this.AtomSpace.GetAllAtoms()) {
            if ($atom -is [GitHubOrgAtom]) {
                $orgs.Add($atom)
            }
        }
        return $orgs
    }
}

# =============================================================================
# Azure Exotic Atom Types
# =============================================================================

<#
.SYNOPSIS
    Azure Entra (AAD) Tenant Atom - AtomSpace of subscriptions and resources
#>
class AzureEntraTenantAtom : AtomSpaceNode {
    [guid]$TenantId
    [string]$TenantName
    [string]$PrimaryDomain
    
    AzureEntraTenantAtom([guid]$tenantId, [string]$tenantName) : base(
        'AzureEntraTenant',
        $tenantName,
        "https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview"
    ) {
        $this.TenantId = $tenantId
        $this.TenantName = $tenantName
        $this.PrimaryDomain = "$tenantName.onmicrosoft.com"
        $this.SetMetadata('NodeSubType', 'AzureEntraTenantAtom')
        $this.SetMetadata('Platform', 'Azure')
        $this.SetMetadata('TenantId', $tenantId.ToString())
    }
    
    [guid] GetTenantId() { return $this.TenantId }
    
    [void] SetPrimaryDomain([string]$domain) {
        $this.PrimaryDomain = $domain
    }
}

<#
.SYNOPSIS
    Azure Subscription Atom
#>
class AzureSubscriptionAtom : AtomSpaceNode {
    [guid]$SubscriptionId
    [string]$SubscriptionName
    [string]$State
    
    AzureSubscriptionAtom([guid]$subscriptionId, [string]$subscriptionName) : base(
        'AzureSubscription',
        $subscriptionName,
        "https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade"
    ) {
        $this.SubscriptionId = $subscriptionId
        $this.SubscriptionName = $subscriptionName
        $this.State = 'Enabled'
        $this.SetMetadata('NodeSubType', 'AzureSubscriptionAtom')
        $this.SetMetadata('Platform', 'Azure')
        $this.SetMetadata('SubscriptionId', $subscriptionId.ToString())
    }
    
    [guid] GetSubscriptionId() { return $this.SubscriptionId }
}

# =============================================================================
# Exchange/Microsoft 365 Exotic Atom Types
# =============================================================================

<#
.SYNOPSIS
    Exchange Mailbox Atom
#>
class ExchangeMailboxAtom : ExoticNode {
    [string]$EmailAddress
    [string]$DisplayName
    [string]$MailboxType
    
    ExchangeMailboxAtom([string]$emailAddress, [string]$displayName) : base(
        'ExchangeMailbox',
        $displayName,
        "mailto:$emailAddress"
    ) {
        $this.EmailAddress = $emailAddress
        $this.DisplayName = $displayName
        $this.MailboxType = 'UserMailbox'
        $this.SetMetadata('NodeSubType', 'ExchangeMailboxAtom')
        $this.SetMetadata('Platform', 'Exchange')
    }
    
    [string] GetEmailAddress() { return $this.EmailAddress }
    
    [void] SetMailboxType([string]$mailboxType) {
        $this.MailboxType = $mailboxType
    }
}

<#
.SYNOPSIS
    Exchange Calendar Atom
#>
class ExchangeCalendarAtom : ExoticNode {
    [string]$OwnerEmail
    [string]$CalendarName
    
    ExchangeCalendarAtom([string]$ownerEmail, [string]$calendarName) : base(
        'ExchangeCalendar',
        "$calendarName ($ownerEmail)",
        "outlook://calendar/$ownerEmail/$calendarName"
    ) {
        $this.OwnerEmail = $ownerEmail
        $this.CalendarName = $calendarName
        $this.SetMetadata('NodeSubType', 'ExchangeCalendarAtom')
        $this.SetMetadata('Platform', 'Exchange')
    }
}

# =============================================================================
# OpenCog Native Exotic Types
# =============================================================================

<#
.SYNOPSIS
    OpenCog AtomSpace Atom - An AtomSpace as an atom in another AtomSpace
.DESCRIPTION
    Enables meta-level reasoning where atomspaces themselves are treated as atoms.
    Useful for reflection, versioning, or distributed cognition.
#>
class OpenCogAtomSpaceAtom : AtomSpaceNode {
    [string]$Version
    [string]$Description
    
    OpenCogAtomSpaceAtom([string]$name, [string]$description) : base(
        'OpenCogAtomSpace',
        $name,
        "opencog://atomspace/$name"
    ) {
        $this.Description = $description
        $this.Version = '1.0.0'
        $this.SetMetadata('NodeSubType', 'OpenCogAtomSpaceAtom')
        $this.SetMetadata('Platform', 'OpenCog')
    }
    
    [void] SetVersion([string]$version) {
        $this.Version = $version
    }
    
    [string] GetVersion() { return $this.Version }
}

# =============================================================================
# Factory Functions
# =============================================================================

function New-ExoticNode {
    <#
    .SYNOPSIS
        Creates a new ExoticNode for URI-addressable entities
    .PARAMETER ExoticType
        The exotic type name (e.g., 'CustomResource', 'APIEndpoint')
    .PARAMETER Name
        Display name for the node
    .PARAMETER Uri
        URI to identify the external resource
    .EXAMPLE
        $node = New-ExoticNode -ExoticType "APIEndpoint" -Name "UserService" -Uri "https://api.example.com/users"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ExoticType,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Uri,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $node = [ExoticNode]::new($ExoticType, $Name, $Uri)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-AtomSpaceNode {
    <#
    .SYNOPSIS
        Creates an AtomSpaceNode - an atom containing its own atomspace
    .PARAMETER ExoticType
        The exotic type name
    .PARAMETER Name
        Display name for the container
    .PARAMETER Uri
        URI identifier
    .EXAMPLE
        $container = New-AtomSpaceNode -ExoticType "ProjectScope" -Name "MyProject" -Uri "project://myproject"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ExoticType,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Uri = "",
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    if ([string]::IsNullOrEmpty($Uri)) {
        $Uri = "atomspace://$($ExoticType.ToLower())/$Name"
    }
    
    $node = [AtomSpaceNode]::new($ExoticType, $Name, $Uri)
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

function New-DistributedAtomSpace {
    <#
    .SYNOPSIS
        Creates a DistributedAtomSpaceNode for federated atomspaces
    .PARAMETER Name
        Name for the distributed atomspace
    .PARAMETER Uri
        Primary URI identifier
    .PARAMETER RemoteEndpoints
        Array of remote endpoint URIs to federate
    .EXAMPLE
        $distributed = New-DistributedAtomSpace -Name "GlobalKB" -Uri "distributed://globalkb" -RemoteEndpoints @("http://node1.example.com", "http://node2.example.com")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Uri = "",
        
        [string[]]$RemoteEndpoints = @(),
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    if ([string]::IsNullOrEmpty($Uri)) {
        $Uri = "distributed://atomspace/$Name"
    }
    
    $node = [DistributedAtomSpaceNode]::new($Name, $Uri)
    foreach ($endpoint in $RemoteEndpoints) {
        $node.AddRemoteEndpoint($endpoint)
    }
    $node.SetTruthValue($Strength, $Confidence)
    return $node
}

# GitHub Factory Functions

function New-GitHubRepoAtom {
    <#
    .SYNOPSIS
        Creates a GitHub repository atom
    .PARAMETER Owner
        Repository owner (user or organization)
    .PARAMETER Name
        Repository name
    .PARAMETER DefaultBranch
        Default branch name (default: 'main')
    .PARAMETER IsPrivate
        Whether the repository is private
    .EXAMPLE
        $repo = New-GitHubRepoAtom -Owner "microsoft" -Name "vscode"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$DefaultBranch = 'main',
        
        [bool]$IsPrivate = $false,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $repo = [GitHubRepoAtom]::new($Owner, $Name)
    $repo.DefaultBranch = $DefaultBranch
    $repo.IsPrivate = $IsPrivate
    $repo.SetTruthValue($Strength, $Confidence)
    return $repo
}

function New-GitHubOrgAtom {
    <#
    .SYNOPSIS
        Creates a GitHub organization atom (AtomSpace of repos)
    .PARAMETER Name
        Organization name
    .PARAMETER DisplayName
        Optional display name
    .EXAMPLE
        $org = New-GitHubOrgAtom -Name "microsoft" -DisplayName "Microsoft Corporation"
        $repo = $org.AddRepository("vscode")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$DisplayName = "",
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $org = [GitHubOrgAtom]::new($Name)
    if (-not [string]::IsNullOrEmpty($DisplayName)) {
        $org.SetDisplayName($DisplayName)
    }
    $org.SetTruthValue($Strength, $Confidence)
    return $org
}

function New-GitHubEnterpriseAtom {
    <#
    .SYNOPSIS
        Creates a GitHub Enterprise atom (AtomSpace of orgs)
    .PARAMETER Name
        Enterprise name
    .PARAMETER EnterpriseUrl
        Enterprise URL (default: github.com)
    .EXAMPLE
        $enterprise = New-GitHubEnterpriseAtom -Name "acme-corp" -EnterpriseUrl "https://github.acme.com"
        $org = $enterprise.AddOrganization("engineering")
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$EnterpriseUrl = "https://github.com",
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $enterprise = [GitHubEnterpriseAtom]::new($Name, $EnterpriseUrl)
    $enterprise.SetTruthValue($Strength, $Confidence)
    return $enterprise
}

# Azure Factory Functions

function New-AzureEntraTenantAtom {
    <#
    .SYNOPSIS
        Creates an Azure Entra (AAD) tenant atom
    .PARAMETER TenantId
        The tenant GUID
    .PARAMETER TenantName
        Display name for the tenant
    .EXAMPLE
        $tenant = New-AzureEntraTenantAtom -TenantId ([guid]::NewGuid()) -TenantName "contoso"
    #>
    param(
        [Parameter(Mandatory)]
        [guid]$TenantId,
        
        [Parameter(Mandatory)]
        [string]$TenantName,
        
        [string]$PrimaryDomain = "",
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $tenant = [AzureEntraTenantAtom]::new($TenantId, $TenantName)
    if (-not [string]::IsNullOrEmpty($PrimaryDomain)) {
        $tenant.SetPrimaryDomain($PrimaryDomain)
    }
    $tenant.SetTruthValue($Strength, $Confidence)
    return $tenant
}

function New-AzureSubscriptionAtom {
    <#
    .SYNOPSIS
        Creates an Azure Subscription atom
    .PARAMETER SubscriptionId
        The subscription GUID
    .PARAMETER SubscriptionName
        Display name for the subscription
    .EXAMPLE
        $sub = New-AzureSubscriptionAtom -SubscriptionId ([guid]::NewGuid()) -SubscriptionName "Production"
    #>
    param(
        [Parameter(Mandatory)]
        [guid]$SubscriptionId,
        
        [Parameter(Mandatory)]
        [string]$SubscriptionName,
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $subscription = [AzureSubscriptionAtom]::new($SubscriptionId, $SubscriptionName)
    $subscription.SetTruthValue($Strength, $Confidence)
    return $subscription
}

# Exchange Factory Functions

function New-ExchangeMailboxAtom {
    <#
    .SYNOPSIS
        Creates an Exchange mailbox atom
    .PARAMETER EmailAddress
        Email address for the mailbox
    .PARAMETER DisplayName
        Display name for the mailbox owner
    .PARAMETER MailboxType
        Type of mailbox (UserMailbox, SharedMailbox, RoomMailbox, etc.)
    .EXAMPLE
        $mailbox = New-ExchangeMailboxAtom -EmailAddress "user@contoso.com" -DisplayName "John Doe"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$EmailAddress,
        
        [Parameter(Mandatory)]
        [string]$DisplayName,
        
        [ValidateSet('UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox', 'SchedulingMailbox')]
        [string]$MailboxType = 'UserMailbox',
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $mailbox = [ExchangeMailboxAtom]::new($EmailAddress, $DisplayName)
    $mailbox.SetMailboxType($MailboxType)
    $mailbox.SetTruthValue($Strength, $Confidence)
    return $mailbox
}

function New-ExchangeCalendarAtom {
    <#
    .SYNOPSIS
        Creates an Exchange calendar atom
    .PARAMETER OwnerEmail
        Email address of the calendar owner
    .PARAMETER CalendarName
        Name of the calendar (default: 'Calendar')
    .EXAMPLE
        $calendar = New-ExchangeCalendarAtom -OwnerEmail "user@contoso.com" -CalendarName "Work Calendar"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$OwnerEmail,
        
        [string]$CalendarName = 'Calendar',
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $calendar = [ExchangeCalendarAtom]::new($OwnerEmail, $CalendarName)
    $calendar.SetTruthValue($Strength, $Confidence)
    return $calendar
}

# OpenCog Factory Functions

function New-OpenCogAtomSpaceAtom {
    <#
    .SYNOPSIS
        Creates an OpenCog AtomSpace as an atom (meta-level)
    .PARAMETER Name
        Name for the atomspace atom
    .PARAMETER Description
        Description of the atomspace
    .PARAMETER Version
        Version string
    .EXAMPLE
        $metaAS = New-OpenCogAtomSpaceAtom -Name "KnowledgeBase-v1" -Description "Main knowledge base"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Description = "",
        
        [string]$Version = "1.0.0",
        
        [double]$Strength = 1.0,
        [double]$Confidence = 1.0
    )
    
    $atomspace = [OpenCogAtomSpaceAtom]::new($Name, $Description)
    $atomspace.SetVersion($Version)
    $atomspace.SetTruthValue($Strength, $Confidence)
    return $atomspace
}

# =============================================================================
# Helper Functions
# =============================================================================

function Test-ExoticAtom {
    <#
    .SYNOPSIS
        Tests if an atom is an exotic atom type
    .PARAMETER Atom
        The atom to test
    .PARAMETER ExoticType
        Optional specific exotic type to check for
    .EXAMPLE
        if (Test-ExoticAtom -Atom $myAtom -ExoticType "GitHubRepo") { ... }
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom,
        
        [string]$ExoticType = ""
    )
    
    if ($Atom -is [ExoticNode]) {
        if ([string]::IsNullOrEmpty($ExoticType)) {
            return $true
        }
        return $Atom.ExoticType -eq $ExoticType
    }
    return $false
}

function Test-AtomSpaceAtom {
    <#
    .SYNOPSIS
        Tests if an atom contains its own AtomSpace
    .PARAMETER Atom
        The atom to test
    .EXAMPLE
        if (Test-AtomSpaceAtom -Atom $org) { $members = $org.GetMemberAtoms() }
    #>
    param(
        [Parameter(Mandatory)]
        [Atom]$Atom
    )
    
    return $Atom -is [AtomSpaceNode]
}

function Get-ExoticAtomUri {
    <#
    .SYNOPSIS
        Gets the URI from an exotic atom
    .PARAMETER Atom
        The exotic atom
    .EXAMPLE
        $uri = Get-ExoticAtomUri -Atom $repo
    #>
    param(
        [Parameter(Mandatory)]
        [ExoticNode]$Atom
    )
    
    return $Atom.GetUri()
}

function Get-ExoticAtomProperties {
    <#
    .SYNOPSIS
        Gets all properties from an exotic atom
    .PARAMETER Atom
        The exotic atom
    .EXAMPLE
        $props = Get-ExoticAtomProperties -Atom $repo
    #>
    param(
        [Parameter(Mandatory)]
        [ExoticNode]$Atom
    )
    
    return $Atom.Properties
}

function Register-ExoticAtomType {
    <#
    .SYNOPSIS
        Registers a custom exotic atom type
    .PARAMETER TypeName
        Name of the custom type
    .PARAMETER Schema
        Schema definition for the type
    .PARAMETER Description
        Description of the type
    .EXAMPLE
        Register-ExoticAtomType -TypeName "JiraTicket" -Schema @{ ProjectKey = 'string'; IssueNumber = 'int' }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TypeName,
        
        [hashtable]$Schema = @{},
        
        [string]$Description = ""
    )
    
    $definition = @{
        Name = $TypeName
        Schema = $Schema
        Description = $Description
        RegisteredAt = [DateTime]::UtcNow
    }
    
    [ExoticAtomRegistry]::Register($TypeName, $definition)
    Write-Verbose "Registered exotic atom type: $TypeName"
}

function Get-RegisteredExoticTypes {
    <#
    .SYNOPSIS
        Gets all registered exotic atom types
    .EXAMPLE
        $types = Get-RegisteredExoticTypes
    #>
    return [ExoticAtomRegistry]::GetRegisteredTypes()
}

# =============================================================================
# Initialize Built-in Type Registrations
# =============================================================================

# Register built-in exotic types
[ExoticAtomRegistry]::Register('GitHubRepo', @{
    Name = 'GitHubRepo'
    Description = 'GitHub repository'
    Schema = @{ Owner = 'string'; RepoName = 'string'; DefaultBranch = 'string'; IsPrivate = 'bool' }
})

[ExoticAtomRegistry]::Register('GitHubOrg', @{
    Name = 'GitHubOrg'
    Description = 'GitHub organization (AtomSpace of repos)'
    Schema = @{ OrgName = 'string'; DisplayName = 'string' }
    IsContainer = $true
})

[ExoticAtomRegistry]::Register('GitHubEnterprise', @{
    Name = 'GitHubEnterprise'
    Description = 'GitHub Enterprise (AtomSpace of orgs)'
    Schema = @{ EnterpriseName = 'string'; EnterpriseUrl = 'string' }
    IsContainer = $true
})

[ExoticAtomRegistry]::Register('AzureEntraTenant', @{
    Name = 'AzureEntraTenant'
    Description = 'Azure Entra (AAD) tenant'
    Schema = @{ TenantId = 'guid'; TenantName = 'string'; PrimaryDomain = 'string' }
    IsContainer = $true
})

[ExoticAtomRegistry]::Register('AzureSubscription', @{
    Name = 'AzureSubscription'
    Description = 'Azure subscription'
    Schema = @{ SubscriptionId = 'guid'; SubscriptionName = 'string'; State = 'string' }
    IsContainer = $true
})

[ExoticAtomRegistry]::Register('ExchangeMailbox', @{
    Name = 'ExchangeMailbox'
    Description = 'Exchange/M365 mailbox'
    Schema = @{ EmailAddress = 'string'; DisplayName = 'string'; MailboxType = 'string' }
})

[ExoticAtomRegistry]::Register('ExchangeCalendar', @{
    Name = 'ExchangeCalendar'
    Description = 'Exchange calendar'
    Schema = @{ OwnerEmail = 'string'; CalendarName = 'string' }
})

[ExoticAtomRegistry]::Register('OpenCogAtomSpace', @{
    Name = 'OpenCogAtomSpace'
    Description = 'OpenCog AtomSpace as an atom (meta-level)'
    Schema = @{ Name = 'string'; Description = 'string'; Version = 'string' }
    IsContainer = $true
})

[ExoticAtomRegistry]::Register('DistributedAtomSpace', @{
    Name = 'DistributedAtomSpace'
    Description = 'Distributed/federated AtomSpace'
    Schema = @{ Name = 'string'; RemoteEndpoints = 'string[]' }
    IsContainer = $true
    IsDistributed = $true
})

# =============================================================================
# Export Module Members
# =============================================================================

Export-ModuleMember -Function @(
    # Base exotic atom functions
    'New-ExoticNode',
    'New-AtomSpaceNode',
    'New-DistributedAtomSpace',
    
    # GitHub functions
    'New-GitHubRepoAtom',
    'New-GitHubOrgAtom',
    'New-GitHubEnterpriseAtom',
    
    # Azure functions
    'New-AzureEntraTenantAtom',
    'New-AzureSubscriptionAtom',
    
    # Exchange functions
    'New-ExchangeMailboxAtom',
    'New-ExchangeCalendarAtom',
    
    # OpenCog meta-level functions
    'New-OpenCogAtomSpaceAtom',
    
    # Helper functions
    'Test-ExoticAtom',
    'Test-AtomSpaceAtom',
    'Get-ExoticAtomUri',
    'Get-ExoticAtomProperties',
    'Register-ExoticAtomType',
    'Get-RegisteredExoticTypes'
)
