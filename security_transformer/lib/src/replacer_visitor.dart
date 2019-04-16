import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/sec_analyzer.dart';
import 'package:security_transformer/src/utils.dart';

class ReplacerVisitor extends SimpleAstVisitor {
  static final SecurityVisitor _visitor = new SecurityVisitor();

  @override
  visitAdjacentStrings(AdjacentStrings node) {
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAnnotation(Annotation node) {
    // node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAsExpression(AsExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAssertInitializer(AssertInitializer node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitBlock(Block node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitCatchClause(CatchClause node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitComment(Comment node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitCommentReference(CommentReference node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitConfiguration(Configuration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitDoStatement(DoStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitDottedName(DottedName node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitExportDirective(ExportDirective node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitForStatement(ForStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitGenericFunctionType(GenericFunctionType node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitGenericTypeAlias(GenericTypeAlias node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitHideCombinator(HideCombinator node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitIfStatement(IfStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitImportDirective(ImportDirective node) {
    //node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.argumentList?.accept(this); // Do not visit the constructorName
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitInterpolationString(InterpolationString node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitIsExpression(IsExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitLabel(Label node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitNativeClause(NativeClause node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPartDirective(PartDirective node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitScriptTag(ScriptTag node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitThisExpression(ThisExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTryStatement(TryStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTypeName(TypeName node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitWithClause(WithClause node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    node.visitChildren(this);
    final parent = node.parent;
    replaceNodeInAst(node, node.accept(_visitor), parent: parent);
  }
}

class SecurityVisitor extends SimpleAstVisitor<AstNode> {
  static var _size = 0;

  @override
  AstNode visitAdjacentStrings(AdjacentStrings node) {
    Iterable stringSecurityValues = node.strings.map((e) => e.accept(this));
    return createFunctionInvocation('SecurityContext.adjacentStrings',
        ['[${stringSecurityValues.join(", ")}]']);
  }

  @override
  AstNode visitAnnotation(Annotation node) => node;

  @override
  AstNode visitArgumentList(ArgumentList node) => node;

  @override
  AstNode visitAsExpression(AsExpression node) => node;

  @override
  AstNode visitAssertInitializer(AssertInitializer node) => node;

  @override
  AstNode visitAssertStatement(AssertStatement node) => node;

  @override
  AstNode visitAssignmentExpression(AssignmentExpression node) =>
      createFunctionInvocation('SecurityContext.assign',
          [node.leftHandSide.toString(), node.rightHandSide.toString()]);

  @override
  AstNode visitAwaitExpression(AwaitExpression node) => node;

  @override
  AstNode visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
      return createFunctionInvocation(
          'SecurityContext.ampersandAmpersandBinaryExpression',
          [node.leftOperand.toString(), node.rightOperand.toString()]);
    } else if (node.operator.type == TokenType.BANG_EQ) {
      return createFunctionInvocation(
          'SecurityContext.bangEqualBinaryExpression',
          [node.leftOperand.toString(), node.rightOperand.toString()]);
    } else if (node.operator.type == TokenType.BAR_BAR) {
      return createFunctionInvocation('SecurityContext.barBarBinaryExpression',
          [node.leftOperand.toString(), node.rightOperand.toString()]);
    } else if (node.operator.type == TokenType.EQ_EQ) {
      return createFunctionInvocation(
          'SecurityContext.equalEqualBinaryExpression',
          [node.leftOperand.toString(), node.rightOperand.toString()]);
    } else if (node.operator.type == TokenType.QUESTION_QUESTION) {
      return createFunctionInvocation(
          'SecurityContext.questionQuestionBinaryExpression',
          [node.leftOperand.toString(), node.rightOperand.toString()]);
    }
    return node;
  }

  @override
  AstNode visitBlock(Block node) => node;

  @override
  AstNode visitBlockFunctionBody(BlockFunctionBody node) {
    return _visitFunctionBody(node, node.block);
  }

  @override
  AstNode visitBooleanLiteral(BooleanLiteral node) {
    return createFunctionInvocation(
        'SecurityContext.booleanLiteral', ["${node.value}"]);
  }

  @override
  AstNode visitBreakStatement(BreakStatement node) => node;

  @override
  AstNode visitCascadeExpression(CascadeExpression node) => node;

  @override
  AstNode visitCatchClause(CatchClause node) => node;

  @override
  AstNode visitClassDeclaration(ClassDeclaration node) => node;

  @override
  AstNode visitClassTypeAlias(ClassTypeAlias node) => node;

  @override
  AstNode visitComment(Comment node) => node;

  @override
  AstNode visitCommentReference(CommentReference node) => node;

  @override
  AstNode visitCompilationUnit(CompilationUnit node) => node;

  @override
  AstNode visitConditionalExpression(ConditionalExpression node) {
    final thenLambda =
        createLambdaWithSingleReturnExpression(node.thenExpression);
    final elseLambda =
        createLambdaWithSingleReturnExpression(node.elseExpression);
    return createFunctionInvocation('SecurityContext.conditionalExpression', [
      node.condition.toString(),
      thenLambda.toString(),
      elseLambda.toString()
    ]);
  }

  @override
  AstNode visitConfiguration(Configuration node) => node;

  @override
  AstNode visitConstructorDeclaration(ConstructorDeclaration node) => node;

  @override
  AstNode visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      node;

  @override
  AstNode visitConstructorName(ConstructorName node) => node;

  @override
  AstNode visitContinueStatement(ContinueStatement node) => node;

  @override
  AstNode visitDeclaredIdentifier(DeclaredIdentifier node) => node;

  @override
  AstNode visitDefaultFormalParameter(DefaultFormalParameter node) => node;

  @override
  AstNode visitDoStatement(DoStatement node) => node;

  @override
  AstNode visitDottedName(DottedName node) => node;

  @override
  AstNode visitDoubleLiteral(DoubleLiteral node) {
    return createFunctionInvocation(
        'SecurityContext.doubleLiteral', ["${node.value}"]);
  }

  @override
  AstNode visitEmptyFunctionBody(EmptyFunctionBody node) => node;

  @override
  AstNode visitEmptyStatement(EmptyStatement node) => node;

  @override
  AstNode visitEnumConstantDeclaration(EnumConstantDeclaration node) => node;

  @override
  AstNode visitEnumDeclaration(EnumDeclaration node) => node;

  @override
  AstNode visitExportDirective(ExportDirective node) => node;

  @override
  AstNode visitExpressionFunctionBody(ExpressionFunctionBody node) {
    final functionExpression = node.parent as FunctionExpression;
    final returnType = functionExpression.element.returnType.name;
    final bodyStatement = returnType == 'void'
        ? createStatementExpressionWithExpression(node.expression)
        : _visitReturnStatement(
            createReturnStatementWithExpression(node.expression),
            (functionExpression.getProperty('sec-type') as SecurityFunctionType)
                .returnType
                .label
                .toString());
    return _visitFunctionBody(node, bodyStatement);
  }

  @override
  AstNode visitExpressionStatement(ExpressionStatement node) => node;

  @override
  AstNode visitExtendsClause(ExtendsClause node) => node;

  @override
  AstNode visitFieldDeclaration(FieldDeclaration node) => node;

  @override
  AstNode visitFieldFormalParameter(FieldFormalParameter node) => node;

  @override
  AstNode visitForEachStatement(ForEachStatement node) => node;

  @override
  AstNode visitFormalParameterList(FormalParameterList node) => node;

  @override
  AstNode visitForStatement(ForStatement node) {
    replaceNodeInAst(
        node.condition,
        createFunctionInvocation('SecurityContext.evaluateConditionAndUpdatePc',
            [node.condition.toString(), _size.toString()]));
    final recoverStatement = createExpressionStatementWithFunctionInvocation(
        'SecurityContext.recoverPc', [_size.toString()]);
    _size++;
    return createBlock([node, recoverStatement]);
  }

  @override
  AstNode visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.name == 'main' || node.parent is! CompilationUnit) {
      return node;
    }
    return parseTopLevelVariableDeclaration(
        'var', node.name.name, _visitFunctionDeclaration(node));
  }

  @override
  AstNode visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    return parseVariableDeclarationStatement(
        'var',
        node.functionDeclaration.name.name,
        _visitFunctionDeclaration(node.functionDeclaration));
  }

  @override
  AstNode visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      return node;
    }
    return createFunctionInvocation(
        'SecurityContext.functionLiteral', [node.toString()]);
  }

  @override
  AstNode visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      node;

  @override
  AstNode visitFunctionTypeAlias(FunctionTypeAlias node) => node;

  @override
  AstNode visitFunctionTypedFormalParameter(
          FunctionTypedFormalParameter node) =>
      node;

  @override
  AstNode visitGenericFunctionType(GenericFunctionType node) => node;

  @override
  AstNode visitGenericTypeAlias(GenericTypeAlias node) => node;

  @override
  AstNode visitHideCombinator(HideCombinator node) => node;

  @override
  AstNode visitIfStatement(IfStatement node) {
    replaceNodeInAst(
        node.condition,
        createFunctionInvocation('SecurityContext.evaluateConditionAndUpdatePc',
            [node.condition.toString(), _size.toString()]));
    final recoverStatement = createExpressionStatementWithFunctionInvocation(
        'SecurityContext.recoverPc', [_size.toString()]);
    _size++;
    return createBlock([node, recoverStatement]);
  }

  @override
  AstNode visitImplementsClause(ImplementsClause node) => node;

  @override
  AstNode visitImportDirective(ImportDirective node) => node;

  @override
  AstNode visitIndexExpression(IndexExpression node) => node;

  @override
  AstNode visitInstanceCreationExpression(InstanceCreationExpression node) =>
      createFunctionInvocation(
          'SecurityContext.instanceCreation', ["${node.toString()}"]);

  @override
  AstNode visitIntegerLiteral(IntegerLiteral node) => createFunctionInvocation(
      'SecurityContext.integerLiteral', ["${node.value}"]);

  @override
  AstNode visitInterpolationExpression(InterpolationExpression node) => node;

  @override
  AstNode visitInterpolationString(InterpolationString node) => node;

  @override
  AstNode visitIsExpression(IsExpression node) => node;

  @override
  AstNode visitLabel(Label node) => node;

  @override
  AstNode visitLabeledStatement(LabeledStatement node) => node;

  @override
  AstNode visitLibraryDirective(LibraryDirective node) => node;

  @override
  AstNode visitLibraryIdentifier(LibraryIdentifier node) => node;

  @override
  AstNode visitListLiteral(ListLiteral node) => node;

  @override
  AstNode visitMapLiteral(MapLiteral node) => node;

  @override
  AstNode visitMapLiteralEntry(MapLiteralEntry node) => node;

  @override
  AstNode visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) {
      replaceNodeInAst(node.parameters,
          createParametersWithSecurityValue(node.parameters.parameters),
          parent: node);
    }
    return node;
  }

  @override
  AstNode visitMethodInvocation(MethodInvocation node) {
    if (_isStatic(node) || !node.methodName.name.startsWith('_')) {
      return node;
    }
    return createInvokeInvocation(
        node.target?.toString(),
        node.operator?.stringValue,
        node.methodName.name,
        node.argumentList.arguments.map((e) => e.toString()).toList(),
        className: node.methodName.bestElement?.enclosingElement?.name);
  }

  @override
  AstNode visitNamedExpression(NamedExpression node) => node;

  @override
  AstNode visitNativeClause(NativeClause node) => node;

  @override
  AstNode visitNativeFunctionBody(NativeFunctionBody node) => node;

  @override
  AstNode visitNullLiteral(NullLiteral node) =>
      createFunctionInvocation('SecurityContext.nullLiteral', []);

  @override
  AstNode visitParenthesizedExpression(ParenthesizedExpression node) => node;

  @override
  AstNode visitPartDirective(PartDirective node) => node;

  @override
  AstNode visitPartOfDirective(PartOfDirective node) => node;

  @override
  AstNode visitPostfixExpression(PostfixExpression node) => node;

  @override
  AstNode visitPrefixedIdentifier(PrefixedIdentifier node) =>
      node.identifier.name.startsWith('_')
          ? createGetFieldInvocation(
              node.prefix.name, node.period.stringValue, node.identifier.name,
              className: node.identifier.bestElement?.enclosingElement?.name)
          : node;

  @override
  AstNode visitPrefixExpression(PrefixExpression node) => node;

  @override
  AstNode visitPropertyAccess(PropertyAccess node) =>
      node.propertyName.name.startsWith('_')
          ? createGetFieldInvocation(node.target.toString(),
              node.operator.stringValue, node.propertyName.name,
              className: node.propertyName.bestElement?.enclosingElement?.name)
          : node;

  @override
  AstNode visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      node;

  @override
  AstNode visitRethrowExpression(RethrowExpression node) => node;

  @override
  AstNode visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      return node;
    }
    final functionExpression =
        node.getAncestor((e) => e is FunctionExpression) as FunctionExpression;
    SecurityFunctionType functionType =
        functionExpression.getProperty('sec-type') as SecurityFunctionType;
    final staticReturnLabel = functionType.returnType.label.toString();
    return _visitReturnStatement(node, staticReturnLabel);
  }

