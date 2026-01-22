# Phase 2 Extended Features - Comprehensive Demonstration
# OpenCog PowerShell - Advanced Type System, Value Atoms, and Links

# Import the OpenCog module
Import-Module "$PSScriptRoot/../OpenCog.psd1" -Force

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  OpenCog PowerShell - Phase 2 Extended Features Demo        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Create AtomSpace
$kb = New-AtomSpace
Write-Host "`n✓ Created AtomSpace" -ForegroundColor Green

#region Example 1: Extended Value Atoms
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 1: Extended Value Atoms (FloatValue, LinkValue)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# FloatValue - Precise floating-point values
Write-Host "`n→ Creating FloatValue atoms with different precisions..." -ForegroundColor Cyan
$pi = New-FloatValue -Value 3.14159265358979 -Precision 10
$e = New-FloatValue -Value 2.71828182845905 -Precision 10
$phi = New-FloatValue -Value 1.61803398874989 -Precision 8

$kb.AddAtom($pi)
$kb.AddAtom($e)
$kb.AddAtom($phi)

Write-Host "  π (pi) = $(Get-AtomValue $pi) (precision: $($pi.GetPrecision()))" -ForegroundColor White
Write-Host "  e (Euler's number) = $(Get-AtomValue $e) (precision: $($e.GetPrecision()))" -ForegroundColor White
Write-Host "  φ (golden ratio) = $(Get-AtomValue $phi) (precision: $($phi.GetPrecision()))" -ForegroundColor White

# LinkValue - Store links as values
Write-Host "`n→ Creating LinkValue to store a link as a value..." -ForegroundColor Cyan
$concept1 = New-ConceptNode "Mathematics"
$concept2 = New-ConceptNode "Physics"
$relationship = New-SimilarityLink -Atom1 $concept1 -Atom2 $concept2 -Strength 0.8 -Confidence 0.9
$linkValue = New-LinkValue -Link $relationship

$kb.AddAtom($concept1)
$kb.AddAtom($concept2)
$kb.AddAtom($relationship)
$kb.AddAtom($linkValue)

Write-Host "  Stored link: $($relationship.Type) with arity $($relationship.GetArity())" -ForegroundColor White
$retrievedLink = Get-AtomValue $linkValue
Write-Host "  Retrieved link arity: $($retrievedLink.GetArity())" -ForegroundColor White
#endregion

#region Example 2: Union and Intersection Types
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 2: Type System - Union (TypeChoice) and Intersection Types" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# Define base types
Write-Host "`n→ Defining base types..." -ForegroundColor Cyan
$stringType = New-TypeNode -TypeName "StringNode"
$numberType = New-TypeNode -TypeName "NumberNode"
$floatType = New-TypeNode -TypeName "FloatValue"

$kb.AddAtom($stringType)
$kb.AddAtom($numberType)
$kb.AddAtom($floatType)

# TypeChoice (Union Type: A | B)
Write-Host "`n→ Creating TypeChoice (union type: String | Number)..." -ForegroundColor Cyan
$primitiveType = New-TypeChoice -Types @($stringType, $numberType, $floatType)

Write-Host "  Union type contains: String, Number, Float" -ForegroundColor White

# Test type compatibility
$testString = New-StringNode -Value "Hello"
$testNumber = New-NumberNode -Value 42
$testFloat = New-FloatValue -Value 3.14 -Precision 5

Write-Host "`n→ Testing type compatibility with union type..." -ForegroundColor Cyan
Write-Host "  StringNode 'Hello' matches union: $(Test-TypeCompatibility -Atom $testString -Type $primitiveType)" -ForegroundColor White
Write-Host "  NumberNode 42 matches union: $(Test-TypeCompatibility -Atom $testNumber -Type $primitiveType)" -ForegroundColor White
Write-Host "  FloatValue 3.14 matches union: $(Test-TypeCompatibility -Atom $testFloat -Type $primitiveType)" -ForegroundColor White

