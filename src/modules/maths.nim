## Nim maths module.

import std/[math, strformat, tables]
import core

# Integer

proc integerPow*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Compute the previous Integer or Float on the stack to the value of an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(Integer(stack.pop()).value ^ Integer(self).value))
    else:
      stack.append(newFloat(Float(stack.pop()).value ^ Integer(self).value))
  except ParameterError as error:
    raise newError[IntegerError](fmt"+ - {error.msg}")

# Float

proc FloatIsNaN*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Determine whether the number is NaN.
  if Float(self).value.isNaN:
    stack.append(base_objects.base_true)
  else:
    stack.append(base_objects.base_false)

proc FloatSqrt*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Compute the square root.
  stack.append(newFloat(sqrt(Float(self).value)))

proc FloatSin*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Compute the sine.
  stack.append(newFloat(sin(Float(self).value)))

proc FloatCos*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Compute the cosine.
  stack.append(newFloat(cos(Float(self).value)))

proc FloatTan*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Compute the tangent.
  stack.append(newFloat(tan(Float(self).value)))

proc init*(base_objs: var BaseObjects, stack: var List, scope: var Object) {.cdecl, exportc, dynlib.} =
  echo "+ maths/init"
  # We have to set this here since we're in our own address space.
  base_objects = base_objs

  # Integer.
  base_objects.base_integer.slots["^"] = newNativeProc(integerPow)

  # Float.
  base_objects.base_float.slots["isNaN"] = newNativeProc(FloatIsNaN)
  base_objects.base_float.slots["sqrt"] = newNativeProc(FloatSqrt)
  base_objects.base_float.slots["sin"] = newNativeProc(FloatSin)
  base_objects.base_float.slots["cos"] = newNativeProc(FloatCos)
  base_objects.base_float.slots["tan"] = newNativeProc(FloatTan)

  echo "+ done"