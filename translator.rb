
# Produces a string representation of the tree (no type check or evaluating)
# Every AST node implements its visitor and calls back to the corresponding one
# For compound nodes, recursively visit children first
# Utilizes helpers to maintain consistency

require_relative "ast_nodes"

class Translator

  # Primitives: convert to strings as is
  def visitIntegerPrimitive(node) = node.value.to_s
  def visitFloatPrimitive(node)    = node.value.to_s
  def visitBooleanPrimitive(node)  = node.value ? "true" : "false"
  def visitNullPrimitive(_node)    = "null"
  def visitStringPrimitive(node)   = '"' + node.value.gsub(/["\\]/) { |m| "\\#{m}" } + '"'

  # Variables and Statements
  def visitRvalue(node) = node.name
  def visitPrint(node)  = "print(#{node.expr.visit(self)})"
  def visitAssign(node) = "#{node.name} = #{node.expr.visit(self)}"
  
  # Put each statement on its own line
  def visitBlock(node)
    body = node.statements.map { |s| s.visit(self) }.join(";\n")
    "{\n#{body}\n}"
  end

  # Helpers for composition

  # Binary formatter that wraps with parantheses
  def bin(op, l, r) = "(#{l.visit(self)} #{op} #{r.visit(self)})"

  def unary(op, e)  = "(#{op}#{e.visit(self)})"
  def call(fn, e)   = "#{fn}(#{e.visit(self)})"

  # Arithmetic with paratheses for clarity
  def visitAdd(n)      = bin("+",  n.left, n.right)
  def visitSubtract(n) = bin("-",  n.left, n.right)
  def visitMultiply(n) = bin("*",  n.left, n.right)
  def visitDivide(n)   = bin("/",  n.left, n.right)
  def visitModulo(n)   = bin("%",  n.left, n.right)
  def visitExponent(n) = bin("**", n.left, n.right)
  def visitNegate(n)   = unary("-", n.expr)

  # Logical
  def visitAnd(n) = bin("&&", n.left, n.right)
  def visitOr(n)  = bin("||",  n.left, n.right)
  def visitNot(n) = unary("!", n.expr)

  # Bitwise
  def visitBitAnd(n)     = bin("&",  n.left, n.right)
  def visitBitOr(n)      = bin("|",  n.left, n.right)
  def visitBitXor(n)     = bin("^",  n.left, n.right)
  def visitBitNot(n)     = unary("~", n.expr)
  def visitLeftShift(n)  = bin("<<", n.left, n.right)
  def visitRightShift(n) = bin(">>", n.left, n.right)

  # Relational
  def visitEquals(n)      = bin("==", n.left, n.right)
  def visitNotEquals(n)   = bin("!=", n.left, n.right)
  def visitLessThan(n)    = bin("<",  n.left, n.right)
  def visitLessEq(n)      = bin("<=", n.left, n.right)
  def visitGreaterThan(n) = bin(">",  n.left, n.right)
  def visitGreaterEq(n)   = bin(">=", n.left, n.right)

  # Casts: uses the function calls for readibility (ex. int(7))
  def visitToInt(n)   = call("int",   n.expr)
  def visitToFloat(n) = call("float", n.expr)
end
