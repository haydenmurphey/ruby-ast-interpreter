
# textual user interface (TUI)

require 'curses'
require_relative 'lexer'
require_relative 'parser'
require_relative 'evaluator'
require_relative 'runtime'

# The main class that manages the TUI and game logic
class TUI

    # Represents a single test case with params, expected results, and actual results
    Case = Struct.new(:params, :expected, :actual)

    def initialize(mystery_file_path)
        @mystery_file_path = mystery_file_path
        @param_types = []
        @reference_impl = ""
        @cases = []
        @user_code = ""
        @output_message = "Press 'N' to add a new test case. Edit code below. Press 'R' to run."
        @param_names = ('a'..'z').to_a
    end

    # Entry to start the application
    def run
        load_mystery_function
        setup_curses
        main_loop
    end

    private

    # Reads the mystery function file to get parameter and the implementation
    def load_mystery_function
        unless File.exist?(@mystery_file_path)
            puts "Error: Mystery function file not found at '#{@mystery_file_path}'"
            exit 1
        end
        lines = File.readlines(@mystery_file_path, chomp: true)
        @param_types = lines.first.split
        @reference_impl = lines[1..].join("\n")
    end

    # Initialize the Curses library and sets up the windows
    def setup_curses
        Curses.init_screen
        Curses.start_color
        Curses.curs_set(1)
        Curses.noecho 
        Curses.cbreak
        Curses.stdscr.keypad(true)

        # Define window layout
        height, width = Curses.lines, Curses.cols
        table_h = 10
        output_h = 5
        code_h = height - table_h - output_h

        @win_table = Curses::Window.new(table_h, width, 0, 0)
        @win_code = Curses::Window.new(code_h, width, table_h, 0)
        @win_output = Curses::Window.new(output_h, width, table_h + code_h, 0)
    end

    # The main event loop that handles user input and updates screen
    def main_loop
        loop do
            draw_all
            handle_input
        end
    end

    # Redraws all windows with their current content
    def draw_all
        draw_table_window
        draw_code_window
        draw_output_window
        Curses.stdscr.refresh
    end

    # Draws the test cases table
    def draw_table_window
        @win_table.clear
        @win_table.box(?|, ?-)
        @win_table.setpos(1, 2)
        headers = @param_names.first(@param_types.length).join("\t") + "\t| expected\t| actual"
        @win_table.addstr("Test Cases")
        @win_table.setpos(2, 2)
        @win_table.addstr(headers)
        @win_table.setpos(3, 2)
        @win_table.addstr("-" * (headers.length * 1.5))

        @cases.each_with_index do |c, i|
            @win_table.setpos(4 + i, 2)
            params_str = c.params.join("\t")
            expected_str = c.expected.nil? ? "N/A" : c.expected
            actual_str = c.actual.nil? ? "N/A" : c.actual
            @win_table.addstr("#{params_str}\t| #{expected_str}\t| #{actual_str}")
        end
        @win_table.refresh
    end

    # Draws the code editing window.
    def draw_code_window
        @win_code.clear
        @win_code.box(?|, ?-)
        @win_code.setpos(1, 2)
        @win_code.addstr("Your Code ('R' to run, 'N' for new case, 'C' to clear, 'Q' to quit)")

        # Display user code line by line
        @user_code.lines.each_with_index do |line, i|
            break if i + 2 >= @win_code.maxy - 1 # Stop if we run out of vertical space
            @win_code.setpos(2 + i, 2)
            @win_code.addstr(line.chomp)
        end
        @win_code.refresh
    end
  
    # Draws the output/error message panel
    def draw_output_window
        @win_output.clear
        @win_output.box(?|, ?-)
        @win_output.setpos(1, 2)
        @win_output.addstr("Output / Status")
        @win_output.setpos(2, 2)
        @win_output.addstr(@output_message.to_s.split("\n").first) # Display first line of message
        @win_output.refresh
    end

    # Handles a single key press from the user
    def handle_input
        # Position cursor in the code window for editing
        line = @user_code.lines.count 
        col = (@user_code.lines.last&.chomp&.length || 0)
        @win_code.setpos(2 + line, 2 + col)

        ch = @win_code.getch

        case ch
        
        when 'Q'
        exit(0)
        when 'N'
        prompt_for_new_case
        when 'C'
        @user_code = ""
        @cases = []
        @output_message = "Press 'N' to add a new test case. Edit code below. Press 'R' to run."
        draw_all
        when 'R'
        run_user_code_on_all_cases
        # Simple text editing
        when 9, "\t" 
            @user_code += "  "

        when Curses::KEY_BACKSPACE, 127
            @user_code = @user_code.chop
        when Curses::KEY_ENTER, 10, 13
            @user_code += "\n"
        else
            if ch.is_a?(String) && ch.length == 1
                @user_code += ch
            end
        end
    end
  
    # Guides the user through setting up a new test case
    def prompt_for_new_case
        params = []
        @param_types.each_with_index do |type, i|
            param_name = @param_names[i]
            prompt = "Enter value for param '#{param_name}' (#{type}): "
            @output_message = prompt
            draw_output_window

            input_str = ""
            loop do
                @win_output.setpos(3, 2)
                @win_output.addstr(" " * 20) # Clear previous input
                @win_output.setpos(3, 2)
                @win_output.addstr(input_str)
                char = @win_output.getch
                if char == Curses::KEY_ENTER || char == 10 || char == 13
                    break
                elsif char == Curses::KEY_BACKSPACE || char == 127
                    input_str.chop!
                else
                    input_str << char
                end
            end
        params << input_str
    end

    # Create and add the new case
    new_case = Case.new(params)
    expected_val, _ = execute_implementation(@reference_impl, new_case.params)
    new_case.expected = expected_val
    @cases << new_case
    @output_message = "New case added. Press 'R' to run."
    end

    # Runs the user's current code against all existing test cases
    def run_user_code_on_all_cases
        if @user_code.strip.empty?
            @output_message = "Your code is empty. Nothing to run."
            return
    end

    all_passed = true
    error_found = false
    @cases.each do |c|
        actual_val, output = execute_implementation(@user_code, c.params)
        c.actual = actual_val
        if c.actual != c.expected
            all_passed = false
        end
         # Report first error and stop
        if actual_val.to_s.start_with?("ERROR:")
            @output_message = actual_val
            error_found = true
            break
        end
    end

    unless error_found
        @output_message = all_passed ? "Success! All test cases passed." : "Some test cases failed."
    end
  end

  # Executes a given implementation (user's or reference) with specific parameters
  def execute_implementation(impl_code, params)
    # Build the code with variable assignments for the parameters
    param_assignments = params.map.with_index do |val, i|
        # For strings, add quotes
        value_str = @param_types[i] == "string" ? "\"#{val}\"" : val
        "#{@param_names[i]} = #{value_str};"
    end.join("\n")
    
    full_code = param_assignments + "\n" + impl_code

    runtime = Runtime.new
    evaluator = Evaluator.new(runtime)
    final_value_node = nil

    begin
        tokens = Lexer.new(full_code).tokenize
        ast = Parser.new(tokens).parse
        final_value_node = ast.visit(evaluator)
    rescue Lexer::LexerError, Parser::ParseError, StandardError => e
        return "ERROR: #{e.message}", runtime.outputs
    end
    
    # Convert the final AST node to a string representation
    final_value_str = evaluator.primitive_to_string(final_value_node)
    [final_value_str, runtime.outputs]
  end

end

# --- Main Execution ---
if ARGV.empty?
  puts "Usage: ruby tui.rb <path_to_mystery_function_file>"
  puts "Example: ruby tui.rb mystery_functions/average.txt"
  exit 1
end

TUI.new(ARGV.first).run
