## Wibble REPL

import std/[streams, strformat]
import wibble/[core, parser, exec]

#echo base_objects.global_object.repr_tree("global")

var
  stack = newStack()
  scope = newScope()

# echo stack.repr_tree("stack")
# echo scope.repr_tree("scope")

while true:
  try:
    stdout.write("> ")
    let
      line = readLine(stdin)
      stream = newStringStream(line)
      parsed_input = parse_data(stream)

    #echo($parsed_input)
    exec(stack, scope, parsed_input)
    echo("Stack {to_repr(stack, scope, stack)}".fmt)
  except EOFError:
    break

