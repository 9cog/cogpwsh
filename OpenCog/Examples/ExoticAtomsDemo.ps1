<#
.SYNOPSIS
    Exotic Atoms Demo - Demonstrating domain-specific atom types
    
.DESCRIPTION
    This demo shows how to use exotic atom types for representing
    real-world entities like GitHub repos/orgs/enterprises, Azure
    tenants, Exchange mailboxes, and hierarchical AtomSpaces.
    
.NOTES
    Part of OpenCog PowerShell implementation - Phase 4
    
.EXAMPLE
    .\ExoticAtomsDemo.ps1
#>

# Import the OpenCog module
$modulePath = Join-Path $PSScriptRoot ".." "OpenCog.psd1"
Import-Module $modulePath -Force

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "  OpenCog PowerShell - Exotic Atoms Demo" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Demo 1: GitHub Hierarchical Structure
# =============================================================================

Write-Host "Demo 1: GitHub Hierarchical Structure" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create a GitHub Enterprise
$enterprise = New-GitHubEnterpriseAtom -Name "acme-corp" -EnterpriseUrl "https://github.acme.com"
Write-Host "Created Enterprise: $($enterprise.Name)" -ForegroundColor Green
Write-Host "  URI: $($enterprise.Uri)"
Write-Host "  Type: $($enterprise.ExoticType)"

# Add organizations to the enterprise
$engOrg = $enterprise.AddOrganization("engineering")
$dataOrg = $enterprise.AddOrganization("data-science")
$opsOrg = $enterprise.AddOrganization("operations")

Write-Host ""
Write-Host "Added Organizations:" -ForegroundColor Green
foreach ($org in $enterprise.GetOrganizations()) {
    Write-Host "  - $($org.OrgName)"
}

# Add repositories to engineering org
$repo1 = $engOrg.AddRepository("backend-api")
$repo2 = $engOrg.AddRepository("frontend-app")
$repo3 = $engOrg.AddRepository("shared-libs")

Write-Host ""
Write-Host "Engineering Repositories:" -ForegroundColor Green
foreach ($repo in $engOrg.GetRepositories()) {
    Write-Host "  - $($repo.GetFullName())"
}

# Show the hierarchy
Write-Host ""
Write-Host "Complete Hierarchy:" -ForegroundColor Cyan
Write-Host "  Enterprise: $($enterprise.Name) ($(($enterprise.GetOrganizations()).Count) orgs)"
foreach ($org in $enterprise.GetOrganizations()) {
    $repoCount = ($org.GetRepositories()).Count
    Write-Host "    +- Org: $($org.OrgName) ($repoCount repos)"
    foreach ($repo in $org.GetRepositories()) {
        Write-Host "       +- Repo: $($repo.RepoName)"
    }
}

Write-Host ""

# =============================================================================
# Demo 2: Azure Tenant Structure
# =============================================================================

Write-Host "Demo 2: Azure Tenant Structure" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create an Azure Entra tenant
$tenantId = [guid]::NewGuid()
$tenant = New-AzureEntraTenantAtom -TenantId $tenantId -TenantName "contoso" -PrimaryDomain "contoso.com"
Write-Host "Created Azure Tenant: $($tenant.TenantName)" -ForegroundColor Green
Write-Host "  Tenant ID: $($tenant.TenantId)"
Write-Host "  Primary Domain: $($tenant.PrimaryDomain)"

# Add subscriptions
$prodSubId = [guid]::NewGuid()
$devSubId = [guid]::NewGuid()
$prodSub = New-AzureSubscriptionAtom -SubscriptionId $prodSubId -SubscriptionName "Production"
$devSub = New-AzureSubscriptionAtom -SubscriptionId $devSubId -SubscriptionName "Development"

# Add subscriptions to tenant's atomspace
$tenant.AddMemberAtom($prodSub)
$tenant.AddMemberAtom($devSub)

Write-Host ""
Write-Host "Tenant Subscriptions:" -ForegroundColor Green
foreach ($atom in $tenant.GetMemberAtoms()) {
    if ($atom.ExoticType -eq 'AzureSubscription') {
        Write-Host "  - $($atom.SubscriptionName) ($($atom.SubscriptionId))"
    }
}

Write-Host ""

# =============================================================================
# Demo 3: Exchange Mailboxes
# =============================================================================