  @override
  AstNode visitScriptTag(ScriptTag node) => node;

  @override
  AstNode visitShowCombinator(ShowCombinator node) => node;

  @override
  AstNode visitSimpleFormalParameter(SimpleFormalParameter node) => node;

  @override
  AstNode visitSimpleIdentifier(SimpleIdentifier node) => node;

  @override
  AstNode visitSimpleStringLiteral(SimpleStringLiteral node) {
    return createFunctionInvocation(
        'SecurityContext.stringLiteral', ["\"${node.stringValue}\""]);
  }

  @override
  AstNode visitStringInterpolation(StringInterpolation node) => node;

  @override
  AstNode visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      node;

  @override
  AstNode visitSuperExpression(SuperExpression node) => node;

  @override
  AstNode visitSwitchCase(SwitchCase node) => node;

  @override
  AstNode visitSwitchDefault(SwitchDefault node) => node;

  @override
  AstNode visitSwitchStatement(SwitchStatement node) => node;

  @override
  AstNode visitSymbolLiteral(SymbolLiteral node) => node;

  @override
  AstNode visitThisExpression(ThisExpression node) => node;

  @override
  AstNode visitThrowExpression(ThrowExpression node) => node;

  @override
  AstNode visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      node;

  @override
  AstNode visitTryStatement(TryStatement node) => node;

