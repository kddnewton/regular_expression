# Contributing

Thanks for your interest in contributing to `regular_expression`! Here are a couple of ways that you can contribute:

* A good place to start is looking at the existing [open issues](https://github.com/kddnewton/regular_expression/issues) on GitHub. Most of the time they will be labeled with an estimate of their size and scope.
* We could always use help with better documentation both in code, in this document, and in the README.
* If you've found a bug or other issue with the code, opening issues with reproduction steps is always appreciated!

Below is some background information to get you up and running on what is happening in this gem.

## Background

In order to understand your regular expression patterns and compare them against input strings, the source string goes through a couple of transformations.

### 1. Abstract syntax tree

First, it passes through `RegularExpression::Parser`, which is a class that is generated using the [racc](https://github.com/ruby/racc) gem. It is a parser that will take your input string and convert it into an abstract syntax tree. The root of that tree is a `RegularExpression::AST::Root`, and each of its children are also within the `RegularExpression::AST` module. The grammar that the AST follows is loosely described below:

```
root: CARET? expression

expression:
  | item+ PIPE expression
  | item+

item: group | match | ANCHOR

group: LPAREN expression RPAREN quantifier?

match: match_item quantifier?

match_item:
  | LBRACKET CARET? character_group_item+ RBRACKET
  | CHAR_CLASS
  | CHAR
  | PERIOD

character_group_item:
  | CHAR_CLASS
  | CHAR DASH CHAR
  | CHAR

quantifier:
  | LBRACE INTEGER COMMA INTEGER RBRACE
  | LBRACE INTEGER COMMA RBRACE
  | LBRACE INTEGER RBRACE
  | STAR
  | PLUS
  | QMARK
```

### 2. State machine

Second, we take the AST and transform it into a [nondeterministic finite automaton](https://en.wikipedia.org/wiki/Nondeterministic_finite_automaton) (which is an academic way of saying a state machine). Each transition between the states of the state machine consume either 0 or 1 characters from the input string. Everything regarding the state machine is defined under the `RegularExpression::NFA` module.

### 3. Bytecode

Third, we take the state machine and convert it into bytecode. This involves walking through each of the state machine's states and generating instructions that our interpreter understands. The various bytecode instructions are defined under the `RegularExpression::Bytecode::Insns` module. For the most part they consist of:

* Instructions that push and pop the current string index from the stack to support backtracking.
* Instructions that function as "guards" in that they assert that things are true (e.g., `\A` saying we're at the beginning of the string).
* Instructions that conditionally jump (e.g., a pattern with a `[a-zA-Z]` range receiving an `x` character).
* Instructions that succeed or fail the entire match.

Once we have the bytecode in place, we can pass it to our interpreter to execute. At this point we have a functional matching algorithm that will work (albeit somewhat slowly).

### 4. Control flow graph

Fourth, if asked we will take the bytecode and convert it into a control flow graph. This graph creates a list of basic blocks (a set of instructions where the first instruction is a jump target). This graph makes it easier to compile our abstract representation of the regular expression pattern because the flow of the matching algorithm becomes explicit on the block boundaries. The code for generating and managing this control flow graph is defined under the `RegularExpression::CFG` module.

### 5. Compilation

Fifth, we can take the control flow graph and pass it to one of our compilers. These compilers are responsible for taking the control flow graph and transforming it into a proc that we can call with an input string. The compilers include:

* `RegularExpression::Compiler::Ruby` - takes the control flow graph and converts it into a ruby string. To convert the string to a proc, the compiled object calls `eval`.
* `RegularExpression::Compiler::X86` - takes the control flow graph and uses the `fisk` gem to generate `X86-64` assembly. The assembly returns a function pointer, and the compiled object knows how to convert that into a proc using the `Fiddle` library. The assembled code can be disassembled using the `crabstone` gem.

## Additional reading

Below are a couple of links to other reading you can do for background on regular expressions which additionally served as inspiration for this project.

* [Regular Expression Matching Can Be Simple And Fast - Russ Cox](https://swtch.com/~rsc/regexp/regexp1.html)
* [Regular Expression Matching: the Virtual Machine Approach](https://swtch.com/~rsc/regexp/regexp2.html)
* [Regular Expression Matching in the Wild](https://swtch.com/~rsc/regexp/regexp3.html)
* [Understanding Computation, Chapter 3: "The Simplest Computers" - Tom Stuart](https://computationbook.com/)
* [Exploring Ruby’s Regular Expression Algorithm](http://patshaughnessy.net/2012/4/3/exploring-rubys-regular-expression-algorithm)
