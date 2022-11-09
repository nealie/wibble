## Wibble String.

import std/[strformat, strutils, tables]
import base, list

base_objects.base_string = newString(base_objects.base_symbol, "")
base_objects.global_object.slots[stringName] = base_objects.base_string

proc stringNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { -- String }
  ## Create a new empty String.
  stack.append(newString(""))

base_objects.base_string.slots["new"] = newNativeProc(stringNew)

proc stringToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- String }
  ## Just return a new copy of ourself.
  stack.append(newString(String(self).value))

base_objects.base_string.slots[objectSlotStringify] = newNativeProc(stringToString)

proc stringRepr*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- String }
  ## Display String representation.
  var result = "\"{String(self).value}\"".fmt
  stack.append(newString(result))

base_objects.base_string.slots[objectSlotRepr] = newNativeProc(stringRepr)

proc stringAppend*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String String-self -- String }
  ## Append one String to another.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_string)]])
  except ParameterError as error:
    raise newError[StringError](fmt"& - {error.msg}")

  stack.append(newString(String(stack.pop()).value & String(self).value))

base_objects.base_string.slots["&"] = newNativeProc(stringAppend)

proc stringPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- }
  ## Print a String.
  echo(String(self).value)

base_objects.base_string.slots["print"] = newNativeProc(stringPrint)

proc stringToSymbol*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- Symbol }
  ## Convert a String to a Symbol.
  stack.append(newSymbol(String(self).value))

base_objects.base_string.slots["toSymbol"] = newNativeProc(stringToSymbol)

proc stringIn*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String/Symbol Symbol-self -- Boolean }
  ## Determine whether a string is contained within another as a substring.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_string)], @[Object(base_objects.base_symbol)]])
    if index == 0:
      stack.append(toBoolean(String(stack.pop()).value in String(self).value))
    else:
      stack.append(toBoolean(Symbol(stack.pop()).value in String(self).value))
  except ParameterError as error:
    raise newError[StringError](fmt"/ - {error.msg}")

base_objects.base_string.slots["in"] = newNativeProc(stringIn) 