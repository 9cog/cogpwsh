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
|---------------------|----------------|---------|
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

## See Also

- [9cog Framework Architecture](https://github.com/9cog/9fs9rc/blob/main/framework/ARCHITECTURE.md)
- [OpenCog README](OpenCog/README.md)