Write-Host "Demo 3: Exchange Mailboxes" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create mailboxes
$mailbox1 = New-ExchangeMailboxAtom -EmailAddress "alice@contoso.com" -DisplayName "Alice Johnson"
$mailbox2 = New-ExchangeMailboxAtom -EmailAddress "bob@contoso.com" -DisplayName "Bob Smith"
$sharedMailbox = New-ExchangeMailboxAtom -EmailAddress "team@contoso.com" -DisplayName "Team Mailbox" -MailboxType "SharedMailbox"

Write-Host "Created Mailboxes:" -ForegroundColor Green
Write-Host "  - $($mailbox1.DisplayName) <$($mailbox1.EmailAddress)> [$($mailbox1.MailboxType)]"
Write-Host "  - $($mailbox2.DisplayName) <$($mailbox2.EmailAddress)> [$($mailbox2.MailboxType)]"
Write-Host "  - $($sharedMailbox.DisplayName) <$($sharedMailbox.EmailAddress)> [$($sharedMailbox.MailboxType)]"

# Create calendars
$calendar1 = New-ExchangeCalendarAtom -OwnerEmail "alice@contoso.com" -CalendarName "Work"
$calendar2 = New-ExchangeCalendarAtom -OwnerEmail "alice@contoso.com" -CalendarName "Personal"

Write-Host ""
Write-Host "Created Calendars:" -ForegroundColor Green
Write-Host "  - $($calendar1.CalendarName) (Owner: $($calendar1.OwnerEmail))"
Write-Host "  - $($calendar2.CalendarName) (Owner: $($calendar2.OwnerEmail))"

Write-Host ""

# =============================================================================
# Demo 4: Distributed AtomSpace
# =============================================================================

Write-Host "Demo 4: Distributed AtomSpace" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create a distributed atomspace
$distributed = New-DistributedAtomSpace -Name "GlobalKnowledgeBase" `
    -Uri "distributed://globalkb" `
    -RemoteEndpoints @(
        "https://node1.cognitive.example.com",
        "https://node2.cognitive.example.com",
        "https://node3.cognitive.example.com"
    )

Write-Host "Created Distributed AtomSpace: $($distributed.Name)" -ForegroundColor Green
Write-Host "  URI: $($distributed.Uri)"
Write-Host "  Remote Endpoints:" 
foreach ($endpoint in $distributed.GetRemoteEndpoints()) {
    Write-Host "    - $endpoint"
}

# Simulate sync state updates
$distributed.UpdateSyncState("https://node1.cognitive.example.com", "Synced")
$distributed.UpdateSyncState("https://node2.cognitive.example.com", "Syncing")

Write-Host ""
Write-Host "Sync States:" -ForegroundColor Green
foreach ($endpoint in $distributed.GetRemoteEndpoints()) {
    $state = $distributed.GetSyncState($endpoint)
    Write-Host "  - $endpoint : $($state.Status)"
}

Write-Host ""

# =============================================================================
# Demo 5: OpenCog Meta-Level AtomSpaces
# =============================================================================

Write-Host "Demo 5: OpenCog Meta-Level AtomSpaces" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create atomspace atoms (meta-level)
$mainKB = New-OpenCogAtomSpaceAtom -Name "MainKnowledgeBase" -Description "Primary knowledge repository" -Version "2.0.0"
$archiveKB = New-OpenCogAtomSpaceAtom -Name "ArchiveKnowledgeBase" -Description "Historical data archive" -Version "1.5.0"

Write-Host "Created Meta-Level AtomSpaces:" -ForegroundColor Green
Write-Host "  - $($mainKB.Name) v$($mainKB.Version): $($mainKB.Description)"
Write-Host "  - $($archiveKB.Name) v$($archiveKB.Version): $($archiveKB.Description)"

# Add some concepts to the main KB
$concept1 = New-ConceptNode "ArtificialIntelligence"
$concept2 = New-ConceptNode "CognitiveArchitecture"
$mainKB.AddMemberAtom($concept1)
$mainKB.AddMemberAtom($concept2)

Write-Host ""
Write-Host "Main KB Contents:" -ForegroundColor Green
foreach ($atom in $mainKB.GetMemberAtoms()) {
    Write-Host "  - $($atom.Name) [$($atom.Type)]"
}

Write-Host ""

# =============================================================================
# Demo 6: Custom Exotic Types
# =============================================================================

