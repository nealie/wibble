## Wibble Integer.

import std/[math, strformat, tables]
import base, list

base_objects.base_integer = newInteger(base_objects.base_number)
base_objects.global_object.slots[integerName] = base_objects.base_integer

proc integerToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- String }
  ## Convert the value of an Integer to a String.
  stack.append(newString($Integer(self).value))

base_objects.base_integer.slots[objectSlotStringify] = newNativeProc(integerToString)
base_objects.base_integer.slots[objectSlotRepr] = newNativeProc(integerToString)

proc integerPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- }
  ## Print the value of an Integer.
  echo(Integer(self).value)

base_objects.base_integer.slots["print"] = newNativeProc(integerPrint)

proc integerToFloat*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- Float }
  ## Convert an Integer to a Float.
  stack.append(newFloat(Integer(self).value.float))

base_objects.base_integer.slots["toFloat"] = newNativeProc(integerToFloat)

proc integerAdd*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Add either an Integer or Float to an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(Integer(stack.pop()).value + Integer(self).value))
    else:
      stack.append(newFloat(Float(stack.pop()).value + float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"+ - {error.msg}")

base_objects.base_integer.slots["+"] = newNativeProc(integerAdd)

proc integerSubtract*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Subtract either an Integer or Float from an Integer.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(Integer(stack.pop()).value - Integer(self).value))
    else:
      stack.append(newFloat(Float(stack.pop()).value - float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"- - {error.msg}")

base_objects.base_integer.slots["-"] = newNativeProc(integerSubtract)

proc integerMultiply*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Multiply an Integer by either an Integer or a Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(Integer(stack.pop()).value * Integer(self).value))
    else:
      stack.append(newFloat(Float(stack.pop()).value * float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"* - {error.msg}")

base_objects.base_integer.slots["*"] = newNativeProc(integerMultiply)

proc integerDivide*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Divide an Integer by either an Integer or a Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(int(Integer(stack.pop()).value / Integer(self).value)))
    else:
      stack.append(newFloat(Float(stack.pop()).value / float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["/"] = newNativeProc(integerDivide)

proc integerModulo*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Integer/Float }
  ## Integer Modulus either an Integer or a Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(newInteger(int(Integer(stack.pop()).value mod Integer(self).value)))
    else:
      stack.append(newFloat(Float(stack.pop()).value mod float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["%"] = newNativeProc(integerModulo)

proc integerNegate*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- Integer }
  ## Negate the value of an Integer.
  stack.append(newInteger(-Integer(self).value))

base_objects.base_integer.slots["neg"] = newNativeProc(integerNegate)

proc integerNot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- Integer }
  ## Bitwise complement of an Integer.
  stack.append(newInteger(Integer(self).value.not))

base_objects.base_integer.slots["not"] = newNativeProc(integerNot)

proc integerAnd*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise and of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(Integer(stack.pop()).value and Integer(self).value)))

base_objects.base_integer.slots["and"] = newNativeProc(integerAnd)

proc integerOr*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise or of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(Integer(stack.pop()).value or Integer(self).value)))

base_objects.base_integer.slots["or"] = newNativeProc(integerOr)

proc integerXor*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise xor of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(Integer(stack.pop()).value xor Integer(self).value)))

base_objects.base_integer.slots["xor"] = newNativeProc(integerXor)

proc integerShiftLeft*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise shift left of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(Integer(stack.pop()).value shl Integer(self).value)))

base_objects.base_integer.slots["shl"] = newNativeProc(integerShiftLeft)

proc integerShiftRight*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise shift right of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(Integer(stack.pop()).value shr Integer(self).value)))

base_objects.base_integer.slots["shr"] = newNativeProc(integerShiftRight)

proc integerArithShiftRight*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer Integer-self -- Integer }
  ## Bitwise arithmatic shift right of an Integer.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

  stack.append(newInteger(int(ashr(Integer(stack.pop()).value, Integer(self).value))))

base_objects.base_integer.slots["ashr"] = newNativeProc(integerArithShiftRight)

proc integerEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an Integer is the same as that of another Integer or a Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value == Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value == float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["="] = newNativeProc(integerEquals)

proc integerLessThan*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an Integer is less than that of another Integer or Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value < Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value < float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["<"] = newNativeProc(integerLessThan)

proc integerLessThanOrEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an Integer is less than or equal to that of
  ## another Integer or Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value <= Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value <= float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["<="] = newNativeProc(integerLessThanOrEqual)

proc integerGreaterThan*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an integer is greater than that of another Integer or a Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value > Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value > float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots[">"] = newNativeProc(integerGreaterThan)

proc integerGreaterThanOrEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an Integer is greater than or equal to that of 
  ## another Integer or Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value >= Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value >= float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots[">="] = newNativeProc(integerGreaterThanOrEqual)

proc integerNotOrEqual*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer/Float Integer-self -- Boolean }
  ## Determine whether the value of an Integer differs from that of another Integer or Float.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_integer)], @[Object(base_objects.base_float)]])
    if index == 0:
      stack.append(toBoolean(Integer(stack.pop()).value != Integer(self).value))
    else:
      stack.append(toBoolean(Float(stack.pop()).value != float(Integer(self).value)))
  except ParameterError as error:
    raise newError[IntegerError](fmt"/ - {error.msg}")

base_objects.base_integer.slots["!="] = newNativeProc(integerNotOrEqual)