# TypeIntersection (Intersection Type: A & B)
Write-Host "`n→ Creating TypeIntersection (traits/interfaces)..." -ForegroundColor Cyan
$serializableType = New-TypeNode -TypeName "Serializable"
$comparableType = New-TypeNode -TypeName "Comparable"
$orderedSerializableType = New-TypeIntersection -Types @($serializableType, $comparableType)

$kb.AddAtom($serializableType)
$kb.AddAtom($comparableType)

Write-Host "  Intersection type requires: Serializable AND Comparable" -ForegroundColor White
#endregion

#region Example 3: Scoped Implications
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 3: ImplicationScopeLink - Scoped Logical Rules" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host "`n→ Creating a universal rule: ∀x, Human(x) → Mortal(x)..." -ForegroundColor Cyan

# Variables
$varX = New-VariableNode '$x'
$varList = New-ListLink @($varX)

# Antecedent and Consequent
$humanPred = New-PredicateNode "Human"
$mortalPred = New-PredicateNode "Mortal"
$antecedent = New-EvaluationLink -Predicate $humanPred -Arguments $varList
$consequent = New-EvaluationLink -Predicate $mortalPred -Arguments $varList

# Create scoped implication
$rule = New-ImplicationScopeLink -Variables $varList -Antecedent $antecedent -Consequent $consequent -Strength 0.99 -Confidence 0.95

$kb.AddAtom($varX)
$kb.AddAtom($varList)
$kb.AddAtom($humanPred)
$kb.AddAtom($mortalPred)
$kb.AddAtom($antecedent)
$kb.AddAtom($consequent)
$kb.AddAtom($rule)

Write-Host "  Rule: ∀x, Human(x) → Mortal(x)" -ForegroundColor White
Write-Host "  Truth Value: Strength=$(Get-StrengthOf $rule), Confidence=$(Get-ConfidenceOf $rule)" -ForegroundColor White
Write-Host "  Arity: $($rule.GetArity()) (Variables, Antecedent, Consequent)" -ForegroundColor White

# Another example: Mathematical rule
Write-Host "`n→ Creating a mathematical rule: ∀x, Prime(x) → Integer(x)..." -ForegroundColor Cyan
$varY = New-VariableNode '$y'
$varListY = New-ListLink @($varY)
$primePred = New-PredicateNode "IsPrime"
$integerPred = New-PredicateNode "IsInteger"
$primeAnt = New-EvaluationLink -Predicate $primePred -Arguments $varListY
$integerCon = New-EvaluationLink -Predicate $integerPred -Arguments $varListY
$mathRule = New-ImplicationScopeLink -Variables $varListY -Antecedent $primeAnt -Consequent $integerCon

$kb.AddAtom($varY)
$kb.AddAtom($varListY)
$kb.AddAtom($primePred)
$kb.AddAtom($integerPred)
$kb.AddAtom($primeAnt)
$kb.AddAtom($integerCon)
$kb.AddAtom($mathRule)

Write-Host "  Rule: ∀y, IsPrime(y) → IsInteger(y)" -ForegroundColor White
#endregion

#region Example 4: Temporal Presence with PresentLink
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 4: PresentLink - Temporal Presence Assertions" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host "`n→ Marking events as currently present..." -ForegroundColor Cyan

# Current events
$meeting = New-ConceptNode "TeamMeeting"
$weather = New-ConceptNode "SunnyWeather"
$task = New-ConceptNode "ProcessingData"

# Mark as present
$presentMeeting = New-PresentLink -Atom $meeting -Strength 1.0 -Confidence 0.95
$presentWeather = New-PresentLink -Atom $weather -Strength 0.9 -Confidence 0.8
$presentTask = New-PresentLink -Atom $task -Strength 1.0 -Confidence 1.0

$kb.AddAtom($meeting)
$kb.AddAtom($weather)
$kb.AddAtom($task)
$kb.AddAtom($presentMeeting)
$kb.AddAtom($presentWeather)
$kb.AddAtom($presentTask)

Write-Host "  Present: TeamMeeting (strength: $(Get-StrengthOf $presentMeeting))" -ForegroundColor White
Write-Host "  Present: SunnyWeather (strength: $(Get-StrengthOf $presentWeather))" -ForegroundColor White
Write-Host "  Present: ProcessingData (strength: $(Get-StrengthOf $presentTask))" -ForegroundColor White

Write-Host "`n→ Verifying PresentLink type..." -ForegroundColor Cyan
Write-Host "  Is PresentLink: $(Test-AtomType -Atom $presentMeeting -SubType 'PresentLink')" -ForegroundColor White
#endregion

