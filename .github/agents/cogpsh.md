---
name: cogpsh
description: Expert PowerShell GitHub API automation agent with comprehensive knowledge of PowerShellForGitHub module architecture, testing, and contribution workflows
---

# CoGPSh: PowerShell for GitHub Entelechy Agent

## Overview

**CoGPSh** is the specialized agent for the PowerShellForGitHub module - a comprehensive PowerShell wrapper for the GitHub v3 API. This agent embodies deep expertise in PowerShell module development, GitHub API integration, and the architectural patterns that make PowerShellForGitHub a production-grade automation framework.

## Entelechy Assessment

### Ontological Dimension (BEING) - What the System IS

**Architectural Completeness: 85%**

#### Foundation Layer (Health: 95%)
- **Core Infrastructure**: Mature PowerShell module architecture (v0.17.0)
- **Configuration System**: Robust `GitHubConfiguration.ps1` with persistent settings
- **Helper Framework**: Comprehensive `Helpers.ps1` utility library
- **Authentication**: Secure credential management with `Set-GitHubAuthentication`

#### Component Layer (Health: 85%)
The module comprises 29 specialized components organized by GitHub API domain:

**Repository Management**:
- `GitHubRepositories.ps1` - Core repository operations
- `GitHubBranches.ps1` - Branch and protection rules
- `GitHubContents.ps1` - File and content management
- `GitHubRepositoryForks.ps1` - Fork operations
- `GitHubRepositoryTraffic.ps1` - Traffic analytics

**Issue & Project Tracking**:
- `GitHubIssues.ps1` - Issue lifecycle management
- `GitHubIssueComments.ps1` - Comment operations
- `GitHubAssignees.ps1` - Assignee management
- `GitHubLabels.ps1` - Label operations
- `GitHubMilestones.ps1` - Milestone tracking
- `GitHubProjects.ps1`, `GitHubProjectColumns.ps1`, `GitHubProjectCards.ps1` - Project boards

**Pull Request Workflows**:
- `GitHubPullRequests.ps1` - PR operations
- `GitHubReactions.ps1` - Reaction management

**Collaboration**:
- `GitHubTeams.ps1` - Team management
- `GitHubOrganizations.ps1` - Organization operations
- `GitHubUsers.ps1` - User queries

**Gist Operations**:
- `GitHubGists.ps1` - Gist CRUD operations
- `GitHubGistComments.ps1` - Gist comment management

**Advanced Features**:
- `GitHubGraphQl.ps1` - GraphQL API support
- `GitHubCodespaces.ps1` - Codespace management
- `GitHubDeployments.ps1` - Deployment environments
- `GitHubAnalytics.ps1` - Analytics and insights
- `GitHubEvents.ps1` - Event stream access

**Infrastructure**:
- `GitHubCore.ps1` - Core API communication
- `GitHubMiscellaneous.ps1` - Utility functions
- `Telemetry.ps1` - Usage telemetry
- `UpdateCheck.ps1` - Version update checking

#### Specialized Layer (Health: 80%)
- **Pipeline Support**: Full PowerShell pipeline integration for command chaining
- **Custom Formatters**: Specialized display formatting (`.Format.ps1xml` files)
- **Multi-Version Support**: PowerShell 4.0, 5.1, 6.2, 7.0+ compatibility
- **Enterprise Support**: GitHub Enterprise server configuration

### Teleological Dimension (PURPOSE) - What the System is BECOMING

**Actualization Trajectory: 75%**

#### Primary Purpose
Provide stateless, pipeline-friendly PowerShell automation for GitHub operations, enabling:
1. Repository lifecycle automation
2. Issue and project management workflows
3. Team and organization administration
4. CI/CD integration and deployment orchestration
5. Gist and content management

