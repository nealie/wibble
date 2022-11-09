## Wibble Boolean.

import std/[strformat, tables]
import base, list

base_objects.base_boolean = newBoolean(base_objects.base_object, true)
base_objects.global_object.slots[booleanName] = base_objects.base_boolean
base_objects.base_true = newBoolean(base_objects.base_boolean, true)
base_objects.global_object.slots[trueObjectName] = base_objects.base_true
base_objects.base_false = newBoolean(base_objects.base_boolean, false)
base_objects.global_object.slots[falseObjectName] = base_objects.base_false

proc booleanToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean-self -- String }
  ## Convert the value of a Boolean to a String.
  stack.append(newString($Boolean(self).value))

base_objects.base_boolean.slots[objectSlotStringify] = newNativeProc(booleanToString)
base_objects.base_boolean.slots[objectSlotRepr] = newNativeProc(booleanToString)

proc booleanPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean-self -- }
  ## Print the value of a Boolean.
  echo(Boolean(self).value)

base_objects.base_boolean.slots["print"] = newNativeProc(booleanPrint)

proc booleanAnd*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean Boolean-self -- Boolean }
  ## Perform a logical and between two Booleans.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_boolean)]])
  except ParameterError as error:
    raise newError[BooleanError](fmt"and - {error.msg}")

  stack.append(toBoolean(Boolean(stack.pop).value and Boolean(self).value))

base_objects.base_boolean.slots["and"] = newNativeProc(booleanAnd)

proc booleanOr*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean Boolean-self -- Boolean }
  ## Perform a logical or between two Booleans.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_boolean)]])
  except ParameterError as error:
    raise newError[BooleanError](fmt"or - {error.msg}")

  stack.append(toBoolean(Boolean(stack.pop).value or Boolean(self).value))

base_objects.base_boolean.slots["or"] = newNativeProc(booleanOr)

proc booleanXor*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean Boolean-self -- Boolean }
  ## Perform a logical exclusive or between two Booleans.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_boolean)]])
  except ParameterError as error:
    raise newError[BooleanError](fmt"xor - {error.msg}")

  stack.append(toBoolean(Boolean(stack.pop).value xor Boolean(self).value))

base_objects.base_boolean.slots["xor"] = newNativeProc(booleanXor)

proc booleanNot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Boolean-self -- Boolean }
  ## Invert the value of a Boolean.
  stack.append(toBoolean(not Boolean(self).value))

base_objects.base_boolean.slots["not"] = newNativeProc(booleanNot)