  @override
  AstNode visitTypeArgumentList(TypeArgumentList node) => node;

  @override
  AstNode visitTypeName(TypeName node) {
    return node.name.name == 'void' ? node : createDynamicTypeName();
  }

  @override
  AstNode visitTypeParameter(TypeParameter node) => node;

  @override
  AstNode visitTypeParameterList(TypeParameterList node) => node;

  @override
  AstNode visitVariableDeclaration(VariableDeclaration node) {
    var securityLabel = node.getProperty('sec-type')?.label?.toString();
    securityLabel ??= '?';
    //securityLabel ??= '?'; (if there the security type is null there is
    // an error in the security analysis that have to be solved, so we cannot
    // assume the unknown label)
    replaceNodeInAst(
        node.initializer,
        createFunctionInvocation('SecurityContext.declare', [
          "'$securityLabel'",
          node.initializer?.toString() ?? visitNullLiteral(null).toString()
        ]),
        parent: node);
    return node;
  }

  @override
  AstNode visitVariableDeclarationList(VariableDeclarationList node) => node;

  @override
  AstNode visitVariableDeclarationStatement(
          VariableDeclarationStatement node) =>
      node;

  @override
  AstNode visitWhileStatement(WhileStatement node) {
    replaceNodeInAst(
        node.condition,
        createFunctionInvocation('SecurityContext.evaluateConditionAndUpdatePc',
            [node.condition.toString(), _size.toString()]));
    final recoverStatement = createExpressionStatementWithFunctionInvocation(
        'SecurityContext.recoverPc', [_size.toString()]);
    _size++;
    return createBlock([node, recoverStatement]);
  }

