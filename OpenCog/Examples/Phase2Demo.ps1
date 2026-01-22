<#
.SYNOPSIS
    Phase 2 Extended Atom Types - Demonstration
    
.DESCRIPTION
    Demonstrates the new Phase 2 features of OpenCog PowerShell:
    - Advanced Link Types (ContextLink, MemberLink, SubsetLink, etc.)
    - Type System (TypeNode, TypedAtomLink, SignatureLink, ArrowLink)
    - Value Atoms (NumberNode, StringNode)
    
.NOTES
    OpenCog PowerShell Phase 2 - Extended Atom Types
#>

# Import the OpenCog module
Import-Module "$PSScriptRoot/../OpenCog.psd1" -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenCog Phase 2: Extended Atom Types Demo" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Create an AtomSpace
$kb = New-AtomSpace
Write-Host "Created AtomSpace`n" -ForegroundColor Green

#
# 1. Value Atoms - NumberNode and StringNode
#
Write-Host "1. Value Atoms Demo" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

# Create numeric values
$age = New-NumberNode -Value 25
$height = New-NumberNode -Value 180.5
$pi = New-NumberNode -Value 3.14159

$kb.AddAtom($age)
$kb.AddAtom($height)
$kb.AddAtom($pi)

Write-Host "Created NumberNodes:"
Write-Host "  Age: $(Get-AtomValue $age)"
Write-Host "  Height: $(Get-AtomValue $height) cm"
Write-Host "  Pi: $(Get-AtomValue $pi)"

# Create string values
$name = New-StringNode -Value "Alice"
$city = New-StringNode -Value "New York"

$kb.AddAtom($name)
$kb.AddAtom($city)

Write-Host "`nCreated StringNodes:"
Write-Host "  Name: $(Get-AtomValue $name)"
Write-Host "  City: $(Get-AtomValue $city)`n"

#
# 2. Advanced Link Types - Set Theory
#
Write-Host "2. Set Theory with MemberLink and SubsetLink" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Yellow

# Create concepts for set theory
$alice = New-ConceptNode "Alice"
$bob = New-ConceptNode "Bob"
$charlie = New-ConceptNode "Charlie"

$people = New-ConceptNode "People"
$employees = New-ConceptNode "Employees"
$managers = New-ConceptNode "Managers"

$kb.AddAtom($alice)
$kb.AddAtom($bob)
$kb.AddAtom($charlie)
$kb.AddAtom($people)
$kb.AddAtom($employees)
$kb.AddAtom($managers)

# Create membership relationships
$aliceMember = New-MemberLink -Element $alice -Set $employees
$bobMember = New-MemberLink -Element $bob -Set $employees
$charlieMember = New-MemberLink -Element $charlie -Set $managers

$kb.AddAtom($aliceMember)
$kb.AddAtom($bobMember)
$kb.AddAtom($charlieMember)

Write-Host "Created MemberLinks:"
Write-Host "  Alice ∈ Employees"
Write-Host "  Bob ∈ Employees"
Write-Host "  Charlie ∈ Managers"

# Create subset relationships
$employeesSubset = New-SubsetLink -Subset $employees -Superset $people
$managersSubset = New-SubsetLink -Subset $managers -Superset $employees

$kb.AddAtom($employeesSubset)
$kb.AddAtom($managersSubset)

Write-Host "`nCreated SubsetLinks:"
Write-Host "  Employees ⊆ People"
Write-Host "  Managers ⊆ Employees"

# Verify link types
Write-Host "`nVerifying link types:"
Write-Host "  aliceMember is MemberLink: $(Test-AtomType $aliceMember 'MemberLink')"
Write-Host "  employeesSubset is SubsetLink: $(Test-AtomType $employeesSubset 'SubsetLink')`n"

#
# 3. Contextual Relationships with ContextLink
#
Write-Host "3. Contextual Relationships" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow

# Create contexts
$workContext = New-ConceptNode "WorkContext"
$homeContext = New-ConceptNode "HomeContext"

$kb.AddAtom($workContext)
$kb.AddAtom($homeContext)

# Create contextual facts
$aliceRole = New-ConceptNode "AliceIsManager"
$aliceHobby = New-ConceptNode "AlicePlaysGuitar"

$kb.AddAtom($aliceRole)
$kb.AddAtom($aliceHobby)

# Associate facts with contexts
$workFact = New-ContextLink -Context $workContext -Atom $aliceRole
$homeFact = New-ContextLink -Context $homeContext -Atom $aliceHobby

$kb.AddAtom($workFact)
$kb.AddAtom($homeFact)

Write-Host "Created ContextLinks:"
Write-Host "  In WorkContext: Alice is Manager"
Write-Host "  In HomeContext: Alice plays Guitar"

Write-Host "`nContextLinks allow facts to be scoped to specific contexts."
Write-Host "This is useful for representing knowledge that varies by situation.`n"

#
# 4. Type System
#
Write-Host "4. Type System Demo" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

