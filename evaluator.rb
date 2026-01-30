
# Evaluates an AST to Primitive types
# Recursively visits child nodes to obtain Primitive results
# Also type checks prior to computation then returns a new Primtive node

require_relative "ast_nodes"
require_relative "runtime"

class Evaluator

  # Custom error to handle 'return' statements breaking normal control flow
  class ReturnJump < StandardError
    attr_reader :value
    def initialize(value)
      super(nil) # No message needed
      @value = value
    end
  end

  def initialize(runtime)
    @rt = runtime # Runtime environment for storing variables and output
  end

  # Primitives: leaf nodes already evaluated
  def visitIntegerPrimitive(node) = node
  def visitFloatPrimitive(node)   = node
  def visitBooleanPrimitive(node) = node
  def visitStringPrimitive(node)  = node
  def visitNullPrimitive(node)    = node

  # Variables & Statements
  def visitRvalue(node) = @rt.get(node.name)

  def visitPrint(node)
    val = node.expr.visit(self)
    @rt.println(primitive_to_string(val))
    AST::NullPrimitive.new(node.token)
  end

  def visitAssign(node)
    val = node.expr.visit(self)
    @rt.set(node.name_token.text, val)
    val
  end

  def visitBlock(node)
    last = AST::NullPrimitive.new(node.token)
    node.statements.each { |s| last = s.visit(self) }
    last
  end
  
  # Control Flow
  def visitIf(node)
    condition_val = node.condition.visit(self)
    if is_truthy?(condition_val)
      node.then_branch.visit(self)
    elsif node.else_branch
      node.else_branch.visit(self)
    else
      AST::NullPrimitive.new(node.token)
    end
  end
  
  def visitWhile(node)
    while is_truthy?(node.condition.visit(self))
      node.body.visit(self)
    end
    AST::NullPrimitive.new(node.token) # While loops return null
  end

  def visitFor(node)
    start_val_node = node.start_expr.visit(self)
    end_val_node = node.end_expr.visit(self)

    raise "Runtime Error: For loop range must be integers" if !int?(start_val_node) || !int?(end_val_node)
    
    last_value = AST::NullPrimitive.new(node.token)
    var_name = node.var_token.text
    
    (start_val_node.value..end_val_node.value).each do |i|
      @rt.set(var_name, AST::IntegerPrimitive.new(i, node.var_token))
      last_value = node.body.visit(self)
    end
    
    last_value
  end

  # Functions
  def visitFunctionDef(node)
    @rt.define_fun(node.name_token.text, node)
    AST::NullPrimitive.new(node.token)
  end
  
  def visitReturn(node)
    value = node.expr ? node.expr.visit(self) : AST::NullPrimitive.new(node.token)
    raise ReturnJump.new(value)
  end
  
  def visitCall(node)
    callee_name = node.callee.name
    function_def = @rt.get_fun(callee_name)
    
    raise "Runtime Error: Expected #{function_def.params.length} arguments but got #{node.args.length}" if node.args.length != function_def.params.length

    call_runtime = Runtime.new(@rt)
    
    function_def.params.zip(node.args).each do |param_token, arg_node|
      arg_value = arg_node.visit(self)
      call_runtime.set(param_token.text, arg_value)
    end

    body_evaluator = Evaluator.new(call_runtime)
    begin
      function_def.body.visit(body_evaluator)
    rescue ReturnJump => ret
      return ret.value
    end
    
    AST::NullPrimitive.new(node.token) # Implicit return null
  end

  # Helpers
  def is_truthy?(p)
    return false if p.is_a?(AST::NullPrimitive) || (p.is_a?(AST::BooleanPrimitive) && !p.value)
    true
  end
  
  def numeric?(p) = p.is_a?(AST::IntegerPrimitive) || p.is_a?(AST::FloatPrimitive)
  def int?(p)     = p.is_a?(AST::IntegerPrimitive)
  def float?(p)   = p.is_a?(AST::FloatPrimitive)
  def bool?(p)    = p.is_a?(AST::BooleanPrimitive)
  def str?(p)     = p.is_a?(AST::StringPrimitive)

  def coerce_pair(l, r)
    raise "Runtime Error: numeric operands expected" if not numeric?(l) && numeric?(r)
    if float?(l) || float?(r) then [l.value.to_f, r.value.to_f, :float]
    else [l.value, r.value, :int]
    end
  end

  # Arithmetic
  def visitAdd(n)
    l = n.left.visit(self); r = n.right.visit(self)
    a, b, k = coerce_pair(l, r)
    k == :float ? AST::FloatPrimitive.new(a + b, n.token) : AST::IntegerPrimitive.new(a + b, n.token)
  end

  def visitSubtract(n)
    l = n.left.visit(self); r = n.right.visit(self)
    a, b, k=coerce_pair(l,r)
    k == :float ? AST::FloatPrimitive.new(a - b, n.token) : AST::IntegerPrimitive.new(a - b, n.token)
  end

  def visitMultiply(n)
    l = n.left.visit(self); r = n.right.visit(self)
    a, b, k = coerce_pair(l,r)
    k == :float ? AST::FloatPrimitive.new(a * b, n.token) : AST::IntegerPrimitive.new(a * b, n.token)
  end

  def visitDivide(n)
    l = n.left.visit(self); r = n.right.visit(self)
    a, b, k = coerce_pair(l,r)
    raise "Runtime Error: division by zero at [#{n.token.start_index}-#{n.token.end_index}]" if b==0.0
    k == :float ? AST::FloatPrimitive.new(a / b, n.token) : AST::IntegerPrimitive.new(a / b, n.token)
  end

  def visitModulo(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: modulo expects integers" if !int?(l) || !int?(r)
    raise "Runtime Error: modulo by zero at [#{n.token.start_index}-#{n.token.end_index}]" if r.value==0
    AST::IntegerPrimitive.new(l.value % r.value, n.token)
  end

  def visitExponent(n)
    l = n.left.visit(self); r = n.right.visit(self)
    a, b, k = coerce_pair(l,r)
    k == :float ? AST::FloatPrimitive.new(a ** b, n.token) : AST::IntegerPrimitive.new(a ** b, n.token)
  end

  def visitNegate(n)
    v = n.expr.visit(self)
    raise "Runtime Error: negation expects numeric" unless numeric?(v)
    v.is_a?(AST::FloatPrimitive) ? AST::FloatPrimitive.new(-v.value, n.token) : AST::IntegerPrimitive.new(-v.value, n.token)
  end

  # Logical
  def visitAnd(n)
    l = n.left.visit(self)
    !is_truthy?(l) ? l : n.right.visit(self)
  end

  def visitOr(n)
    l = n.left.visit(self)
    is_truthy?(l) ? l : n.right.visit(self)
  end

  def visitNot(n)
    v = n.expr.visit(self); AST::BooleanPrimitive.new(!is_truthy?(v), n.token)
  end

  # Bitwise
  def visitBitAnd(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: bitwise and expects integers" if !int?(l) || !int?(r)
    AST::IntegerPrimitive.new(l.value & r.value, n.token)
  end

  def visitBitOr(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: bitwise or expects integers" if !int?(l) || !int?(r)
    AST::IntegerPrimitive.new(l.value | r.value, n.token)
  end

  def visitBitXor(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: bitwise xor expects integers" if !int?(l) || !int?(r)
    AST::IntegerPrimitive.new(l.value ^ r.value, n.token)
  end

  def visitBitNot(n)
    v = n.expr.visit(self)
    raise "Runtime Error: bitwise not expects integer" if !int?(v)
    AST::IntegerPrimitive.new(~v.value, n.token)
  end

  def visitLeftShift(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: left shift expects integers" if !int?(l) || !int?(r)
    raise "Runtime Error: shift by negative" if r.value < 0
    AST::IntegerPrimitive.new(l.value << r.value, n.token)
  end

  def visitRightShift(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: right shift expects integers" if !int?(l) || !int?(r)
    raise "Runtime Error: shift by negative" if r.value < 0
    AST::IntegerPrimitive.new(l.value >> r.value, n.token)
  end

  # Relational
  def visitEquals(n)
    l = n.left.visit(self); r = n.right.visit(self)
    eq = if numeric?(l)&&numeric?(r) then l.value==r.value
         elsif l.class==r.class then l.value==r.value
         else false end
    AST::BooleanPrimitive.new(eq, n.token)
  end

  def visitNotEquals(n)
    l = n.left.visit(self); r = n.right.visit(self)
    neq = if numeric?(l)&&numeric?(r) then l.value!=r.value
          elsif l.class==r.class then l.value!=r.value
          else true end
    AST::BooleanPrimitive.new(neq, n.token)
  end

  def visitLessThan(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: comparison expects numerics" if !numeric?(l) || !numeric?(r)
    AST::BooleanPrimitive.new(l.value.to_f < r.value.to_f, n.token)
  end

  def visitLessEq(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: comparison expects numerics" if !numeric?(l) || !numeric?(r)
    AST::BooleanPrimitive.new(l.value.to_f <= r.value.to_f, n.token)
  end

  def visitGreaterThan(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: comparison expects numerics" if !numeric?(l) || !numeric?(r)
    AST::BooleanPrimitive.new(l.value.to_f > r.value.to_f, n.token)
  end

  def visitGreaterEq(n)
    l = n.left.visit(self); r = n.right.visit(self)
    raise "Runtime Error: comparison expects numerics" if !numeric?(l) || !numeric?(r)
    AST::BooleanPrimitive.new(l.value.to_f >= r.value.to_f, n.token)
  end

  # Casts
  def visitToInt(n)
    v = n.expr.visit(self)
    val = if v.is_a?(AST::FloatPrimitive) then v.value.to_i
          elsif v.is_a?(AST::IntegerPrimitive) then v.value
          else raise "Runtime Error: to-int expects float or int" end
    AST::IntegerPrimitive.new(val, n.token)
  end

  def visitToFloat(n)
    v = n.expr.visit(self)
    val = if v.is_a?(AST::IntegerPrimitive) then v.value.to_f
          elsif v.is_a?(AST::FloatPrimitive) then v.value
          else raise "Runtime Error: to-float expects int or float" end
    AST::FloatPrimitive.new(val, n.token)
  end

  def primitive_to_string(p)
    return "(error)" if p.nil?; case p
    when AST::IntegerPrimitive then p.value.to_s
    when AST::FloatPrimitive   then p.value.to_s
    when AST::BooleanPrimitive then p.value ? "true" : "false"
    when AST::StringPrimitive  then p.value
    when AST::NullPrimitive    then "null"
    else "Unknown primitive: #{p.class}" end
  end
end
