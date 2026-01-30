
# The Parser takes a list of tokens and assembles an Abstract Syntax Tree (AST)
# I utilize a recursive descent parser with one method for each non-terminal

require_relative 'token'
require_relative 'ast_nodes'

class Parser
  # Error class for syntax errors found during parsing
  class ParseError < StandardError; end

  include AST

  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end

  # The main public method parses a complete program
  # returns the root node of the AST (block of statements)
  def parse
    statements = []
    while not_at_end?
      statements << declaration
    end
    # root of the tree is an implicit block
    Block.new(statements, @tokens.first || Token.new(:EOF, "", 0, 0))
  end

  private

  # Grammar Rule Methods
  def declaration
    statement
  rescue ParseError => e
    # In case of an error -> synchronize to the next statement boundary
    synchronize
    # Report the error but return nil so the parser can continue
    puts e.message
    nil
  end

  def statement
    if has?(:PRINT) then print_statement
    elsif has?(:LEFT_BRACE) then block_statement
    elsif has?(:IF) then if_statement
    elsif has?(:WHILE) then while_statement
    elsif has?(:FOR) then for_statement
    elsif has?(:FUNCTION) then function_statement
    elsif has?(:RETURN) then return_statement
    else expression_statement
    end
  end

  # Parses a block of statements until one of the terminator tokens is found
  def parse_block_until(*terminators)
    statements = []
    while !check?(*terminators) && not_at_end?
      statements << declaration
    end
    statements.compact
  end

  def if_statement
    if_token = previous
    condition = expression # Parse the boolean condition that follows the 'if'
    then_branch = Block.new(parse_block_until(:ELSE, :END), peek)
    
    # Check for an optional 'else' branch
    else_branch = nil
    if has?(:ELSE)
      else_branch = Block.new(parse_block_until(:END), peek)
    end
    
    # Check it is property terminated with an 'end'
    consume(:END, "Expect 'end' after if statement.")
    If.new(condition, then_branch, else_branch, if_token)
  end

  def while_statement
    while_token = previous
    condition = expression
    body = Block.new(parse_block_until(:END), peek) # Parse the body until an 'end'
    consume(:END, "Expect 'end' after while loop.")
    While.new(condition, body, while_token)
  end

  def for_statement
    for_token = previous

    # Parse the loop variable identifier
    var_token = consume(:IDENTIFIER, "Expect loop variable name.")
    consume(:IN, "Expect 'in' after loop variable.")

    # Parse the range
    consume(:LEFT_BRACKET, "Expect '[' for range.")
    start_expr = expression
    consume(:COMMA, "Expect ',' separating range values.")
    end_expr = expression
    consume(:RIGHT_BRACKET, "Expect ']' to close range.")
    
    # Parse the body of the loop
    body = Block.new(parse_block_until(:END), peek)
    consume(:END, "Expect 'end' after for loop.")
    For.new(var_token, start_expr, end_expr, body, for_token)
  end

  def function_statement
    fun_token = previous # 'fun' keyword

    # Function's name
    name_token = consume(:IDENTIFIER, "Expect function name.")
    consume(:LEFT_PAREN, "Expect '(' after function name.")
    
    # Check for parameters then parse
    params = []
    unless check?(:RIGHT_PAREN)
      loop do
        # If no comma then the paramter list is done
        params << consume(:IDENTIFIER, "Expect parameter name.")
        break unless has?(:COMMA)
      end
    end
    consume(:RIGHT_PAREN, "Expect ')' after parameters.")
    
    body = Block.new(parse_block_until(:END), peek)
    consume(:END, "Expect 'end' after function body.")
    FunctionDef.new(name_token, params, body, fun_token)
  end
  
  def return_statement
    return_token = previous # 'return' keyword

    # Return value is optional if the next token is a semicolon
    expr = check?(:SEMICOLON) ? nil : expression
    consume(:SEMICOLON, "Expect ';' after return value.")
    Return.new(expr, return_token)
  end

  # Parses a print statement: 'print(expression);'
  def print_statement
    print_token = previous
    consume(:LEFT_PAREN, "Expect '(' after 'print'.")
    expr = expression
    consume(:RIGHT_PAREN, "Expect ')' after expression in print statement.")
    consume(:SEMICOLON, "Expect ';' after print statement.")
    Print.new(expr, print_token)
  end

  # Parses a block statement: '{statement1; statement2;}'
  def block_statement
    block_token = previous
    statements = []
    while !check?(:RIGHT_BRACE) && not_at_end?
      statements << declaration
    end
    consume(:RIGHT_BRACE, "Expect '}' after block.")
    Block.new(statements.compact, block_token)
  end

  # Parses an expression followed by a semicolon
  def expression_statement
    expr = expression
    consume(:SEMICOLON, "Expect ';' after expression.")
    expr
  end

  def expression
    assignment
  end

  # Level N: Assignment
  def assignment
    expr = logical_or
    if has?(:EQUAL)
      equals_token = previous
      value = assignment 
      if expr.is_a?(Rvalue)
        name_token = expr.token
        return Assign.new(name_token, value, equals_token)
      end
      raise error(equals_token, "Invalid assignment target.")
    end
    expr
  end

  # Levels 0-7: Left-associative binary operators
  def logical_or;    parse_left_associative_binary(:logical_and, :PIPE_PIPE); end
  def logical_and;   parse_left_associative_binary(:bitwise_op, :AMPERSAND_AMPERSAND); end
  def bitwise_op;    parse_left_associative_binary(:equality, :AMPERSAND, :PIPE, :CARET); end
  def equality;      parse_left_associative_binary(:comparison, :BANG_EQUAL, :EQUAL_EQUAL); end
  def comparison;    parse_left_associative_binary(:shift, :GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL); end
  def shift;         parse_left_associative_binary(:term, :LESS_LESS, :GREATER_GREATER); end
  def term;          parse_left_associative_binary(:factor, :MINUS, :PLUS); end
  def factor;        parse_left_associative_binary(:exponent, :SLASH, :STAR, :PERCENT); end
  
  # Level 8: Exponentiation (right-associative)
  def exponent
    expr = unary
    if has?(:STAR_STAR)
      op_token = previous
      right = exponent
      return Exponent.new(expr, right, op_token)
    end
    expr
  end

  # Level 9: Unary
  def unary
    if has?(:BANG, :MINUS, :TILDE)
      op_token = previous
      right = call
      klass = { BANG: Not, MINUS: Negate, TILDE: BitNot }[op_token.type]
      return klass.new(right, op_token)
    end
    call
  end

  # Level 10: Function Calls
  def call
    expr = primary
    loop do
      if has?(:LEFT_PAREN)
        expr = finish_call(expr)
      else
        break
      end
    end
    expr
  end

  def finish_call(callee)
    args = []
    unless check?(:RIGHT_PAREN)
      loop do
        args << expression
        break unless has?(:COMMA)
      end
    end
    paren = consume(:RIGHT_PAREN, "Expect ')' after arguments.")
    Call.new(callee, args, paren)
  end

  # Level 11: Primary
  def primary
    if has?(:FALSE) then return BooleanPrimitive.new(false, previous); end
    if has?(:TRUE) then return BooleanPrimitive.new(true, previous); end
    if has?(:NULL) then return NullPrimitive.new(previous); end
    if has?(:INTEGER_LITERAL) then return IntegerPrimitive.new(previous.text.to_i, previous); end
    if has?(:FLOAT_LITERAL) then return FloatPrimitive.new(previous.text.to_f, previous); end
    if has?(:STRING_LITERAL) then return StringPrimitive.new(previous.text, previous); end
    if has?(:IDENTIFIER) then return Rvalue.new(previous.text, previous); end
    if has?(:INT, :FLOAT) then return cast_expression; end

    if has?(:LEFT_PAREN)
      expr = expression
      consume(:RIGHT_PAREN, "Expect ')' after expression.")
      return expr
    end

    raise error(peek, "Expect expression.")
  end

  def cast_expression
    cast_token = previous
    consume(:LEFT_PAREN, "Expect '(' after type cast keyword.")
    expr = expression
    consume(:RIGHT_PAREN, "Expect ')' after cast expression.")
    klass = { INT: ToInt, FLOAT: ToFloat }[cast_token.type]
    klass.new(expr, cast_token)
  end

  def parse_left_associative_binary(higher_precedence_method, *token_types)
    expr = send(higher_precedence_method)
    while has?(*token_types)
      op_token = previous
      right = send(higher_precedence_method)
      klass = {
        PIPE_PIPE: Or, AMPERSAND_AMPERSAND: And, AMPERSAND: BitAnd,
        PIPE: BitOr, CARET: BitXor, BANG_EQUAL: NotEquals,
        EQUAL_EQUAL: Equals, GREATER: GreaterThan, GREATER_EQUAL: GreaterEq,
        LESS: LessThan, LESS_EQUAL: LessEq, LESS_LESS: LeftShift,
        GREATER_GREATER: RightShift, MINUS: Subtract, PLUS: Add,
        SLASH: Divide, STAR: Multiply, PERCENT: Modulo
      }[op_token.type]
      expr = klass.new(expr, right, op_token)
    end
    expr
  end

  def has?(*types)
    return false if at_end?
    if types.include?(peek.type)
      advance
      return true
    end
    false
  end

  def check?(*types)
    return false if at_end?
    types.include?(peek.type)
  end

  def advance
    @current += 1 if not_at_end?
    previous
  end

  def consume(type, message)
    return advance if check?(type)
    raise error(peek, message)
  end

  def at_end? = peek.type == :EOF
  def not_at_end? = !at_end?
  def peek = @tokens[@current]
  def previous = @tokens[@current - 1]

  def error(token, message)
    ParseError.new("Parse Error at token '#{token.text}' [#{token.start_index}-#{token.end_index}]: #{message}")
  end

  def synchronize
    advance
    while not_at_end?
      return if previous.type == :SEMICOLON
      case peek.type
      when :PRINT, :LEFT_BRACE, :IF, :WHILE, :FOR, :FUNCTION
        return
      end
      advance
    end
  end
end
