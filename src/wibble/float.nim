## Wibble Float.

import std/[strformat, tables]
import base, list

base_objects.base_float = newFloat(base_objects.base_number, 0.0)
base_objects.global_object.slots[floatName] = base_objects.base_float

proc floatToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- String }
  ## Convert the value of a Float to a String.
  stack.append(newString($Float(self).value))

base_objects.base_float.slots[objectSlotStringify] = newNativeProc(floatToString)
base_objects.base_float.slots[objectSlotRepr] = newNativeProc(floatToString)

proc floatPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- }
  ## Print the value of a Float.
  echo($Float(self).value)

base_objects.base_float.slots["print"] = newNativeProc(floatPrint)

proc floatToInteger*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Integer }
  ## Convert the value of a Float to an Integer.
  stack.append(newInteger(Float(self).value.int))

base_objects.base_float.slots["toInteger"] = newNativeProc(floatToInteger)

proc floatAdd*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Float }
  ## Add a Float to either a Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(newFloat(Float(stack.pop()).value + Float(self).value))
    else:
      stack.append(newFloat(float(Integer(stack.pop()).value) + Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"+ - {error.msg}")

base_objects.base_float.slots["+"] = newNativeProc(floatAdd)

proc floatSubtract*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Float }
  ## Subtract a Float from either a Float or Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(newFloat(Float(stack.pop()).value - Float(self).value))
    else:
      stack.append(newFloat(float(Integer(stack.pop()).value) - Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"- - {error.msg}")

base_objects.base_float.slots["-"] = newNativeProc(floatSubtract)

proc floatMultiply*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Float }
  ## Multiply a Float by either a Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(newFloat(Float(stack.pop()).value * Float(self).value))
    else:
      stack.append(newFloat(float(Integer(stack.pop()).value) * Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"* - {error.msg}")

base_objects.base_float.slots["*"] = newNativeProc(floatMultiply)

proc floatDivide*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Float }
  ## Divide a Float by either a Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(newFloat(Float(stack.pop()).value / Float(self).value))
    else:
      stack.append(newFloat(float(Integer(stack.pop()).value) / Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots["/"] = newNativeProc(floatDivide)

proc floatNegate*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Float }
  ## Negate the value of an Integer.
  stack.append(newFloat(-Float(self).value))

base_objects.base_float.slots["neg"] = newNativeProc(floatNegate) 

proc floatEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## Determine whether a Float is equal to another Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value == Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) == Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots["="] = newNativeProc(floatEquals)

proc floatLessThan*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## Determine whether a Float is less than another Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value < Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) < Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots["<"] = newNativeProc(floatLessThan)

proc floatLessThanOrEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## Determine whether a Float is less than or equal to another Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value <= Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) <= Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots["<="] = newNativeProc(floatLessThanOrEqual)

proc floatGreaterThan*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## Determine whether a Float is greater than another Float or an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value > Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) > Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots[">"] = newNativeProc(floatGreaterThan)

proc floatGreaterThanOrEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## Determine whether a Float is greater than or euqal to another Float or Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value >= Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) >= Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots[">="] = newNativeProc(floatGreaterThanOrEqual)

proc floatNotEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float/Integer Float-self -- Boolean }
  ## DFetermine whether a Float is not euqal to another Float or Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_float)], @[Object(base_objects.base_integer)]])
    if index == 0:
      stack.append(toBoolean(Float(stack.pop()).value != Float(self).value))
    else:
      stack.append(toBoolean(float(Integer(stack.pop()).value) != Float(self).value))
  except ParameterError as error:
    raise newError[FloatError](fmt"/ - {error.msg}")

base_objects.base_float.slots["!="] = newNativeProc(floatNotEqual)