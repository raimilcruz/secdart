The following BNF notation represents the AST of the supported 
subset of Dart, so is not a grammar specification. 
We use brackets in the BNF rules to refer to the name of the 
class of the Ast node provided by the Dart Analyzer.

```
compilationUnitMember ::= 
       | [FunctionDeclaration]
  
 functionDeclaration ::=
         'external' functionSignature
       | functionSignature [FunctionBody]
 
 functionSignature ::=
         [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
         
 binaryExpression ::=
        [Expression] [Token] [Expression] 
 
         
 functionBody ::=
         [BlockFunctionBody]
       | [EmptyFunctionBody]
       | [ExpressionFunctionBody]
       
 blockFunctionBody ::= block

 expressionFunctionBody ::= '=>' [Expression] ';'

 block ::= '{' statement* '}

 statement ::=
         [Block]
       | [VariableDeclarationStatement]
       | [IfStatement]
       | [ReturnStatement]
       | [ExpressionStatement] 
       
 variableDeclarationStatement ::= 
         [VariableDeclarationList] ';'
         
 variableDeclarationList ::=
         finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
         
 variableDeclaration ::=
         [SimpleIdentifier] ('=' [Expression])?
         
 ifStatement ::=
         'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
         
 returnStatement ::=
         'return' [Expression]? ';'
         
 expressionStatement ::=
         [Expression]? ';'
 

 expression ::=
         [AssignmentExpression]
       | [ConditionalExpression] cascadeSection*
       //the Dart grammar does not include the followings nodes here to avoid left recursion, however for the sake of presentation we inline them here.
       | [BinaryExpression]
       | [InvocationExpression]
       | [Literal]
       | [ParenthesizedExpression]
       | [Identifier]
       
 assignmentExpression ::=
         [Expression] assignmentOperator [Expression]
         
 conditionalExpression ::=
         [Expression] '?' [Expression] ':' [Expression] 
```