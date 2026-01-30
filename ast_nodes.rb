
# AST Nodes
# Each node now stores a `token` that represents its position in the
# original source code. This is crucial for error reporting during evaluation.

module AST

  # Base class for all AST nodes to hold location info
  class Node
    attr_reader :token
    def initialize(token)
      @token = token
    end
  end

  # Primitives
  class IntegerPrimitive < Node
    attr_reader :value
    def initialize(value, token)
      super(token)
      @value = value
    end
    def visit(visitor) = visitor.visitIntegerPrimitive(self)
  end

  class FloatPrimitive < Node
    attr_reader :value
    def initialize(value, token)
      super(token)
      @value = value
    end
    def visit(visitor) = visitor.visitFloatPrimitive(self)
  end

  class BooleanPrimitive < Node
    attr_reader :value
    def initialize(value, token)
      super(token)
      @value = value
    end
    def visit(visitor) = visitor.visitBooleanPrimitive(self)
  end

  class StringPrimitive < Node
    attr_reader :value
    def initialize(value, token)
      super(token)
      @value = value
    end
    def visit(visitor) = visitor.visitStringPrimitive(self)
  end

  class NullPrimitive < Node
    def value = nil
    def visit(visitor) = visitor.visitNullPrimitive(self)
  end

  # Variables
  class Rvalue < Node
    attr_reader :name
    def initialize(name, token)
      super(token)
      raise "Must be String" if not name.is_a?(String)
      @name = name
    end
    def visit(visitor) = visitor.visitRvalue(self)
  end

  # Operator Superclasses
  class UnaryOperator < Node
    attr_reader :expr
    def initialize(expr, token)
      super(token)
      @expr = expr
    end
  end

  class BinaryOperator < Node
    attr_reader :left, :right
    def initialize(left, right, token)
      super(token)
      @left = left
      @right = right
    end
  end

  # Statements
  class Print < UnaryOperator
    def visit(visitor) = visitor.visitPrint(self)
  end

  # Variable assignment
  class Assign < Node
    attr_reader :name_token, :expr
    def initialize(name_token, expr, token)
      super(token) # The '=' token
      @name_token = name_token
      @expr = expr
    end
    def visit(visitor) = visitor.visitAssign(self)
  end

  class Block < Node
    attr_reader :statements
    def initialize(statements, token)
      super(token) # The '{' or starting keyword token
      @statements = statements
    end
    def visit(visitor) = visitor.visitBlock(self)
  end

  # Control Flow
  class If < Node
    attr_reader :condition, :then_branch, :else_branch
    def initialize(condition, then_branch, else_branch, token)
      super(token)
      @condition = condition
      @then_branch = then_branch
      @else_branch = else_branch
    end
    def visit(visitor) = visitor.visitIf(self)
  end

  class While < Node
    attr_reader :condition, :body
    def initialize(condition, body, token)
      super(token)
      @condition = condition
      @body = body
    end
    def visit(visitor) = visitor.visitWhile(self)
  end

  class For < Node
    attr_reader :var_token, :start_expr, :end_expr, :body
    def initialize(var_token, start_expr, end_expr, body, token)
      super(token)
      @var_token = var_token
      @start_expr = start_expr
      @end_expr = end_expr
      @body = body
    end
    def visit(visitor) = visitor.visitFor(self)
  end

  # Functions
  class FunctionDef < Node
    attr_reader :name_token, :params, :body
    def initialize(name_token, params, body, token)
      super(token)
      @name_token = name_token
      @params = params
      @body = body
    end
    def visit(visitor) = visitor.visitFunctionDef(self)
  end

  class Return < Node
    attr_reader :expr
    def initialize(expr, token)
      super(token)
      @expr = expr
    end
    def visit(visitor) = visitor.visitReturn(self)
  end

  class Call < Node
    attr_reader :callee, :args
    def initialize(callee, args, token) # token is the closing ')'
      super(token)
      @callee = callee
      @args = args
    end
    def visit(visitor) = visitor.visitCall(self)
  end

  # Arithmetic
  class Add < BinaryOperator; def visit(v)=v.visitAdd(self); end
  class Subtract < BinaryOperator; def visit(v)=v.visitSubtract(self); end
  class Multiply < BinaryOperator; def visit(v)=v.visitMultiply(self); end
  class Divide < BinaryOperator; def visit(v)=v.visitDivide(self); end
  class Modulo < BinaryOperator; def visit(v)=v.visitModulo(self); end
  class Exponent < BinaryOperator; def visit(v)=v.visitExponent(self); end
  class Negate < UnaryOperator; def visit(visitor) = visitor.visitNegate(self); end

  # Logical Expressions
  class And < BinaryOperator; def visit(visitor) = visitor.visitAnd(self); end
  class Or < BinaryOperator; def visit(visitor) = visitor.visitOr(self); end
  class Not < UnaryOperator; def visit(visitor) = visitor.visitNot(self); end

  # Bitwise
  class BitAnd < BinaryOperator; def visit(v)=v.visitBitAnd(self); end
  class BitOr < BinaryOperator; def visit(v)=v.visitBitOr(self); end
  class BitXor < BinaryOperator; def visit(v)=v.visitBitXor(self); end
  class BitNot < UnaryOperator; def visit(visitor) = visitor.visitBitNot(self); end
  class LeftShift < BinaryOperator; def visit(v)=v.visitLeftShift(self); end
  class RightShift < BinaryOperator; def visit(v)=v.visitRightShift(self); end

  # Relational
  class Equals < BinaryOperator; def visit(v)=v.visitEquals(self); end
  class NotEquals < BinaryOperator; def visit(v)=v.visitNotEquals(self); end
  class LessThan < BinaryOperator; def visit(v)=v.visitLessThan(self); end
  class LessEq < BinaryOperator; def visit(v)=v.visitLessEq(self); end
  class GreaterThan < BinaryOperator; def visit(v)=v.visitGreaterThan(self); end
  class GreaterEq < BinaryOperator; def visit(v)=v.visitGreaterEq(self); end

  # Casts
  class ToInt < UnaryOperator; def visit(visitor) = visitor.visitToInt(self); end
  class ToFloat < UnaryOperator; def visit(visitor) = visitor.visitToFloat(self); end
end
