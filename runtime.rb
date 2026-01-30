
# Runtime class for managing the state of the executing program
# This includes storing variable values and collecting output from 'print' statements

class Runtime
  attr_reader :enclosing

  def initialize(enclosing = nil)
    @vars = {}
    @enclosing = enclosing
    
    # Only the root environment (global scope) manage outputs and functions
    if enclosing.nil?
      @outputs_internal = []
      @functions = {}
    end
  end

  # Retrieves the value of a variable
  def get(name)
    return @vars[name] if @vars.key?(name)
    return @enclosing.get(name) if @enclosing
    raise "Undefined variable: #{name}"
  end

  # Sets the value of a variable in the current scope
  def set(name, primitive_node)
    @vars[name] = primitive_node
  end

  # Adds a line of text to global output list
  def println(text)
    root.outputs_internal << text
  end

  # Returns a copy of the collected output from global scope
  def outputs
    root.outputs_internal.dup
  end
  
  # Defines a function
  def define_fun(name, fun_node)
    root.functions[name] = fun_node
  end

  # Looks up a function
  def get_fun(name)
    fun = root.functions[name]
    raise "Undefined function: #{name}" if fun.nil?
    fun
  end

  # Helper to find the root runtime environment by traversing up
  def root
    @enclosing ? @enclosing.root : self
  end

  protected
  
  # Make these accessible to child scopes that get the `root` object.
  attr_accessor :outputs_internal, :functions

end
