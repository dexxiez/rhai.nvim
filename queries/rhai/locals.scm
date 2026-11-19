; Scopes, definitions and references.
[
  (Rhai)
  (ExprBlock)
  (ExprFn)
  (ExprClosure)
  (ExprFor)
] @local.scope

(ExprFn
  fn_name: (FnDeclName
    (ident) @local.definition.function))

(ExprDeclareVar
  name: (ident) @local.definition.var)

(Param
  (ident) @local.definition.parameter)

(PatIdent
  (ident) @local.definition.var)

(PatTuple
  (ident) @local.definition.var)

(ExprImport
  (ident) @local.definition.import)

(Path
  (ident) @local.reference)
