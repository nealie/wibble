## Wibble Symbol

import strformat, tables
import core

method `$`*(self: Symbol): string =
  self.value

method repr*(self: Symbol): string =
  result = "<{$self.class_name}: <{self.value}> ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc newSymbol*(parent: Object, value: string): Symbol =
  ## Create a new Symbol.
  result = new Symbol
  result.class_name = symbolName
  result.slots[objectSlotParent] = parent
  result.value = value

proc newSymbol*(value: string): Symbol =
  ## Create a new Symbol, inheriting from base_symbol.
  result = newSymbol(base_objects.base_symbol, value)

proc symbolToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- String }
  ## Convert a Symbol to a String.
  let
    v = Symbol(self).value
    x = newString(v)
  echo v
  if x.isNil:
    echo "x is nil!"
  else:
    #echo "<{$x.class_name}: ref {cast[int](x):#x}>".fmt
    echo "<ref {cast[int](x):#x}>".fmt
    echo x.class_name
    echo x.slots
    echo objectSlotParent
    if x.slots[objectSlotParent].isNil:
      echo "x.slots[objectSlotParent] is nil!"
    else:
      echo x.slots[objectSlotParent]
    echo x
  stack.append(newString(Symbol(self).value))

proc symbolPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- }
  ## Print a Symbol.
  echo("'{Symbol(self).value}".fmt)

proc symbolCreateSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- }
  ## Convenience method to create a slot in the scope when the Object containing the
  ## slot is not mentioned.
  let name = Symbol(self).value
  if name in scope.slots:
    raise newError[SymbolError]("create - Slot {name} already exists.".fmt)
  scope.slots[name] = base_objects.base_nil

proc symbolGetSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- Object }
  ## Convenience method to get a slot value in the scope when the Object containing the
  ## slot is not mentioned.
  let name = Symbol(self).value
  if name in scope.slots:
    stack.append(scope.slots[name])
  else:
    # Get local, so we know where to stop looking.
    #let local = scope.get_slot(localObjectName)
    var parent = scope.slots[objectSlotParent]
    #while parent != local and not parent.isNil:
    while not parent.isNil:
      if name in parent.slots:
        stack.append(parent.slots[name])
        return
      else:
        parent = parent.slots[objectSlotParent]
    raise newError[SymbolError]("get - Slot {name} does not exist in local chain.".fmt)

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
    #let local = scope.get_slot(localObjectName)
    var parent = scope.slots[objectSlotParent]
    #while parent != local and not parent.isNil:
    while not parent.isNil:
      if name in parent.slots:
        parent.slots[name] = stack.pop
        return
      else:
        parent = parent.slots[objectSlotParent]
    raise newError[SymbolError]("set - Slot {name} does not exist in local chain.".fmt)

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

proc initObjects*() =
    base_objects.base_symbol = newSymbol(base_objects.base_object, "")
    base_objects.global_object.slots[symbolName] = base_objects.base_symbol
    base_objects.base_symbol.slots["toString"] = newNativeProc(symbolToString)
    base_objects.base_symbol.slots["print"] = newNativeProc(symbolPrint)
    base_objects.base_symbol.slots["create"] = newNativeProc(symbolCreateSlot)
    base_objects.base_symbol.slots["get"] = newNativeProc(symbolGetSlot)
    base_objects.base_symbol.slots["set"] = newNativeProc(symbolSetSlot)
    base_objects.base_symbol.slots["="] = newNativeProc(symbolEquals) 
    base_objects.base_symbol.slots["!="] = newNativeProc(symbolNotEquals)