  @override
  AstNode visitWithClause(WithClause node) => node;

  @override
  AstNode visitYieldStatement(YieldStatement node) => node;

  List<String> _getIdentifiers(FunctionBody body) {
    final declaration = body.parent;
    if (declaration is FunctionExpression) {
      return declaration.parameters.parameters
          .map((e) => e.identifier.name)
          .toList();
    }
    if (declaration is MethodDeclaration) {
      return declaration.parameters.parameters
          .map((e) => e.identifier.name)
          .toList();
    }
    return [];
  }

  List<String> _getSecurityLabels(FunctionBody body) {
    final declaration = body.parent;
    if (declaration is FunctionExpression) {
      return declaration.parameters.parameters
          .map((e) => "'${e.getProperty('sec-type') ?? '?'}'")
          .toList();
    }
    if (declaration is MethodDeclaration) {
      return declaration.parameters.parameters
          .map((e) => "'${e.getProperty('sec-type') ?? '?'}'")
          .toList();
    }
    return [];
  }

  AstNode _visitFunctionBody(FunctionBody node, Statement bodyStatement) {
    final identifiers = _getIdentifiers(node);
    final securityLabels = _getSecurityLabels(node);
    final checkStatement = createExpressionStatementWithFunctionInvocation(
        'SecurityContext.checkParametersType',
        ['[${identifiers.join(', ')}]', '[${securityLabels.join(', ')}]']);
    final statements = <Statement>[];
    for (final identifier in identifiers) {
      statements
          .add(parseStatement('$identifier ??= SecurityContext.nullLiteral()'));
    }
    statements.add(checkStatement);
    statements.add(bodyStatement);
    return createBlockFunctionBody(statements);
  }

  String _visitFunctionDeclaration(FunctionDeclaration node) =>
      "SecurityContext.declare('?', SecurityContext.functionLiteral(${node.functionExpression.toString()}))";

  ReturnStatement _visitReturnStatement(
      ReturnStatement node, String staticReturnLabel) {
    replaceNodeInAst(
        node.expression,
        createFunctionInvocation('SecurityContext.checkReturnType',
            [node.expression.toString(), "'$staticReturnLabel'"]));
    return node;
  }
}

bool _isStatic(MethodInvocation node) {
  final element = node.methodName.bestElement;
  if (element is MethodElement) {
    return element.isStatic;
  }
  return true;
}
