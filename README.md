<h2>Black Box: A Full-Stack Language Interpreter & TUI </h2>

<p>Box is a custom-built, dynamically typed programming language engine implemented in Ruby. This project demonstrates the complete lifecycle of a language tool, from lexical analysis and parsing to a decoupled execution runtime and an interactive developer interface.</p>

<h2>🚀 Key Features</h2>

- Custom Language Specification: Supports arithmetic, bitwise logic, relational operations, and complex control flow (conditionals, while-loops, for-each, and function definitions).

- Recursive-Descent Parser: Translates a custom BNF grammar into an Abstract Syntax Tree (AST), handling operator precedence and associativity.

- Visitor Design Pattern: Utilizes the Visitor pattern to decouple the AST structure from its operations, including a Translater for code serialization and an Evaluator for runtime execution.

- Scoped Runtime Environment: Manages variable bindings and function scopes with support for recursion and return-path exception handling.

- Interactive TUI: A terminal-based interface built with the Curses library, allowing developers to test mystery functions, monitor outputs, and debug code in real-time.

<h2>🛠️ Technical Architecture</h2>

<h3> The Model (AST & Visitor)</h3>
<p>The core of the engine is built on a node hierarchy representing language primitives and operations. By implementing the Visitor Pattern, the project maintains high "craftsmanship" and extensibility, allowing new language behaviors to be added without modifying the underlying node classes. </p>

<h3>The Interpreter (Lexer & Parser)</h3>
<p>The lexer chunks raw source code into tokens, which are then consumed by a recursive-descent parser. The parser enforces grammar rules and builds a robust tree representation of the logic, complete with source-code indexing for precise error reporting.</p>

<h3>Control Flow & Functions
Evaluation supports complex execution states, including:</h3>

- Short-circuiting logical operators.

- Dynamic type checking during evaluation.

- Exception-based Return Logic to handle function exits across nested scopes.

<h2>💻 Installation & Usage</h2>
Clone the repository:

```Bash
Bash
git clone https://github.com/haydenmurphey/ruby-ast-interpreter.git
```

Install dependencies:

```Bash
gem install curses
```

Run the Interface:

```Bash
ruby main.rb mystery_function.txt
```