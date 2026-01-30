
# Token Abstraction 
# Represents a single token from the source code
# Each token has a type and the original text it was parsed from,
# and its starting and ending indices in the source string

class Token
  attr_reader :type, :text, :start_index, :end_index

  def initialize(type, text, start_index, end_index)
    @type = type
    @text = text
    @start_index = start_index
    @end_index = end_index
  end

  # Helper for debugging
  def to_s
    "Token(:#{@type}, \"#{@text}\", #{@start_index}..#{@end_index})"
  end
end