#region Example 5: Truth Value Extractors
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 5: Truth Value Extractors - Fine-grained Access" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host "`n→ Creating facts with different truth values..." -ForegroundColor Cyan

$certainFact = New-ConceptNode "WaterIsWet" -Strength 0.99 -Confidence 0.99
$likelyFact = New-ConceptNode "ItWillRainTomorrow" -Strength 0.7 -Confidence 0.6
$uncertainFact = New-ConceptNode "AliensExist" -Strength 0.5 -Confidence 0.3

$kb.AddAtom($certainFact)
$kb.AddAtom($likelyFact)
$kb.AddAtom($uncertainFact)

Write-Host "`n→ Extracting truth values..." -ForegroundColor Cyan
foreach ($fact in @($certainFact, $likelyFact, $uncertainFact)) {
    $tv = Get-TruthValueOf -Atom $fact
    $strength = Get-StrengthOf -Atom $fact
    $confidence = Get-ConfidenceOf -Atom $fact
    
    Write-Host "`n  Fact: $($fact.Name)" -ForegroundColor White
    Write-Host "    Strength: $strength" -ForegroundColor White
    Write-Host "    Confidence: $confidence" -ForegroundColor White
    Write-Host "    Certainty: $(if ($strength * $confidence -gt 0.7) { 'High' } elseif ($strength * $confidence -gt 0.4) { 'Medium' } else { 'Low' })" -ForegroundColor White
}
#endregion

#region Example 6: Type Hierarchy and Annotations
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 6: Type Hierarchy and Type Annotations" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host "`n→ Creating typed entities..." -ForegroundColor Cyan

# Define custom types
$personType = New-TypeNode -TypeName "Person"
$animalType = New-TypeNode -TypeName "Animal"
$entityType = New-TypeNode -TypeName "Entity"

$kb.AddAtom($personType)
$kb.AddAtom($animalType)
$kb.AddAtom($entityType)

# Create entities with type annotations
$alice = New-ConceptNode "Alice"
$bob = New-ConceptNode "Bob"
$dog = New-ConceptNode "Fido"

$kb.AddAtom($alice)
$kb.AddAtom($bob)
$kb.AddAtom($dog)

# Add type annotations
$aliceTyped = New-TypedAtomLink -Atom $alice -Type $personType
$bobTyped = New-TypedAtomLink -Atom $bob -Type $personType
$dogTyped = New-TypedAtomLink -Atom $dog -Type $animalType

$kb.AddAtom($aliceTyped)
$kb.AddAtom($bobTyped)
$kb.AddAtom($dogTyped)

Write-Host "  Alice: Person" -ForegroundColor White
Write-Host "  Bob: Person" -ForegroundColor White
Write-Host "  Fido: Animal" -ForegroundColor White

# Get type hierarchy
Write-Host "`n→ Querying type hierarchy..." -ForegroundColor Cyan
$aliceTypes = Get-TypeHierarchy -Atom $alice -AtomSpace $kb
Write-Host "  Alice has $($aliceTypes.Count) type annotation(s)" -ForegroundColor White
if ($aliceTypes.Count -gt 0) {
    foreach ($type in $aliceTypes) {
        Write-Host "    - $($type.Name)" -ForegroundColor White
    }
}
#endregion

