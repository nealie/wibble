# Wibble

The Wibble programming language is an experimental language that I am using to explore some ideas.
It's very much in its early days and is currently not of much use for anything.

## Concept

There are some concepts that I like, but no language uses them all, until now:

- Homoiconic - like lisp
- Stack based - like forth
- Object oriented, using prototypes - like self

## Data Format

The parser is able to read a simple data format.
Being homoiconic, the language itself is expressed using these data types.

The most basic feature is that data elements are space separated.
End of lines are considered white space, as are commas, just for convenience.

### Lists

Lists are denoted using square brackets: `[` and `]`.
Elements within the list must of course be space separated, however the start and end of list
do not need to be.

### Comments

There are two kinds of comments:

- Inline comments start with a `#` and finish at the end of line.
- Block comments are enclosed within curly brackets: `{` and `}`.

### Strings

Strings are simply enclosed within double quotes: `"`.
They can span lines.

There are a few special escape characters, denoted by the backspace: `\`:

- `\\` - Backslash.
- `\"` - Double quote.
- `\'` - Single quote.
- `\r` or `\c` - Carriage return.
- `\n` or `\l` - Newline.
- `\f` - Form feed.
- `\t` - Tab.
- `\v` - Vertical tab.
- `\a` - Alert.
- `\b` - Backspace.
- `\e` - Escape.
- `\x<nn>` - Hex value of a character.
- `\<0..9>` - Decimal value of a character.

### Numbers

If a value starts with a value of `0`..`9` or a decimal point `.`, 
optionally preceded by a `+` or `-`,
then it's parsed as a Number.

Hex values can be used starting with `0x`, which are always Integer.

If the value contains a `.`, `e` or `E`, then the Number is a Float, otherwise it's parsed as
an Integer.

### Symbols

Everything else is considered a Symbol.

## Objects

Everything is an Object. Objects can basically be considered to be associative arrays.
Values are stored within an Object's slots.

An Object has a `_parent` slot. This is used for slot lookup when looking up a slot that
does not exist within the Object.

An Object (or more likely it's parent) also has a `_call` slot, which is called whenever an
Object is referenced. Object itself defines this as pushing itself onto the stack and this
behaviour is inherited by most other more specialised objects. Proc's however refer to themselves.

There are two special Objects:

- `global` - This contains all of the base Objects.

- `local` - This forms the basis of scope.

## Scope

The `local` object forms the basis of scope. When a block of code is executing, such as with `do`, `if` or `while`, a new scope Object is created. The `_parent` of this Object is the previous scope Object. The name `local` always refers to the current scope.

This operates as lexical scope.

## Stacks

The language operates on a stack using postfix notation.
All stack operations are prefixed with a dot.
This is simply a way of directing the operation to the stack in stead of the scope.

## Execution

The following are simply added to the stack:
- Number
- String
- List
- 'Symbol

Everything else should be a symbol.

Symbols beginning with "." are applied to the stack, otherwise the appropriate
slot will be looked up the the following order:

1. If there is an Object on the stack, look there.
2. Within the scope Object.
3. In global.

When an Object is found, it will be called.