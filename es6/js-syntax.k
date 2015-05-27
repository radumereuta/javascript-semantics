module JS-SYNTAX-COMMON
syntax Program

endmodule

module JS-SYNTAX
imports JS-SYNTAX-COMMON

//////////////////////////////////////////////////////////////////////
// A.1 Lexical Grammar
//////////////////////////////////////////////////////////////////////
// 11.8.4
syntax RegularExpressionLiteral // TODO

//////////////////////////////////////////////////////////////////////
// A.2 Expressions
//////////////////////////////////////////////////////////////////////

// IdentifierReference, BindingIdentifier, LabelIdentifier
// TODO: the standard doesn't describe ID_Start and ID_Continue, found this though: https://github.com/mathiasbynens/unicode-4.1.0/tree/master/properties
syntax Identifier ::= r"[\\_\\$A-Za-z][\\_\\$A-Za-z0-9]*"   [token, reject2("null|true|false|break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|new|return|super|switch|this|throw|try|typeof|var|void|while|with|yield|enum|await")]

syntax PrimaryExpression ::= "this"
                           | Identifier                     /* IdentifierReference */
                           | Literal
                           | "[" Elements "]"               /* ArrayLiteral */
                           | "{" PropertyDefinitions "}"    /* ObjectLiteral */                 [klabel('{_}::PropertyAssignments->PrimaryExpression)]
                           | Function                       /* FunctionExpression */
                           | Class                          /* ClassExpression */
                           | Generator                      /* GeneratorExpression */
                           | RegularExpressionLiteral
                           | TemplateLiteral
                           | "(" Expression ")"             /* ParenthesizedExpression */  /* CoverParenthesizedExpressionAndArrowParameterList */  [klabel('(_)::ExpressionS->PrimaryExpression)]

syntax Literal ::= NullLiteral
                 | Bool           // BooleanLiteral
                 | Int | Float    // NumericLiteral
                 | StringLiteral  // StringLiteral

syntax NullLiteral ::= "null"

syntax Bool  ::= "true"  [token]
               | "false" [token]
syntax Int   ::= r"0[bB][0-1]+"       [token] // BinaryIntegerLiteral
               | r"0[oO][0-7]+"       [token] // OctalIntegerLiteral
               | r"0[xX][0-9a-fA-F]+" [token] // OctalIntegerLiteral

syntax Float ::= r"([0]|[1-9][0-9]*)\\.([0-9]+)?([eE][\\+-]?[0-9]+)?" [token] // decimal literal
               | r"\\.([0-9]+) ([eE][\\+-]?[0-9]+)?"                  [token]
               | r"([0]|[1-9][0-9]*)([eE][\\+-]?[0-9]+)?"             [token]

// 11.8.4 String Literals
syntax StringLiteral ::= r"[\"](([^\"\n\r\\\\])|([\\\\](['\"\\\\bfnrtv]|[^'\"\\\\bfnrtv0-9xu\n\r]|[0]|[x][0-9a-fA-F]{2}|[u][0-9a-fA-F]{4}|[u][{][0-9a-fA-F]+[}])))*[\"]" [token]
                       | r"['](([^'\n\r\\\\])|([\\\\](['\"\\\\bfnrtv]|[^'\"\\\\bfnrtv0-9xu\n\r]|[0]|[x][0-9a-fA-F]{2}|[u][0-9a-fA-F]{4}|[u][{][0-9a-fA-F]+[}])))*[']"    [token]

// [\"]                               // double quotes
// [^\"\n\r\\\\]                      // source character, but none of " or \ or LineTerminator
// [\\\\]                             // \ EscapeSequence:
//    ['\"\\\\bfnrtv]                 // SingleEscapeCharacter: ' " \ b f n r t v
//    [^'\"\\\\bfnrtv0-9xu\n\r]       // NonEscapeCharacter: SourceCharacter but not one of EscapeCharacter or LineTerminator
//     0 [lookahead =/= DecimalDigit] // TODO: why the lookahead? Apparently will be clarified in ES7 https://bugs.ecmascript.org/show_bug.cgi?id=3477
//    [x][0-9a-fA-F]{2}               // HexEscapeSequence
//    [u][0-9a-fA-F]{4}               // UnicodeEscapeSequence
//    [u][{][0-9a-fA-F]+[}]




// ElementList, Arguments, ArgumentList
syntax Elements ::= List{Element, ","}
syntax Element ::= ""                /* Elision */  /* NOTE: not allowed in Arguments and ArgumentList */              [avoid, onlyLabel, klabel('epsilonElement)]
                 |       Expression  /* AssignmentExpression */
                 | "..." Expression  /* SpreadElement */ /* AssignmentExpression */

// TODO: merge with Element
syntax ExpressionOpt ::= Expression
                       | "" [avoid, onlyLabel, klabel('epsilonExpression)]

// PropertyDefinitionList
syntax PropertyDefinitions ::= List{PropertyDefinition, ","}                [klabel('_,_::PropertyAssignment*PropertyAssignments->PropertyAssignments)]
syntax PropertyDefinition ::= SingleNameBinding /* IdentifierReference, CoverInitializedName */
                            | PropertyName ":" Expression  /* AssignmentExpression */                 [klabel('_:_::PropertyName*Expression->PropertyAssignment)]
                            | MethodDefinition

syntax PropertyName ::= LiteralPropertyName
                      | ComputedPropertyName

syntax LiteralPropertyName ::= Identifier | NullLiteral | Bool  // TODO: IdentifierName
                             | StringLiteral                    // TODO: StringLiteral
                             | Int | Float                      // TODO: NumericLiteral

syntax ComputedPropertyName ::= "[" Expression "]" /* AssignmentExpression */

syntax TemplateLiteral // TODO

// MemberExpression, NewExpression, CallExpression
syntax LeftHandSideExpression ::= PrimaryExpression
                                | LeftHandSideExpression "[" Expression "]"            [klabel('_[_]::Expression*Expression->Expression)]
                                | LeftHandSideExpression "." Identifier /* TODO: IdentifierName */           [klabel('_._::Expression*Name->Expression)]
                                | LeftHandSideExpression "(" Elements ")" /* Arguments */
                                | LeftHandSideExpression TemplateLiteral
                                | "super" "[" Expression "]"   /* SuperProperty */
                                | "super" "." Identifier       /* SuperProperty */ /* TODO: IdentifierName */
                                | "super" "(" Elements ")"     /* SuperCall */ /* Arguments */
                                | "new" LeftHandSideExpression "(" Elements ")" /* Arguments */
                                | "new" LeftHandSideExpression
                                | "new" "." "target"  /* MetaProperty */ /* NewTarget */

// AssignmentExpression
syntax Expression ::= LeftHandSideExpression
                    // PostfixExpression
                    > Expression "++"
                    | Expression "--"
                    // UnaryExpression
                    > "delete" Expression
                    | "void" Expression
                    | "typeof" Expression
                    | "++" Expression                               [prefer]
                    | "--" Expression                               [prefer]
                    | "+" Expression
                    | "-" Expression
                    | "~" Expression
                    | "!" Expression
                    // MultiplicativeExpression
                    > left:
                      Expression "*" Expression                            [left]
                    | Expression "/" Expression                            [left]
                    | Expression "%" Expression                            [left]
                    // AdditiveExpression
                    > left:
                      Expression "+" Expression                            [left]
                    | Expression "-" Expression                            [left]
                    // ShiftExpression
                    > left:
                      Expression "<<" Expression                           [left]
                    | Expression ">>" Expression                           [left]
                    | Expression ">>>" Expression                          [left]
                    // RelationalExpression
                    > left:
                      Expression "<" Expression                            [left]
                    | Expression ">" Expression                            [left]
                    | Expression "<=" Expression                           [left]
                    | Expression ">=" Expression                           [left]
                    | Expression "instanceof" Expression                   [left,prefer]
                    | Expression "in" Expression                           [left, klabel('_in_::Expression*Expression->Expression)]
                    // EqualityExpression
                    > left:
                      Expression "==" Expression                           [left]
                    | Expression "!=" Expression                           [left]
                    | Expression "===" Expression                          [left]
                    | Expression "!==" Expression                          [left]
                    // BitwiseANDExpression
                    > left:
                      Expression "&" Expression                            [left]
                    // BitwiseXORExpression
                    > left:
                      Expression "^" Expression                            [left]
                    // BitwiseORExpression
                    > left:
                      Expression "|" Expression                            [left]
                    // LogicalANDExpression
                    > left:
                      Expression "&&" Expression                           [left]
                    // LogicalORExpression
                    > left:
                      Expression "||" Expression                           [left]
                    // ConditionalExpression
                    > Expression "?" Expression ":" Expression
                    // AssignmentExpression
                    > right:
                      LeftHandSideExpression "=" Expression                           [right]
                    | LeftHandSideExpression "*=" Expression                          [right]
                    | LeftHandSideExpression "/=" Expression                          [right]
                    | LeftHandSideExpression "%=" Expression                          [right]
                    | LeftHandSideExpression "+=" Expression                          [right]
                    | LeftHandSideExpression "-=" Expression                          [right]
                    | LeftHandSideExpression "<<=" Expression                         [right]
                    | LeftHandSideExpression ">>=" Expression                         [right]
                    | LeftHandSideExpression ">>>=" Expression                        [right]
                    | LeftHandSideExpression "&=" Expression                          [right]
                    | LeftHandSideExpression "^=" Expression                          [right]
                    | LeftHandSideExpression "|=" Expression                          [right]

// AssignmentExpression
syntax Expression ::= YieldExpression
                    | ArrowFunction

syntax Expression ::= Expression "," Expression  [left]

//////////////////////////////////////////////////////////////////////
// A.3 Statements
//////////////////////////////////////////////////////////////////////

// StatementList, FunctionBody, FunctionStatementList, GeneratorBody
syntax Statements ::= List{Statement, ""}

// StatementListItem
syntax Statement ::=
/* BlockStatement, Block */   "{" Statements "}" /* StatementList */
/* EmptyStatement */        | ";"
/* ExpressionStatement */   | Expression ";"
/* IfStatement */           | "if" "(" Expression ")" Statement "else" Statement
                            | "if" "(" Expression ")" Statement
/* IterationStatement, BreakableStatement */
                            | "do" Statement "while" "(" Expression ")" ";"
                            | "while" "(" Expression ")" Statement
                            // for
                            | "for" "("      ExpressionOpt ";" ExpressionOpt ";" ExpressionOpt ")" Statement
                            | "for" "(" LexicalDeclaration     ExpressionOpt ";" ExpressionOpt ")" Statement
                            // for-in
                            | "for" "(" LeftHandSideExpression "in" Expression ")" Statement
                            | "for" "("     LexicalDeclaration "in" Expression ")" Statement /* ForDeclaration, ForBinding */
                            // for-of
                            | "for" "(" LeftHandSideExpression "of" Expression ")" Statement                                  /* AssignmentExpression */
                            | "for" "("     LexicalDeclaration "of" Expression ")" Statement /* ForDeclaration, ForBinding */ /* AssignmentExpression */
/* ContinueStatement */     | "continue" ";"
                            | "continue" Identifier ";" /* LabelIdentifier */
/* BreakStatement */        | "break" ";"
                            | "break" Identifier ";" /* LabelIdentifier */
/* ReturnStatement */       | "return" ";"
                            | "return" Expression ";"
/* WithStatement */         | "with" "(" Expression ")" Statement
/* LabelledStatement */     | Identifier ":" Statement /* LabelIdentifier */ /* LabelledItem */     [klabel('_:_::Name*Statement->Statement)]
/* ThrowStatement */        | "throw" Expression ";"
/* TryStatement */          | "try" "{" Statements "}" "catch" "(" Binding ")" "{" Statements "}"                               /* CatchParameter */
                            | "try" "{" Statements "}"                         "{" Statements "}" "finally" "{" Statements "}"
                            | "try" "{" Statements "}" "catch" "(" Binding ")" "{" Statements "}" "finally" "{" Statements "}"  /* CatchParameter */
/* DebuggerStatement */     | "debugger" ";"
/* SwitchStatement, BreakableStatement */
                            | "switch" "(" Expression ")" "{" CaseClauses "}"                           /* CaseBlock */
                            | "switch" "(" Expression ")" "{" CaseClauses DefaultClause CaseClauses "}" /* CaseBlock */
syntax CaseClauses ::= List{CaseClause, ""}                         [klabel('__::CaseClause*CaseClauses->CaseClauses)]
syntax CaseClause ::= "case" Expression ":" Statements /* StatementList */
syntax DefaultClause ::= "default" ":" Statements /* StatementList */

// Declaration, StatementListItem
syntax Statement ::= Function   /* FunctionDeclaration */   /* HoistableDeclaration */ 
                   | Generator  /* GeneratorDeclaration */  /* HoistableDeclaration */ 
                   | Class      /* ClassDeclaration */
                   | LexicalDeclaration

// ForDeclaration
syntax LexicalDeclaration ::= "var"   Bindings ";" /* VariableStatement */
                            | "let"   Bindings ";" /* LetOrConst */
                            | "const" Bindings ";" /* LetOrConst */

// BindingList, VariableDeclarationList, FormalsList
syntax Bindings ::= List{Binding, ","}

// LexicalBinding, VariableDeclaration, BindingElement, ForBinding, CatchParameter, FormalParameter, PropertySetParameterList
syntax Binding ::= SingleNameBinding
                 | DestructiveBinding
// CoverInitializedName, SingleNameBinding
syntax SingleNameBinding  ::= Identifier     "=" Expression /* Initializer */ /* BindingIdentifier */ // NOTE: not allowed in ForBinding and CatchParameter
                            | Identifier                                      /* BindingIdentifier */
syntax DestructiveBinding ::= BindingPattern "=" Expression /* Initializer */                         // NOTE: not allowed in ForBinding and CatchParameter
                            | BindingPattern                                   // NOTE: not allowed in LexicalBinding and VariableDeclaration

syntax BindingPattern ::= "{" BindingProperties "}"   /* ObjectBindingPattern */ // TODO: a trailing comma option
                        | "[" BindingOptsWithRest "]" /* ArrayBindingPattern */

// BindingPropertyList
syntax BindingProperties ::= List{BindingProperty, ","}
syntax BindingProperty ::=                  SingleNameBinding
                         | PropertyName ":"           Binding /* BindingElement */

// NOTE: different with BindingsWithRest
syntax BindingOptsWithRest ::=                 "..." Identifier                          /* BindingRestElement */
                             | BindingOpts                      /* BindingElementList */
                             | BindingOpts "," "..." Identifier /* BindingElementList */ /* BindingRestElement */

// BindingElementList // NOTE: Bindings with Elision
syntax BindingOpts ::= List{BindingOpt, ","}
// BindingElisionElement // NOTE: Binding + Elision
syntax BindingOpt ::= Binding /* BindingElement */
                    | ""      /* Elision */ [avoid, onlyLabel, klabel('epsilonBinding)]

//////////////////////////////////////////////////////////////////////
// A.4 Functions and Classes
//////////////////////////////////////////////////////////////////////

// FunctionDeclaration, FunctionExpression
syntax Function ::= "function" Identifier "(" BindingsWithRest ")" "{" Statements "}" /* BindingIdentifier */ /* FormalParameters */ /* FunctionBody */
                  | "function"            "(" BindingsWithRest ")" "{" Statements "}"                         /* FormalParameters */ /* FunctionBody */

// StrictFormalParameters, FormalParameters, FormalParameterList // NOTE: different with BindingOptsWithRest
syntax BindingsWithRest ::=              "..." Identifier /* FunctionRestParameter */
                          | Bindings
                          | Bindings "," "..." Identifier /* FunctionRestParameter */

// ArrowParameters, ConciseBody, ArrowFormalParameters
syntax ArrowFunction ::=     Identifier           "=>"     Expression      /* BindingIdentifier */ /* AssignmentExpression */
                       |     Identifier           "=>" "{" Statements "}"  /* BindingIdentifier */ /* FunctionBody */
                       | "(" BindingsWithRest ")" "=>"     Expression      /* CoverParenthesizedExpressionAndArrowParameterList, FormalParameters */ /* AssignmentExpression */
                       | "(" BindingsWithRest ")" "=>" "{" Statements "}"  /* CoverParenthesizedExpressionAndArrowParameterList, FormalParameters */ /* FunctionBody */

syntax MethodDefinition ::=     PropertyName "(" BindingsWithRest ")" "{" Statements "}"                         /* FormalParameters */ /* FunctionBody */
                          | "*" PropertyName "(" BindingsWithRest ")" "{" Statements "}"  /* GeneratorMethod */  /* FormalParameters */ /* GeneratorBody */
                          // accessor
                          | "get" PropertyName "("         ")" "{" Statements "}"                                /* FunctionBody */
                          | "set" PropertyName "(" Binding ")" "{" Statements "}" /* PropertySetParameterList */ /* FunctionBody */

// GeneratorDeclaration, GeneratorExpression
syntax Generator ::= "function" "*" Identifier "(" BindingsWithRest ")" "{" Statements "}" /* BindingIdentifier */ /* FormalParameters */ /* GeneratorBody */
                   | "function" "*"            "(" BindingsWithRest ")" "{" Statements "}"                         /* FormalParameters */ /* GeneratorBody */

syntax YieldExpression ::= "yield"
                         | "yield"     Expression /* AssignmentExpression */
                         | "yield" "*" Expression /* AssignmentExpression */

// ClassDeclaration, ClassExpression, ClassTail
syntax Class ::= "class" Identifier "extends" LeftHandSideExpression "{" ClassElements "}" /* BindingIdentifier */ /* ClassHeritage */ /* ClassBody */
               | "class" Identifier                                  "{" ClassElements "}" /* BindingIdentifier */                     /* ClassBody */
               | "class"            "extends" LeftHandSideExpression "{" ClassElements "}"                         /* ClassHeritage */ /* ClassBody */ 
               | "class"                                             "{" ClassElements "}"                                             /* ClassBody */
// ClassBody, ClassElementList
syntax ClassElements ::= List{ClassElement, ""}
syntax ClassElement ::=          MethodDefinition
                      | "static" MethodDefinition

//////////////////////////////////////////////////////////////////////
// A.5 Scripts and Modules
//////////////////////////////////////////////////////////////////////

syntax Program ::= Script [prefer, klabel('script), bracket] // Ambiguity between the script list and module list, so adding prefer to keep this branch if possible.
                                                             // Added `klabel` so the node doesn't get removed before applying prefer, and added `bracket` so it does get removed after that.
                 | Module [klabel('module), bracket] 

// ScriptBody
syntax Script ::= Statements

// ModuleBody
syntax Module ::= ModuleItems

// ModuleItemList
syntax ModuleItems ::= List{ModuleItem, ""}

syntax ModuleItem ::= ImportDeclaration
                    | ExportDeclaration
                    | Statement

syntax ImportDeclaration ::= "import" Identifier                                    "from" ModuleSpecifier ";" /* ImportClause */ /* ImportedDefaultBinding, ImportedBinding, BindingIdentifier */                                      /* FromClause */
                           | "import"                "*" "as" Identifier            "from" ModuleSpecifier ";" /* ImportClause */                              /* NameSpaceImport */ /* ImportedBinding, BindingIdentifier */           /* FromClause */
                           | "import" Identifier "," "*" "as" Identifier            "from" ModuleSpecifier ";" /* ImportClause */ /* ImportedDefaultBinding */ /* NameSpaceImport */ /* ImportedBinding, BindingIdentifier */           /* FromClause */
                           | "import"                "{" ImportExportSpecifiers "}" "from" ModuleSpecifier ";" /* ImportClause */                              /* NamedImports */ /* ImportsList */ /* TODO: a trailing comma option */ /* FromClause */
                           | "import" Identifier "," "{" ImportExportSpecifiers "}" "from" ModuleSpecifier ";" /* ImportClause */ /* ImportedDefaultBinding */ /* NamedImports */ /* ImportsList */ /* TODO: a trailing comma option */ /* FromClause */
                           | "import"                                                      ModuleSpecifier ";"

// ImportsList, ExportsList
syntax ImportExportSpecifiers ::= List{ImportExportSpecifier, ","}
// ImportSpecifier, ExportSpecifier
syntax ImportExportSpecifier ::=                 Identifier                      /* ImportedBinding for ImportSpecifier */ /* IdentifierName for ExportSpecifier */
                               | Identifier "as" Identifier /* IdentifierName */ /* ImportedBinding for ImportSpecifier */ /* IdentifierName for ExportSpecifier */

syntax ModuleSpecifier ::= StringLiteral // TODO: StringLiteral

syntax ExportDeclaration ::= "export"              "*"               "from" ModuleSpecifier ";"                                                        /* FromClause */
                           | "export" "{" ImportExportSpecifiers "}" "from" ModuleSpecifier ";" /* ExportClause */ /* TODO: a trailing comma option */ /* FromClause */
                           | "export" "{" ImportExportSpecifiers "}"                        ";" /* ExportClause */ /* TODO: a trailing comma option */ 
                           //
                           | "export"           Function            /* FunctionDeclaration */   /* Declaration */ 
                           | "export"           Generator           /* GeneratorDeclaration */  /* Declaration */ 
                           | "export"           Class               /* ClassDeclaration */      /* Declaration */
                           | "export"           LexicalDeclaration  /* VariableStatement */     /* Declaration */
                           | "export" "default" Function            /* FunctionDeclaration */   /* HoistableDeclaration */ 
                           | "export" "default" Generator           /* GeneratorDeclaration */  /* HoistableDeclaration */ 
                           | "export" "default" Class               /* ClassDeclaration */
                           | "export" "default" Expression          /* AssignmentExpression */

endmodule

/*
  array, spread element, rest element, destructive binding

  In array expression (i.e., Elements), a spread element "... e" is supposed to be flattened.
    e.g., a = [1,2,3];
          b = [10,20,...a,30]; // [10,20,1,2,3,30]
          c = [10,  ,...a,30]; // [10,undefined,1,2,3,30]
  A list of arguments (i.e., Arguments) is also a kind of array expression, but do not allow elision.
    e.g., foo(1,2,3);
          foo(1, ,3); // invalid

  In binding, two kinds of binding declaration:
    - var, let, const declaration: only a list of bindings (i.e., Bindings)
    - formal parameters: a list of bindings with optional rest elements "... x" (i.e., BindingsWithRest)
  In both bindings,
    array pattern destructive binding is also a list of bindings with optional rest elements,
    but the list of bindings can have elision. (i.e., BindingOptsWithRest)
  e.g., let x, y, z; // only a list of bindings
        function foo(x, y, z, ...w) { e; } // a list of bindings with rest element
        let [x,y,z,...w] = e; // array pattern with rest element
        let [x, ,z,...w] = e; // array pattern with elision and rest element
  That is,
    - declaration (Bindings) and formal parameters (BindingsWithRest) are same except rest elements
    - formal parameters (BindingsWithRest) and array pattern (BindingOptsWithRest) are same except elision
 */
