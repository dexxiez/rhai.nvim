; Indent queries (used by nvim-treesitter's indentexpr).
[
  (ExprBlock)
  (ExprObject)
  (ExprArray)
  (SwitchArmList)
  (ArgList)
  (ParamList)
] @indent.begin

[
  "}"
  "]"
  ")"
] @indent.branch @indent.end

[
  (comment_block)
  (comment_block_doc)
] @indent.auto

(lit_str) @indent.ignore
