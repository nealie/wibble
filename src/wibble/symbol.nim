## Wibble Symbol.

import std/[strformat, tables]
import base, list

base_objects.base_symbol = newSymbol(base_objects.base_object, "Symbol")
base_objects.global_object.slots[symbolName] = base_objects.base_symbol

proc symbolNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- }
  ## Can't create an abstract Symbol.
  raise newError[SymbolError]("new - Can't create an anstract Symbol.")

base_objects.base_symbol.slots["new"] = newNativeProc(symbolNew) 

proc symbolToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- String }
  ## Convert a Symbol to a String.
  stack.append(newString(Symbol(self).value))

base_objects.base_symbol.slots[objectSlotStringify] = newNativeProc(symbolToString)
base_objects.base_symbol.slots[objectSlotRepr] = newNativeProc(symbolToString)

proc symbolPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- }
  ## Print a Symbol.
  echo("'{Symbol(self).value}".fmt)

base_objects.base_symbol.slots["print"] = newNativeProc(symbolPrint)

proc symbolCreateSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- }
  ## Convenience method to create a slot in the scope when the Object containing the
  ## slot is not mentioned.
  let name = Symbol(self).value
  if name in scope.slots:
    raise newError[SymbolError]("create - Slot {name} already exists.".fmt)
  scope.slots[name] = base_objects.base_nil

base_objects.base_symbol.slots["create"] = newNativeProc(symbolCreateSlot)

proc symbolGetSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- Object }
  ## Convenience method to get a slot value in the scope when the Object containing the
  ## slot is not mentioned.
  let name = Symbol(self).value
  if name in scope.slots:
    stack.append(scope.slots[name])
  else:
    # Get local, so we know where to stop looking.
    var parent = scope.slots[objectSlotParent]
    while not parent.isNil:
      if name in parent.slots:
        stack.append(parent.slots[name])
        return
      else:
        parent = parent.slots[objectSlotParent]
    raise newError[SymbolError]("get - Slot {name} does not exist in local chain.".fmt)

base_objects.base_symbol.slots["get"] = newNativeProc(symbolGetSlot)

proc symbolSetSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object Symbol-self -- }
  ## Convenience method to se the value of a slot in the scope when the Object containing the
  ## slot is not mentioned.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object]])
  except ParameterError as error:
    raise newError[SymbolError](fmt"set - {error.msg}")

  let name = Symbol(self).value
  if name in scope.slots:
    scope.slots[name] = stack.pop
  else:
    # Get local, so we know where to stop looking.
    var parent = scope.slots[objectSlotParent]
    while not parent.isNil:
      if name in parent.slots:
        parent.slots[name] = stack.pop
        return
      else:
        parent = parent.slots[objectSlotParent]
    raise newError[SymbolError]("set - Slot {name} does not exist in local chain.".fmt)

base_objects.base_symbol.slots["set"] = newNativeProc(symbolSetSlot)

proc symbolEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol/String Symbol-self -- Boolean }
  ## Determine whether one Symbol is the same as another.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_symbol)], @[Object(base_objects.base_string)]])
    if index == 0:
      stack.append(toBoolean(Symbol(stack.pop()).value == Symbol(self).value))
    else:
      stack.append(toBoolean(String(stack.pop()).value == Symbol(self).value))
  except ParameterError as error:
    raise newError[SymbolError](fmt"/ - {error.msg}")

base_objects.base_symbol.slots["="] = newNativeProc(symbolEquals)

proc symbolNotEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol/String Symbol-self -- Boolean }
  ## Determine whether one Symbol differs from another.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_symbol)], @[Object(base_objects.base_string)]])
    if index == 0:
      stack.append(toBoolean(Symbol(stack.pop()).value != Symbol(self).value))
    else:
      stack.append(toBoolean(String(stack.pop()).value != Symbol(self).value))  except ParameterError as error:
    raise newError[SymbolError](fmt"/ - {error.msg}")

base_objects.base_symbol.slots["!="] = newNativeProc(symbolNotEquals)