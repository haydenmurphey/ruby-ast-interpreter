
# Lexer class for breaking a string into a stream of tokens

require_relative 'token'

class Lexer
  # Error class for reporting errors found during lexing
  class LexerError < StandardError; end

  # A map of  keywords to their token types
  KEYWORDS = {
    "print"    => :PRINT,
    "true"     => :TRUE,
    "false"    => :FALSE,
    "null"     => :NULL,
    "int"      => :INT,
    "float"    => :FLOAT,
    "if"       => :IF,
    "else"     => :ELSE,
    "end"      => :END,
    "while"    => :WHILE,
    "for"      => :FOR,
    "in"       => :IN,
    "function" => :FUNCTION,
    "return"   => :RETURN
  }.freeze

  def initialize(source)
    @source = source
    @tokens = []
    @start = 0
    @current = 0
  end

  # The main public method to tokenize the entire source string
  # Iterates through source code until it reaches the end
  def tokenize
    while not_at_end?
      # reset start position for each new token
      @start = @current
      scan_token
    end
    # Add an "End of File" token at the end of the source
    @tokens << Token.new(:EOF, "", @source.length, @source.length)
    @tokens
  end

  private

  # Scans and identifies the next token
  def scan_token
    char = advance
    case char
    # Single-character tokens
    when '('; emit_token(:LEFT_PAREN)
    when ')'; emit_token(:RIGHT_PAREN)
    when '{'; emit_token(:LEFT_BRACE)
    when '}'; emit_token(:RIGHT_BRACE)
    when '['; emit_token(:LEFT_BRACKET)
    when ']'; emit_token(:RIGHT_BRACKET)
    when ';'; emit_token(:SEMICOLON)
    when ','; emit_token(:COMMA)
    when '.'; emit_token(:DOT)
    when '-'; emit_token(:MINUS)
    when '+'; emit_token(:PLUS)
    when '%'; emit_token(:PERCENT)
    when '^'; emit_token(:CARET)
    when '~'; emit_token(:TILDE)

    # One or two character tokens
    when '*'; has?('*') ? emit_token(:STAR_STAR) : emit_token(:STAR)
    when '!'; has?('=') ? emit_token(:BANG_EQUAL)    : emit_token(:BANG)
    when '='; has?('=') ? emit_token(:EQUAL_EQUAL)   : emit_token(:EQUAL)
    when '<'; has?('=') ? emit_token(:LESS_EQUAL)    : has?('<') ? emit_token(:LESS_LESS) : emit_token(:LESS)
    when '>'; has?('=') ? emit_token(:GREATER_EQUAL) : has?('>') ? emit_token(:GREATER_GREATER) : emit_token(:GREATER)
    when '&'; has?('&') ? emit_token(:AMPERSAND_AMPERSAND) : emit_token(:AMPERSAND)
    when '|'; has?('|') ? emit_token(:PIPE_PIPE) : emit_token(:PIPE)

    # Comments start with '//' and go to the end of the line
    when '/'; has?('/') ? skip_comment : emit_token(:SLASH)

    # Ignore whitespace
    when ' ', "\r", "\t", "\n";

    # String literals are enclosed in double quotes
    when '"'; string_literal
    
    # Figure out what kind of character it is (digit, letter, etc.)
    else
      if is_digit?(char)
        number_literal
      elsif is_alpha?(char)
        identifier
      else
        error("Unrecognized character '#{char}'.")
      end
    end
  end

  # Helper for handling identifiers and keywords
  def identifier
    capture while is_alpha_numeric?(peek)
    text = @source[@start...@current]
    type = KEYWORDS[text] || :IDENTIFIER
    emit_token(type)
  end

  # Helper for handling number literals (ints // floats)
  def number_literal
    capture while is_digit?(peek)
    # If there is a decimal point followed by another digit, it is a float
    if peek == '.' && is_digit?(peek_next)
      advance # Consume the '.'
      capture while is_digit?(peek)
      emit_token(:FLOAT_LITERAL)
    else
      emit_token(:INTEGER_LITERAL)
    end
  end

  # Helper method for handling string literals
  def string_literal
    while peek != '"' && not_at_end?
      advance
    end
    error("Unterminated string.") if at_end?
    advance # Consume the closing "
    # Trim surrounding quotes
    text = @source[(@start + 1)...(@current - 1)]
    emit_token(:STRING_LITERAL, text)
  end

  def skip_comment
    # '//' comment goes until the end of the line
    advance while peek != "\n" && not_at_end?
  end

  # Character Checkers 
  def is_digit?(char) = char >= '0' && char <= '9'
  def is_alpha?(char) = (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
  def is_alpha_numeric?(char) = is_alpha?(char) || is_digit?(char)

  # Lexer Primitives
  def not_at_end? = @current < @source.length
  def at_end? = !not_at_end?
  def advance = (@current += 1; @source[@current - 1])
  def capture = advance
  
  # Checks if the current character matches 'expected' then consumes it if so
  def has?(expected)
    return false if at_end? || @source[@current] != expected
    @current += 1
    true
  end
  
  # Looks at the current or next character without consuming it
  def peek = at_end? ? "\0" : @source[@current]
  def peek_next = (@current + 1 >= @source.length) ? "\0" : @source[@current + 1]

  # Creates a new token and adds it to the list
  def emit_token(type, literal_value = nil)
    text = literal_value.nil? ? @source[@start...@current] : literal_value
    @tokens << Token.new(type, text, @start, @current - 1)
  end

  # Raises a formatted lexer error
  def error(message)
    raise LexerError.new("Lexer Error at index #{@start}: #{message}")
  end
end
