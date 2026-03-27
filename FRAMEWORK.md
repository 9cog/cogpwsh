# cogpwsh — 9cog Framework Role

## Role: Cognitive Layer (Knowledge Graph + GitHub API)

cogpwsh provides the cognitive computing layer for the 9cog framework:

1. **OpenCog Knowledge Graph** — Hypergraph knowledge base with pattern matching
2. **PowerShellForGitHub** — GitHub API wrapper for repository management

## Framework Integration

### Knowledge Graph Bridge

The OpenCog implementation in `OpenCog/` provides the conceptual foundation
for the framework's knowledge layer. The Go implementation in the framework
core (`9fs9rc/framework/aifs/knowledge.go`) is a port of these concepts:

| cogpwsh (PowerShell) | Framework (Go) | Concept |
|---------------------|----------------|--------|
| `Atoms.psm1` | `knowledge.go:Atom` | Node/Link types |
| `AtomSpace.psm1` | `knowledge.go:KnowledgeGraph` | Indexed hypergraph |
| `PatternMatcher.psm1` | `knowledge.go:Query()` | Pattern matching |
| TruthValue class | `knowledge.go:TruthValue` | Probabilistic belief |

### Atom Types Mapped to Framework

```
cogpwsh                    → 9cog filesystem path
────────────────────────── → ─────────────────────
New-ConceptNode "Cat"      → echo Cat > /ai/knowledge/concepts/Cat
New-InheritanceLink        → /ai/knowledge/relations/
New-PatternQuery           → echo 'InheritanceLink 5 1' > /ai/knowledge/query
Get-AtomSpace stats        → cat /ai/knowledge/stats
```

### GitHub Integration

PowerShellForGitHub's 200+ cmdlets enable framework-level repository operations:

```powershell
# Query framework repos
Get-GitHubRepository -Owner 9cog | ForEach-Object {
    $stats = Get-GitHubRepositoryLanguage -Uri $_.html_url
    [PSCustomObject]@{
        Repo = $_.name
        Languages = ($stats.PSObject.Properties.Name -join ', ')
    }
}

# Framework-aware operations
$repos = @('9fs9rc', 'go9p', 'diod', 'cogpwsh', '120c', 'lua9p', 'aichat', 'airc')
foreach ($repo in $repos) {
    $issues = Get-GitHubIssue -OwnerName 9cog -RepositoryName $repo
    Write-Host "$repo: $($issues.Count) open issues"
}
```

### Exotic Atoms for Framework

Phase 4 exotic atoms map directly to framework components:

```powershell
# Create framework topology in knowledge graph
$hub = New-GitHubRepoAtom "9cog/9fs9rc" "Framework integration hub"
$proto = New-GitHubRepoAtom "9-p9/go9p" "9P protocol library"
$link = New-InheritanceLink -Child $proto -Parent $hub

# Azure/Exchange atoms for enterprise deployment
$tenant = New-AzureEntraTenantAtom "contoso" "Enterprise tenant"
```

## Architecture

```
┌─────────────────────────────┐
│  /ai/knowledge/ (9P files)  │
├─────────────────────────────┤
│  KnowledgeGraph (Go port)   │
│  in 9fs9rc/framework/aifs   │
├─────────────────────────────┤
│  OpenCog (PowerShell)       │  ← conceptual source
│  in cogpwsh/OpenCog/        │
│  Atoms, AtomSpace, Pattern  │
│  Matcher, ExoticAtoms       │
└─────────────────────────────┘
```

## See Also

- [9cog Framework Architecture](https://github.com/9cog/9fs9rc/blob/main/framework/ARCHITECTURE.md)
- [OpenCog README](OpenCog/README.md)
