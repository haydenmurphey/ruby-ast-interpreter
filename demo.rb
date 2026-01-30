
# Environment for testing the overall projects functionality

require_relative 'token'
require_relative 'lexer'
require_relative 'parser'
require_relative 'runtime'
require_relative 'evaluator'

# Helper to run a piece of code through the full Lexer -> Parser -> Evaluator pipeline
def run_program(source, runtime)
  puts "--- Code ---"
  puts source.strip
  puts

  begin
    # Beging lexing with source code
    lexer = Lexer.new(source)
    tokens = lexer.tokenize

    # Parse the tokens to an AST
    parser = Parser.new(tokens)
    ast = parser.parse

    # Evaluate the AST
    evaluator = Evaluator.new(runtime)
    last_value = ast.visit(evaluator)

    # Display results
    puts "--- Printed Output ---"
    if runtime.outputs.empty?
      puts "(None)"
    else
      runtime.outputs.each { |line| puts line }
    end
    # The runtime object is shared, so clear its outputs for the next run
    runtime.instance_variable_get(:@outputs_internal).clear

  # Catch any errors that occur during the process
  rescue Lexer::LexerError, Parser::ParseError, RuntimeError => e
    puts "--- ERROR ---"
    puts e.message
  end
  puts "========================================="
  puts
end

# Helper to demonstrate how the parser handles incorrect code with the lexer / parser
def run_with_error_check(source)
  puts "--- Malformed Code ---"
  puts source.strip
  puts
  puts "--- Resulting Error ---"
  begin
    lexer = Lexer.new(source)
    tokens = lexer.tokenize
    parser = Parser.new(tokens)
    # The parser itself will print errors as it finds them
    parser.parse
  rescue Lexer::LexerError => e
    # This catches fatal lexer errors that stop parsing
    puts e.message
  end
  puts "========================================="
  puts
end

# Main tests

runtime = Runtime.new

puts
puts "VALID PROGRAMS:"
puts

puts "ARITHMETIC & LOGIC (FROM PREVIOUS MILESTONES):"
puts
run_program("print(10 * 6 - 10 % 4);", runtime)
run_program("x = 5; print(x + x * x);", runtime)
run_program("print((5 > 3) && !(2 > 8));", runtime)

puts "CONDITIONAL TESTS:"
puts
run_program("if 5 > 3 print(1); end", runtime)
run_program("x = 10; y = 20; if x > y print(0); else print(1); end", runtime)
run_program("if 0 print(0); else print(1); end", runtime) # 0 is truthy

puts "WHILE LOOP TESTS:"
puts
run_program(<<~CODE, runtime)
  i = 1;
  sum = 0;
  while i <= 10
    sum = sum + i;
    i = i + 1;
  end
  print(sum);
CODE

puts "FOR LOOP TESTS:"
puts
run_program(<<~CODE, runtime)
  sum = 0;
  for i in [1, 10]
    sum = sum + i;
  end
  print(sum);
CODE

puts "FUNCTION TESTS:"
puts
run_program(<<~CODE, runtime)
  function double(x)
    return x + x;
  end
  print(double(4 + 1));
CODE

run_program(<<~CODE, runtime)
  function fib(n)
    if n <= 1
        return n;
    end
    return fib(n - 2) + fib(n - 1);
  end
  print(fib(10));
CODE


puts "INVALID PROGRAMS"
puts

run_with_error_check("if 5 > 3 print(1);") # Missing 'end'
run_with_error_check("function missing_end(x) return x;")
