; Neovim highlight queries for tree-sitter-rhai.
; Adapted from https://github.com/elkowar/tree-sitter-rhai (MIT).
; Later patterns take priority over earlier ones, so general rules come first.

; Identifiers
(ident) @variable

(Param
  (ident) @variable.parameter)

(PatIdent
  (ident) @variable)

(PatTuple
  (ident) @variable)

; Variables declared with an ALL_CAPS name are treated as constants
(ExprDeclareVar
  name: (ident) @constant
  (#lua-match? @constant "^[A-Z][A-Z0-9_]*$"))

; Modules: `import "x" as name;` and `name::item`
(ExprImport
  (ident) @module)

(Path
  (ident) @module
  .
  (ident))

; Property access
(ExprDotAccess
  (Expr)
  (Expr
    (ExprPath
      (Path
        (ident) @variable.member))))

; Functions
(ExprFn
  fn_name: (FnDeclName
    (ident) @function))

(ExprCall
  fn_name: (Expr
    (ExprPath
      (Path
        (ident) @function.call .))))

(ExprCall
  fn_name: (Expr
    (ExprDotAccess
      (Expr)
      (Expr
        (ExprPath
          (Path
            (ident) @function.method.call))))))

; Built-in variable `this`
((ident) @variable.builtin
  (#eq? @variable.builtin "this"))

; Literals
(lit_str) @string

(lit_char) @character

(lit_int) @number

(lit_float) @number.float

(lit_bool) @boolean

(LitUnit) @constant.builtin

; Object keys (after literals so quoted keys show as properties)
(ObjectField
  key: [
    (ident)
    (lit_str)
  ] @property)

(str_template_expr
  [
    "${"
    "}"
  ] @punctuation.special)

; Comments
[
  (comment_line)
  (comment_block)
] @comment @spell

[
  (comment_line_doc)
  (comment_block_doc)
] @comment.documentation @spell

((comment_line) @comment.documentation
  (#lua-match? @comment.documentation "^//!"))

; Keywords
[
  "let"
  "const"
] @keyword

"fn" @keyword.function

[
  "import"
  "export"
  "as"
] @keyword.import

"private" @keyword.modifier

[
  "if"
  "else"
  "switch"
] @keyword.conditional

[
  "for"
  "while"
  "loop"
  "do"
  "until"
  "break"
  (ExprContinue)
] @keyword.repeat

"in" @keyword.operator

"return" @keyword.return

[
  "try"
  "catch"
  "throw"
] @keyword.exception

; Operators
(binop) @operator

((binop) @keyword.operator
  (#eq? @keyword.operator "in"))

[
  "="
  "!"
  "+"
  "-"
  "=>"
  "?."
  "::"
] @operator

; Punctuation
[
  ";"
  ","
  "."
  ":"
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "#{"
  "?["
] @punctuation.bracket

(ClosureParamList
  "|" @punctuation.bracket)

(SwitchArm
  "_" @character.special)