# Create type definitions
$stringType = New-TypeNode -TypeName "String"
$numberType = New-TypeNode -TypeName "Number"
$personType = New-TypeNode -TypeName "Person"

$kb.AddAtom($stringType)
$kb.AddAtom($numberType)
$kb.AddAtom($personType)

Write-Host "Created TypeNodes:"
Write-Host "  String, Number, Person"

# Create typed atoms
$nameTyped = New-TypedAtomLink -Atom $name -Type $stringType
$ageTyped = New-TypedAtomLink -Atom $age -Type $numberType
$aliceTyped = New-TypedAtomLink -Atom $alice -Type $personType

$kb.AddAtom($nameTyped)
$kb.AddAtom($ageTyped)
$kb.AddAtom($aliceTyped)

Write-Host "`nCreated TypedAtomLinks:"
Write-Host "  name: String"
Write-Host "  age: Number"
Write-Host "  alice: Person"

# Create function signature
$greetPredicate = New-PredicateNode "Greet"
$kb.AddAtom($greetPredicate)

# Signature: Greet(Person, String) -> String
$inputTypes = New-ListLink @($personType, $stringType)
$kb.AddAtom($inputTypes)

$greetArrow = New-ArrowLink -InputTypes $inputTypes -OutputType $stringType
$kb.AddAtom($greetArrow)

$greetSignature = New-SignatureLink -Function $greetPredicate -Signature $greetArrow
$kb.AddAtom($greetSignature)

Write-Host "`nCreated function signature:"
Write-Host "  Greet: (Person, String) -> String"
Write-Host "  This defines that Greet takes a Person and String, returns String`n"

#
# 5. Equivalence Relationships
#
Write-Host "5. Equivalence Relationships" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

# Create equivalent concepts
$bachelor = New-ConceptNode "Bachelor"
$unmarriedMan = New-ConceptNode "UnmarriedMan"

$kb.AddAtom($bachelor)
$kb.AddAtom($unmarriedMan)

# Create equivalence
$equiv = New-EquivalenceLink -Atom1 $bachelor -Atom2 $unmarriedMan -Strength 0.95
$kb.AddAtom($equiv)

Write-Host "Created EquivalenceLink:"
Write-Host "  Bachelor ↔ UnmarriedMan (strength: 0.95)"
Write-Host "  This represents that the concepts are equivalent/interchangeable`n"

#
# 6. Sequential Operations
#
Write-Host "6. Sequential Operations with SequentialAndLink" -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Yellow

# Create action steps
$step1 = New-ConceptNode "OpenDoor"
$step2 = New-ConceptNode "WalkThrough"
$step3 = New-ConceptNode "CloseDoor"

$kb.AddAtom($step1)
$kb.AddAtom($step2)
$kb.AddAtom($step3)

# Create ordered sequence
$sequence = New-SequentialAndLink -Atoms @($step1, $step2, $step3)
$kb.AddAtom($sequence)

Write-Host "Created SequentialAndLink:"
Write-Host "  1. Open Door"
Write-Host "  2. Walk Through"
Write-Host "  3. Close Door"
Write-Host "  Order matters - steps must happen in sequence`n"

#
# 7. AtomSpace Statistics
#
Write-Host "7. AtomSpace Statistics" -ForegroundColor Yellow
Write-Host "-----------------------" -ForegroundColor Yellow

$stats = $kb.GetStatistics()
Write-Host "Total Atoms: $($stats.TotalAtoms)"
Write-Host "Nodes: $($stats.NodeCount)"
Write-Host "Links: $($stats.LinkCount)"

Write-Host "`nAtom Type Breakdown:"
foreach ($typeStat in $stats.TypeStats) {
    if ($typeStat.Value -gt 0) {
        Write-Host "  $($typeStat.Key): $($typeStat.Value)"
    }
}

#
# Summary
#
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 2 Features Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host @"

Phase 2 Extended Atom Types provides:

1. VALUE ATOMS
   - NumberNode: Store numeric constants
   - StringNode: Store string values
   - Get-AtomValue: Extract values from atoms

2. ADVANCED LINKS
   - MemberLink: Set membership (element ∈ set)
   - SubsetLink: Subset relationships (A ⊆ B)
   - ContextLink: Context-dependent facts
   - EquivalenceLink: Bidirectional equivalence (A ↔ B)
   - SequentialAndLink: Ordered sequences

3. TYPE SYSTEM
   - TypeNode: Define types
   - TypedAtomLink: Annotate atoms with types
   - SignatureLink: Define function signatures
   - ArrowLink: Function types (Input -> Output)

4. UTILITIES
   - Test-AtomType: Check atom subtypes
   - Get-AtomValue: Extract values

These features extend OpenCog PowerShell's knowledge
representation capabilities, enabling:
- Typed cognitive architectures
- Set theory operations
- Context-aware reasoning
- Value-based computations
- Type-safe function definitions

"@ -ForegroundColor Green

Write-Host "Demo Complete!" -ForegroundColor Cyan