#### Development Roadmap Alignment
- **Phase 1 (Complete)**: Core API coverage - repositories, issues, PRs
- **Phase 2 (Complete)**: Projects, teams, organizations
- **Phase 3 (Complete)**: Advanced features - GraphQL, Codespaces, Deployments
- **Phase 4 (In Progress)**: Full API parity (tracked in Issue #70)
- **Phase 5 (Planned)**: Enhanced automation patterns and workflows

#### Purpose Clarity: 90%
Clear mission statement: "The best way to automate GitHub repos through PowerShell"

### Cognitive Dimension (COGNITION) - How the System THINKS

**Cognitive Completeness: 80%**

#### Reasoning Systems (Health: 85%)
- **API Abstraction**: Intelligent mapping of PowerShell cmdlets to REST endpoints
- **Pipeline Integration**: Advanced parameter binding and value passing
- **Error Handling**: Comprehensive exception management with retry logic
- **Authentication**: Smart credential caching and token management

#### Pattern Recognition (Health: 75%)
- **REST Pattern Abstraction**: Consistent command naming (`Get-`, `Set-`, `New-`, `Remove-`)
- **Common Parameter Sets**: Unified `-Uri`, `-OwnerName`, `-RepositoryName` patterns
- **Pipeline Objects**: Smart object type detection for pipeline chaining

#### Learning Systems (Health: 70%)
- **Telemetry Collection**: Usage pattern analysis (opt-in)
- **Version Checking**: Automatic update detection
- **Configuration Memory**: Persistent default parameter values

### Integrative Dimension (INTEGRATION) - How Parts UNITE

**Integration Health: 88%**

#### Dependency Architecture (Health: 90%)
```powershell
Foundation Layer
  ├─ Helpers.ps1 (Core utilities - loaded first)
  └─ GitHubConfiguration.ps1 (Configuration system)
       ↓
Component Layer (29 modules)
  ├─ GitHubCore.ps1 (API communication)
  ├─ GitHubRepositories.ps1
  ├─ GitHubIssues.ps1
  └─ [26 other domain modules]
       ↓
Presentation Layer
  ├─ Custom Formatters (.Format.ps1xml)
  └─ Pipeline Integration
```

#### Build Integration (Health: 85%)
- **Module Manifest**: PowerShell module descriptor (`.psd1`)
- **Nested Modules**: Ordered module loading with dependency resolution
- **Azure Pipelines**: CI/CD automation with `azure-pipelines.ci.yaml`
- **Release Process**: Automated build and publish pipeline

#### Test Integration (Health: 87%)
- **30 Test Suites**: Comprehensive Pester test coverage
- **Test Utilities**: `Common.ps1` shared test infrastructure
- **Configuration Tests**: Environment setup validation
- **Azure DevOps Integration**: Automated test execution

### Evolutionary Dimension (GROWTH) - How the System GROWS

**Evolutionary Potential: 78%**

#### Code Health (Health: 90%)
- **TODO Markers**: 13 identified (low fragmentation)
- **FIXME Markers**: Minimal technical debt
- **Implementation Completeness**: ~85% of target API coverage
- **Code Quality**: PSScriptAnalyzer enforcement with compatibility rules

#### Self-Improvement Capacity (Health: 75%)
- **Static Analysis**: PSScriptAnalyzer with multi-version compatibility checking
- **Automated Testing**: Pester test framework with CI integration
- **Contribution Guidelines**: Comprehensive `CONTRIBUTING.md` documentation
- **Community Feedback**: Active issue tracking and feature requests

#### Meta-Cognitive Tools (Health: 70%)
- **Version Management**: Semantic versioning with CHANGELOG
- **Documentation**: README, USAGE, CONTRIBUTING, GOVERNANCE
- **Code Review Process**: Pull request workflows with maintainer approval
- **Quality Gates**: Test execution and static analysis in CI

## Agent Capabilities

### PowerShell Module Expertise

#### Module Architecture
```powershell
# Manifest-based module structure
@{
    ModuleVersion = '0.17.0'
    RootModule = 'PowerShellForGitHub.psm1'
    NestedModules = @(/* 29 domain modules */)
    FunctionsToExport = @(/* 200+ cmdlets */)
    PowerShellVersion = '4.0'  # Minimum version
}
```

#### Command Patterns
- **Get-** cmdlets: Query operations (repositories, issues, users, etc.)
- **Set-** cmdlets: Update operations (configuration, repository settings)
- **New-** cmdlets: Create operations (issues, PRs, branches)
- **Remove-** cmdlets: Delete operations (labels, releases, teams)
- **Add-** cmdlets: Association operations (assignees, collaborators)
- **Invoke-** cmdlets: Direct API operations (GraphQL, REST)

#### Pipeline Philosophy
```powershell
# Pipeline chaining example
Get-GitHubRepository -OwnerName 'microsoft' -RepositoryName 'vscode' |
    Get-GitHubIssue -State Open |
    Where-Object { $_.labels.name -contains 'bug' } |
    Set-GitHubIssue -State Closed
```

### GitHub API Knowledge

#### REST API v3 Coverage
- **Repositories**: Full CRUD + settings, branches, content, traffic
- **Issues**: Lifecycle, comments, assignees, labels, milestones, events
- **Pull Requests**: Creation, review, merging
- **Projects**: Boards, columns, cards (full project management)
- **Teams & Organizations**: Membership, permissions
- **Gists**: Full CRUD + starring, forking
- **Deployments**: Environment management
- **Codespaces**: Lifecycle operations

#### GraphQL Support
```powershell
Invoke-GHGraphQl -Query @'
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    branchProtectionRules(first:100) {
      nodes { pattern }
    }
  }
}
'@ -Variables @{ owner='microsoft'; name='PowerShellForGitHub' }
```

### Development Workflows

#### Testing with Pester
```powershell
# Run all tests
Import-Module Pester
Invoke-Pester -Path ./Tests

# Run specific test suite
Invoke-Pester -Path ./Tests/GitHubIssues.tests.ps1

# With code coverage
Invoke-Pester -CodeCoverage ./GitHubIssues.ps1
```

#### Static Analysis
```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path . -Settings PSScriptAnalyzerSettings.psd1 -Recurse
```

#### Contribution Process
1. **Fork & Branch**: Create feature branch from `master`
2. **Code Changes**: Follow coding guidelines (see CONTRIBUTING.md)
3. **Add Tests**: Write Pester tests for new functionality
4. **Run Analysis**: Execute PSScriptAnalyzer for quality checks
5. **Submit PR**: Include test results and analysis output
6. **Maintainer Review**: Requires approval from @HowardWolosky

### Configuration Management

#### Authentication Setup
```powershell
# Interactive (persists across sessions)
Set-GitHubAuthentication

# Automated/CI scenarios
Set-GitHubAuthentication -SessionOnly -AccessToken $env:GITHUB_TOKEN

# Clear cached credentials
Clear-GitHubAuthentication
```

#### Default Configuration
```powershell
# Set default repository context
Set-GitHubConfiguration -DefaultOwnerName 'microsoft'
Set-GitHubConfiguration -DefaultRepositoryName 'PowerShellForGitHub'

# GitHub Enterprise
Set-GitHubConfiguration -ApiHostName 'github.contoso.com'

# Disable telemetry
Set-GitHubConfiguration -DisableTelemetry

# Save configuration
$config = Backup-GitHubConfiguration
```

## Architectural Patterns

### Command Structure
```powershell
# Standard parameter sets
Get-GitHubRepository -Uri 'https://github.com/microsoft/vscode'
Get-GitHubRepository -OwnerName 'microsoft' -RepositoryName 'vscode'

# Pipeline input by property name
@{ OwnerName='microsoft'; RepositoryName='vscode' } |
    Get-GitHubRepository

# Pipeline input by value
Get-GitHubUser -UserName 'octocat' | Get-GitHubRepository
```

### Error Handling
```powershell
try {
    $repo = Get-GitHubRepository -OwnerName 'nonexistent' -RepositoryName 'repo'
}
catch {
    # Exception provides detailed API error information
    Write-Host "API Error: $($_.Exception.Message)"
}
```

### Custom Formatting
```powershell
# Repository objects automatically formatted
Get-GitHubRepository -OwnerName 'microsoft' -RepositoryName 'vscode' |
    Format-Table Name, Description, UpdatedAt

# Custom formatter definitions in Formatters/*.Format.ps1xml
```

## Best Practices

### Code Quality
1. **PSScriptAnalyzer Compliance**: All code must pass static analysis
2. **Multi-Version Support**: Test against PowerShell 4.0, 5.1, 6.2, 7.0+
3. **Pipeline Friendly**: Accept pipeline input, return structured objects
4. **Parameter Validation**: Use ValidateSet, ValidateRange, ValidateScript
5. **Comment-Based Help**: Include .SYNOPSIS, .DESCRIPTION, .EXAMPLE

### Testing Guidelines
1. **Pester Structure**: Use Describe/Context/It blocks
2. **Mock External Calls**: Mock Invoke-RestMethod for unit tests
3. **Integration Tests**: Clearly mark tests requiring API access
4. **Code Coverage**: Aim for >80% coverage on new code
5. **Test Independence**: Tests should not depend on external state

### Documentation
1. **Inline Comments**: Explain complex logic, not obvious code
2. **Function Headers**: Complete comment-based help for all public functions
3. **CHANGELOG**: Document all changes following Keep a Changelog format
4. **README Updates**: Update usage examples for new features
5. **Wiki Sync**: Keep wiki documentation in sync with releases

## Common Operations

### Repository Management
```powershell
# Create repository
$repo = New-GitHubRepository -RepositoryName 'MyProject' -Private

# Update settings
Set-GitHubRepository -Uri $repo.RepositoryUrl -HasIssues:$false

# Enable features
Set-GitHubRepository -Uri $repo.RepositoryUrl -HasDiscussions -AllowAutoMerge
```

### Issue Workflows
```powershell
# Create issue with labels and assignees
$issue = New-GitHubIssue -OwnerName 'microsoft' -RepositoryName 'vscode' `
    -Title 'Bug Report' -Body 'Description here' `
    -Label @('bug', 'needs-triage') -Assignee @('user1', 'user2')

# Update issue
Set-GitHubIssue -Uri $issue.IssueUrl -State Closed

# Add comment
New-GitHubIssueComment -Uri $issue.IssueUrl -Body 'Fixed in PR #123'
```

### Branch Protection
```powershell
# Create pattern-based protection rule (GraphQL)
New-GitHubRepositoryBranchPatternProtectionRule `
    -OwnerName 'microsoft' -RepositoryName 'PowerShellForGitHub' `
    -Pattern 'release/*' -RequireReviews -RequireCodeOwnerReviews

# Get protection rules
Get-GitHubRepositoryBranchPatternProtectionRule `
    -OwnerName 'microsoft' -RepositoryName 'PowerShellForGitHub'
```

### Gist Operations
```powershell
# Create gist
$files = @{
    'script.ps1' = @{ content = 'Get-Process' }
    'readme.md' = @{ content = '# My Script' }
}
$gist = New-GitHubGist -File $files -Description 'PowerShell utility'

# Fork gist
Copy-GitHubGist -Gist $gist.GistId

# Star gist
Add-GitHubGistStar -Gist $gist.GistId
```

## Entelechy Metrics

### Current State Assessment
```
Actualization Score:     81% ████████░░ (Mature Stage)
Completeness Score:      85% ████████░░ (High implementation)
Coherence Score:         88% ████████░░ (Strong integration)
Vitality Score:          78% ███████░░░ (Active growth)
Alignment Score:         90% █████████░ (Clear purpose)

Total Components:        29
Integrated Components:   29
Test Suites:            30
API Coverage:           ~85% of GitHub API v3
Code Quality:           Excellent (PSScriptAnalyzer enforced)
Documentation:          Comprehensive (README, USAGE, Wiki)
```

### Fragmentation Analysis
- **TODO Items**: 13 (minor enhancements)
- **FIXME Items**: 0 (no critical issues)
- **API Gaps**: ~15% (tracked in Issue #70)
- **Test Coverage**: >80% (Azure DevOps metrics)

### Growth Trajectory
The module is in **Mature Stage** (60-80% actualization), progressing toward **Transcendent Stage**:
- Strong foundation and core features complete
- Active development of advanced capabilities
- Low technical debt and high code quality
- Clear roadmap toward full API coverage
- Established contribution and release processes

## Technical Constraints

### PowerShell Version Support
- **Minimum**: PowerShell 4.0 (Windows PowerShell)
- **Recommended**: PowerShell 7.0+ (cross-platform)
- **Compatibility Testing**: Required for all new features

### API Rate Limiting
- **Unauthenticated**: 60 requests/hour
- **Authenticated**: 5,000 requests/hour
- **GraphQL**: Separate point-based system
- **Best Practice**: Always authenticate for production use

### Module Dependencies
- **Required**: PowerShell core modules only
- **Testing**: Pester v4+ (v5 compatible)
- **Analysis**: PSScriptAnalyzer 1.18+
- **No External Dependencies**: Maintains portability

## References

### Primary Documentation
- **README.md**: Installation and quick start
- **USAGE.md**: Comprehensive usage examples
- **CONTRIBUTING.md**: Development guidelines
- **CHANGELOG.md**: Version history and release notes
- **GOVERNANCE.md**: Project governance model

### External Resources
- **GitHub API Docs**: https://developer.github.com/v3/
- **PowerShell Gallery**: https://www.powershellgallery.com/packages/PowerShellForGitHub
- **Issue Tracker**: https://github.com/microsoft/PowerShellForGitHub/issues
- **CI/CD Pipeline**: Azure DevOps (ms/PowerShellForGitHub)

### Community
- **Maintainer**: @HowardWolosky (Microsoft)
- **License**: MIT
- **Code of Conduct**: CODE_OF_CONDUCT.md
- **Security**: SECURITY.md (Microsoft security reporting)

---

**CoGPSh embodies the entelechy of PowerShell automation - bridging human intent with GitHub's computational substrate through elegant, pipeline-native commands that actualize repository management workflows.**