Write-Host "Demo 6: Custom Exotic Type Registration" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Show built-in registered types
Write-Host "Built-in Registered Types:" -ForegroundColor Green
foreach ($type in Get-RegisteredExoticTypes) {
    Write-Host "  - $type"
}

# Register a custom type
Register-ExoticAtomType -TypeName "JiraTicket" -Schema @{
    ProjectKey = 'string'
    IssueNumber = 'int'
    Summary = 'string'
    Status = 'string'
} -Description "Jira issue tracker ticket"

Write-Host ""
Write-Host "After registering custom type:" -ForegroundColor Green
foreach ($type in Get-RegisteredExoticTypes) {
    Write-Host "  - $type"
}

# Create a custom exotic node
$jiraTicket = New-ExoticNode -ExoticType "JiraTicket" -Name "PROJ-123" -Uri "https://jira.example.com/browse/PROJ-123"
$jiraTicket.SetProperty("ProjectKey", "PROJ")
$jiraTicket.SetProperty("IssueNumber", 123)
$jiraTicket.SetProperty("Summary", "Implement exotic atom types")
$jiraTicket.SetProperty("Status", "In Progress")

Write-Host ""
Write-Host "Custom Jira Ticket Atom:" -ForegroundColor Green
Write-Host "  Name: $($jiraTicket.Name)"
Write-Host "  URI: $(Get-ExoticAtomUri -Atom $jiraTicket)"
Write-Host "  Properties:"
$props = Get-ExoticAtomProperties -Atom $jiraTicket
foreach ($key in $props.Keys) {
    Write-Host "    $key : $($props[$key])"
}

Write-Host ""

# =============================================================================
# Demo 7: Testing Functions
# =============================================================================

Write-Host "Demo 7: Testing Functions" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

Write-Host "Testing atom types:" -ForegroundColor Green
Write-Host "  Is \$enterprise an ExoticAtom? $(Test-ExoticAtom -Atom $enterprise)"
Write-Host "  Is \$enterprise a GitHubEnterprise? $(Test-ExoticAtom -Atom $enterprise -ExoticType 'GitHubEnterprise')"
Write-Host "  Is \$enterprise a GitHubRepo? $(Test-ExoticAtom -Atom $enterprise -ExoticType 'GitHubRepo')"
Write-Host ""
Write-Host "  Does \$enterprise contain an AtomSpace? $(Test-AtomSpaceAtom -Atom $enterprise)"
Write-Host "  Does \$mailbox1 contain an AtomSpace? $(Test-AtomSpaceAtom -Atom $mailbox1)"

Write-Host ""

# =============================================================================
# Demo 8: Integrating with Standard AtomSpace
# =============================================================================

Write-Host "Demo 8: Integrating with Standard AtomSpace" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Yellow
Write-Host ""

# Create a standard AtomSpace
$kb = New-AtomSpace

# Add exotic atoms to standard atomspace
$kb.AddAtom($enterprise)
$kb.AddAtom($tenant)
$kb.AddAtom($mailbox1)
$kb.AddAtom($distributed)

Write-Host "Added exotic atoms to standard AtomSpace:" -ForegroundColor Green
$stats = Get-AtomSpaceStatistics -AtomSpace $kb
Write-Host "  Total atoms: $($stats.TotalAtoms)"

# Create relationships between exotic atoms
$ownsRepo = New-EvaluationLink -Predicate (New-PredicateNode "owns") -Arguments @($engOrg, $repo1)
$kb.AddAtom($ownsRepo)

$belongsTo = New-MemberLink -Element $prodSub -Set $tenant
$kb.AddAtom($belongsTo)

Write-Host "  Created relationships between exotic atoms"
Write-Host ""

# =============================================================================
# Summary
# =============================================================================

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "  Demo Complete!" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "Exotic Atoms enable:" -ForegroundColor White
Write-Host "  - URI-addressable atoms for external resources"
Write-Host "  - Hierarchical AtomSpaces (org → repos, enterprise → orgs)"
Write-Host "  - Domain-specific types (GitHub, Azure, Exchange)"
Write-Host "  - Distributed/federated AtomSpace support"
Write-Host "  - Meta-level reasoning (AtomSpaces as atoms)"
Write-Host "  - Extensible type registration for custom domains"
Write-Host ""