#region Example 7: Complex Type-Safe Function Signatures
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Example 7: Type-Safe Function Signatures with Union Types" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

Write-Host "`n→ Defining a function: process(input: String | Number) -> Boolean..." -ForegroundColor Cyan

# Define function
$processFunc = New-PredicateNode "Process"

# Input type: String | Number (union type)
$inputType = New-TypeChoice -Types @($stringType, $numberType)

# Output type
$boolType = New-TypeNode -TypeName "Boolean"
$kb.AddAtom($boolType)

# Create function signature: (String | Number) -> Boolean
$inputList = New-ListLink @($inputType)
$arrow = New-ArrowLink -InputTypes $inputList -OutputType $boolType
$signature = New-SignatureLink -Function $processFunc -Signature $arrow

$kb.AddAtom($processFunc)
$kb.AddAtom($inputList)
$kb.AddAtom($arrow)
$kb.AddAtom($signature)

Write-Host "  Function: Process(String | Number) -> Boolean" -ForegroundColor White
Write-Host "  Input accepts: String OR Number" -ForegroundColor White
Write-Host "  Output type: Boolean" -ForegroundColor White

# Another example with intersection types
Write-Host "`n→ Defining a function: serialize(input: Serializable & Comparable) -> String..." -ForegroundColor Cyan

$serializeFunc = New-PredicateNode "Serialize"
$inputIntersection = New-TypeIntersection -Types @($serializableType, $comparableType)
$inputList2 = New-ListLink @($inputIntersection)
$arrow2 = New-ArrowLink -InputTypes $inputList2 -OutputType $stringType
$signature2 = New-SignatureLink -Function $serializeFunc -Signature $arrow2

$kb.AddAtom($serializeFunc)
$kb.AddAtom($inputList2)
$kb.AddAtom($arrow2)
$kb.AddAtom($signature2)

Write-Host "  Function: Serialize(Serializable & Comparable) -> String" -ForegroundColor White
Write-Host "  Input requires: Serializable AND Comparable" -ForegroundColor White
Write-Host "  Output type: String" -ForegroundColor White
#endregion

#region Statistics
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Knowledge Base Statistics" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

$stats = $kb.GetStatistics()
Write-Host "`n  Total Atoms: $($stats.TotalAtoms)" -ForegroundColor White
Write-Host "  Nodes: $($stats.NodeCount)" -ForegroundColor White
Write-Host "  Links: $($stats.LinkCount)" -ForegroundColor White
Write-Host "  Types: ConceptNode, PredicateNode, VariableNode, TypeNode, NumberNode, StringNode, FloatValue, LinkValue" -ForegroundColor White
Write-Host "  Advanced Links: ImplicationScopeLink, PresentLink, TypedAtomLink, SignatureLink, ArrowLink" -ForegroundColor White
Write-Host "  Type System: TypeChoice (union), TypeIntersection (intersection)" -ForegroundColor White
#endregion

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Phase 2 Extended Features Demonstration Complete!           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n✓ All Phase 2 Extended features demonstrated successfully!" -ForegroundColor Green
Write-Host "  - FloatValue and LinkValue for advanced value storage" -ForegroundColor White
Write-Host "  - TypeChoice (union) and TypeIntersection for flexible typing" -ForegroundColor White
Write-Host "  - ImplicationScopeLink for universal logical rules" -ForegroundColor White
Write-Host "  - PresentLink for temporal assertions" -ForegroundColor White
Write-Host "  - Truth value extractors for fine-grained access" -ForegroundColor White
Write-Host "  - Type hierarchy querying and annotations" -ForegroundColor White
Write-Host "  - Complex type-safe function signatures" -ForegroundColor White

Write-Host "`nPhase 2 Extended Features: 100% Complete! 🎉" -ForegroundColor Green
