## Wibble core objects.

{.experimental: "codeReordering".}

import std/[strutils, strformat, streams, tables, sugar, os]

const
  # Base Object names.
  objectName* = "Object"
  nilName* = "Nil"
  nativeProcName* = "NativeProc"
  symbolName* = "Symbol"
  stringName* = "String"
  numberName* = "Number"
  integerName* = "Integer"
  floatName* = "Float"
  booleanName* = "Boolean"
  listName* = "List"
  stackName* = "Stack"
  procName* = "Proc"

  # Slot names.
  objectSlotParent* = "_parent"
  objectSlotCall* = "_callable"
  procSlotArgs* = "arguments"
  procSlotReturn* = "returns"
  procSlotScope* = "scope"
  procSlotName* = "name"
  procSlotCode* = "code"
  globalObjectName* = "global"
  localObjectName* = "local"
  modulesObjectName* = "modules"
  trueObjectName = "true"
  falseObjectName = "false"
  selfReferentialSlots = [globalObjectName, localObjectName]

type
  Object* {.inheritable.} = ref object
    ## Basic Object.
    class_name*: string             ## Natively implemented Objects have special names.
    slots*: Table[string, Object]   ## All Object values go into a slot.

  Nil* = ref object of Object
    ## Singleton Nil Object.

  ProcSig* = proc(stack: var List, scope: var Object, self: Object, proc_def: Proc)
    ## Callable signature.

  Proc* = ref object of Object
    ## Procedure.
    call*: ProcSig                  ## Callable proc.

  NativeProc* = ref object of Proc
    ## Native Procedure.

  Symbol* = ref object of Object
    ## Symbolic value.
    value*: string

  String* = ref object of Object
    ## String value.
    value*: string

  Number* = ref object of Object
    ## Abstract base of all Numbers.

  Integer* = ref object of Number
    ## Integer Number.
    value*: int

  Float* = ref object of Number
    ## Floating point Number.
    value*: float

  Boolean* = ref object of Object
    ## Boolean Object.
    ## There are two singleton values in global: true and false.
    value*: bool

  List* = ref object of Object
    ## List containing other Objects.
    items*: seq[Object]


  CoreError* = ref object of CatchableError
    ## Base for all core exceptions.

  ObjectError* = ref object of CoreError
    ## create, get and set.

  NumberError* = ref object of CoreError

  IntegerError* = ref object of NumberError

  FloatError* = ref object of NumberError

  EmptyListError* = ref object of CoreError

  ConditionalError* = ref object of CoreError

  SymbolError* = ref object of CoreError

  StringError* = ref object of CoreError

  StackError* = ref object of CoreError

  ProcError* = ref object of CoreError

  ProcExecError* = ref object of CoreError

  ParameterError* = ref object of CoreError

  BooleanError* = ref object of CoreError

  ListError* = ref object of CoreError

# Necessary forward declarations.
# proc pop*(self: var List): Object

# proc append*(self: var List, item: Object)

# proc newFloat*(value: float): Float

# proc newString*(value: string): String

# proc newList*(items: seq[Object]): List

# proc newList*(): List

# proc len*(self: List): int

# proc objectIsA*(a, b: Object): bool


proc newError*[T](msg: string): T =
  ## Create a new CoreError concrete type with added message.
  result = new T
  result.msg = "{$T.type}: {msg}".fmt

method `$`*(self: Object): string {.base.} =
  result = "<{$self.class_name}: ref {cast[int](self):#x}>".fmt

method repr*(self: Object): string {.base.} =
  result = "<{$self.class_name}: ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.type} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc repr_tree*(self: Object, name: string, indent: string = ""): string =
  ## Describe object structure in a tree.
  result = "{indent}{name}: <{$self.class_name}: ref {cast[int](self):#x}: Slots: [\n".fmt
  let new_indent = indent & "  "
  for slot_name, slot_obj in self.slots.pairs:
    if slot_name.startsWith("_") or slot_name in selfReferentialSlots:
      if slot_obj.isNil:
        result &= "{new_indent}{slot_name}: <nil>\n".fmt
      else:
        result &= "{new_indent}{slot_name}: <{$slot_obj.class_name}: ref {cast[int](slot_obj):#x}>\n".fmt
    else:
      if slot_obj.isNil:
        result &= "{new_indent}{slot_name}: <nil>\n".fmt
      else:
        result &= "{slot_obj.repr_tree(slot_name, new_indent)}".fmt
  result &= "{indent}]\n".fmt

proc checkArgs*(stack: var List, scope: var Object, parameters: openarray[seq[Object]]): int =
  ## Check that the specified arguments exist on the stack.
  ## Try to match for each set of arguments and return the index matched.

  result = 0

  for index, args in parameters:
    if stack.len < args.len:
      # Not enough values on the stack.
      continue

    block check:
      var 
        param_index = args.len - 1
        stack_index = stack.len - 1
      while param_index >= 0:
        let
          kind = args[param_index]
          value = stack.items[stack_index]
        if not objectIsA(value, kind):
          break check
        param_index.dec
        stack_index.dec
      return index

  # Nothing has matched, so whinge.
  var names: seq[string]
  for args in parameters:
    let args_names = collect:
      for obj in args:
        obj.class_name
    names.add(args_names.join(" "))
  let namess = names.join("/")
  raise newError[ParameterError](fmt"Expected parameters not found, expected: {namess}")

# Collection of all base objects.
type
  BaseObjects* = object
    global_object*: Object  # Pseudo Object, but not inheriting from Object.
    base_object*: Object
    base_nil*: Object
    # base_block*: Object
    base_symbol*: Symbol
    base_number*: Number
    base_integer*: Integer
    base_float*: Float
    base_string*: String
    base_boolean*: Boolean
    base_true*: Boolean
    base_false*: Boolean
    base_list*: List
    base_stack*: List
    base_proc*: Proc

var 
  base_objects*: BaseObjects    ## Base of the Object hierarchy.

proc toBoolean*(value: bool): Boolean =
  ## Convert a bool to Boolean.
  if value:
    result = base_objects.base_true
  else:
    result = base_objects.base_false

proc newNativeProc*(the_proc: ProcSig): NativeProc =
  ## Create a callable NativeProc from a nim proc.
  result = new NativeProc
  result.class_name = nativeProcName
  result.call = the_proc
  result.slots[objectSlotCall] = base_objects.base_true

proc newObject*(parent: Object): Object =
  ## Create a new Object, inheriting from a parent Object.
  result = new Object
  result.class_name = objectName
  result.slots[objectSlotParent] = parent

base_objects.global_object = newObject(nil)
base_objects.global_object.slots[globalObjectName] = base_objects.global_object

base_objects.base_object = newObject(nil)
base_objects.global_object.slots[objectName] = base_objects.base_object

# Create Nil singleton.
base_objects.base_nil = newObject(base_objects.base_object)
base_objects.base_nil.class_name = nilName
base_objects.global_object.slots[nilName] = base_objects.base_nil

# Create modules Object.
base_objects.global_object.slots[modulesObjectName] = newObject(base_objects.base_object)

# base_objects.base_block = newObject(nil)
# base_objects.base_block.class_name = "Block"
#base_objects.global_object.slots["_block"] = base_objects.base_block

proc newObject*(): Object =
  ## Create a new Object, inheriting from the base_object.
  result = newObject(base_objects.base_object)

proc callable*(self: Object): bool =
  ## Determine whether an Object is callable.
  result = objectSlotCall in self.slots

proc objectNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- Object }
  ## Create a new Object.
  stack.append(newObject(self))

base_objects.base_object.slots["new"] = newNativeProc(objectNew)

proc nilNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- Object-self }
  ## Nil is a singleton, so return it.
  stack.append(self)

base_objects.base_nil.slots["new"] = newNativeProc(nilNew)

proc objectRepr*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- String }
  ## Return a representation of an Object.
  stack.append(newString(self.repr))

base_objects.base_object.slots["repr"] = newNativeProc(objectRepr)
base_objects.global_object.slots["repr"] = base_objects.base_object.slots["repr"]

method get_slot*(self: Object, slot: string): Object {.base.} =
  ## Get a slot from the object chain, or return nil if not found.
  if slot notIn self.slots:
    var parent = self.slots[objectSlotParent]
    if parent.isNil:
      return nil
    else:
      return parent.get_slot(slot)
  # if self.slots[slot] == base_objects.base_block:
  #   return nil
  return self.slots[slot]

proc objectGetSlots*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- List }
  ## Get the slots of an Object.
  var keys = newSeq[Object]()
  for key in self.slots.keys:
    keys.add(newString(key))
  stack.append(newList(keys))

base_objects.base_object.slots["slots"] = newNativeProc(objectGetSlots)
base_objects.global_object.slots["slots"] = base_objects.base_object.slots["slots"]

proc objectCreateSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol Object-self -- }
  ## Create a new slot in an Object.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_symbol)]])
  except ParameterError as error:
    raise newError[ObjectError](fmt"create - {error.msg}")

  let name = Symbol(stack.pop).value
  if name in self.slots:
    raise newError[ObjectError]("create - Slot {name} already exists.".fmt)
  self.slots[name] = base_objects.base_nil

base_objects.base_object.slots["create"] = newNativeProc(objectCreateSlot)
base_objects.global_object.slots["create"] = base_objects.base_object.slots["create"]

proc objectSetSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object Symbol Object-self -- }
  ## Set the value of a slot in an Object.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object, Object(base_objects.base_symbol)]])
  except ParameterError as error:
    raise newError[ObjectError](fmt"set - {error.msg}")

  let name = Symbol(stack.pop).value

  if name notIn self.slots:
    raise newError[ObjectError]("set - Slot {name} does not exist on Object.".fmt)

  self.slots[name] = stack.pop

base_objects.base_object.slots["set"] = newNativeProc(objectSetSlot)
base_objects.global_object.slots["set"] = base_objects.base_object.slots["set"]

proc objectGetSlot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol Object-self -- Object }
  ## Get the value of an Object's slot.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_symbol)]])
  except ParameterError as error:
    raise newError[ObjectError](fmt"get - {error.msg}")

  let name = Symbol(stack.pop).value

  if name notIn self.slots:
    raise newError[ObjectError]("get - Slot {name} does not exist on Object.".fmt)

  stack.append(self.slots[name])

base_objects.base_object.slots["get"] = newNativeProc(objectGetSlot)
base_objects.global_object.slots["get"] = base_objects.base_object.slots["get"]

proc objectIsA*(a, b: Object): bool =
  ## Determine whether Object a is a b.
  result = false
  var parent = a.slots[objectSlotParent]
  while not(parent.isNil):
    if parent == b:
      return true
    parent = parent.slots[objectSlotParent]

# Symbol

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

base_objects.base_symbol = newSymbol(base_objects.base_object, "")
base_objects.global_object.slots[symbolName] = base_objects.base_symbol

proc newSymbol*(value: string): Symbol =
  ## Create a new Symbol, inheriting from base_symbol.
  result = newSymbol(base_objects.base_symbol, value)

proc symbolToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- String }
  ## Convert a Symbol to a String.
  stack.append(newString(Symbol(self).value))

base_objects.base_symbol.slots["toString"] = newNativeProc(symbolToString)

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

# String

method `$`*(self: String): string =
  "\"$#\"" % self.value

method repr*(self: String): string =
  result = "<{$self.class_name}: <{self.value}> ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc newString*(parent: Object, value: string): String =
  result = new String
  result.class_name = stringName
  result.slots[objectSlotParent] = parent
  result.value = value

base_objects.base_string = newString(base_objects.base_object, "")
base_objects.global_object.slots[stringName] = base_objects.base_string

proc newString*(value: string): String =
  ## Create a new String.
  result = newString(base_objects.base_string, value)

proc newString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { -- String }
  ## Create a new empty String.
  stack.append(newString(""))

base_objects.base_string.slots["new"] = newNativeProc(newString)

# proc append(self: String, item: char) =
#   self.value.add(item)

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

proc stringEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String/Symbol Symbol-self -- Boolean }
  ## Determine whether a String is the same as another.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_string)], @[Object(base_objects.base_symbol)]])
    if index == 0:
      stack.append(toBoolean(String(stack.pop()).value == String(self).value))
    else:
      stack.append(toBoolean(Symbol(stack.pop()).value == String(self).value))
  except ParameterError as error:
    raise newError[StringError](fmt"/ - {error.msg}")

base_objects.base_string.slots["="] = newNativeProc(stringEquals) 

proc stringNotEquals*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String/Symbol Symbol-self -- Boolean }
  ## Determine whether a String differs from another.
  try:
    let index = checkArgs(stack, scope, [@[Object(base_objects.base_string)], @[Object(base_objects.base_symbol)]])
    if index == 0:
      stack.append(toBoolean(String(stack.pop()).value != String(self).value))
    else:
      stack.append(toBoolean(Symbol(stack.pop()).value != String(self).value))
  except ParameterError as error:
    raise newError[StringError](fmt"/ - {error.msg}")

base_objects.base_string.slots["!="] = newNativeProc(stringNotEquals) 

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

# Number

proc newNumber*(parent: Object): Number =
  ## Create a new Number.
  ## This is only used to create base_number.
  result = new Number
  result.class_name = numberName
  result.slots[objectSlotParent] = parent

base_objects.base_number = newNumber(base_objects.base_object)
base_objects.global_object.slots[numberName] = base_objects.base_number

proc numberNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Number-self -- }
  ## Can't create an abstract Number.
  raise newError[NumberError]("new - Can't create an anstract Number.")

base_objects.base_number.slots["new"] = newNativeProc(numberNew) 

# Integer

method `$`*(self: Integer): string =
  result = $self.value

method repr*(self: Integer): string =
  result = "<{$self.class_name}: <{self.value}> ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc newInteger*(parent: Object): Integer =
  ## Create a new Integer, given a parent Object.
  result = new Integer
  result.class_name = integerName
  result.slots[objectSlotParent] = parent

base_objects.base_integer = newInteger(base_objects.base_number)
base_objects.global_object.slots[integerName] = base_objects.base_integer

proc newInteger*(value: int): Integer =
  ## Create a new Integer with base_integer as it's parent.
  result = newInteger(base_objects.base_integer)
  result.value = value

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

proc integerPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- }
  ## Print the value of an Integer.
  echo(Integer(self).value)

base_objects.base_integer.slots["print"] = newNativeProc(integerPrint)

proc integerToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- String }
  ## Convert the value of an Integer to a String.
  stack.append(newString($Integer(self).value))

base_objects.base_integer.slots["toString"] = newNativeProc(integerToString)

proc integerToFloat*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer-self -- Float }
  ## Convert an Integer to a Float.
  stack.append(newFloat(Integer(self).value.float))

base_objects.base_integer.slots["toFloat"] = newNativeProc(integerToFloat)

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

# Float

method `$`*(self: Float): string =
  #result = self.value.formatFloat(precision = -1)
  result = $self.value

method repr*(self: Float): string =
  #result = "<{$self.type}: <{self.value.formatFloat(precision = -1)}> ref {cast[int](self):#x} Slots: [\n".fmt
  result = "<{$self.class_name}: <{self.value}> ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc newFloat*(parent: Object, value: float): Float =
  ## Create a new Float, given a parent and value.
  result = new Float
  result.class_name = floatName
  result.slots[objectSlotParent] = parent
  result.value = value

base_objects.base_float = newFloat(base_objects.base_number, 0.0)
base_objects.global_object.slots[floatName] = base_objects.base_float

proc newFloat*(value: float): Float =
  ## Create a new Float with base_float as it's parent.
  result = newFloat(base_objects.base_float, value)

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

proc floatPrint*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- }
  ## Print the value of a Float.
  echo($Float(self).value)

base_objects.base_float.slots["print"] = newNativeProc(floatPrint)

proc floatToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- String }
  ## Convert the value of a Float to a String.
  stack.append(newString($Float(self).value))

base_objects.base_float.slots["toString"] = newNativeProc(floatToString)

proc floatToInteger*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Float-self -- Integer }
  ## Convert the value of a Float to an Integer.
  stack.append(newInteger(Float(self).value.int))

base_objects.base_float.slots["toInteger"] = newNativeProc(floatToInteger)

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

# Booleans.

method `$`*(self: Boolean): string =
  result = $self.value

method repr*(self: Boolean): string =
  result = "<{$self.class_name}: <{self.value}> ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] >".fmt

proc newBoolean(parent: Object, value: bool): Boolean =
  ## Create a new Boolean.
  result = new Boolean
  result.class_name = booleanName
  result.slots[objectSlotParent] = parent
  result.value = value

base_objects.base_boolean = newBoolean(base_objects.base_object, true)
base_objects.global_object.slots[booleanName] = base_objects.base_boolean
base_objects.base_true = newBoolean(base_objects.base_boolean, true)
base_objects.global_object.slots[trueObjectName] = base_objects.base_true
base_objects.base_false = newBoolean(base_objects.base_boolean, false)
base_objects.global_object.slots[falseObjectName] = base_objects.base_false

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

# List

method `$`*(self: List): string =
  result = "["
  var separator = ""

  for value in self.items:
    if value == self:
      result.add("{separator}<{$value.class_name} ref {cast[int](value):#x}>".fmt)
      if separator == "":
        separator = " "
    else:
      result.add("{separator}{value}".fmt)
      if separator == "":
        separator = " "

  result.add("]")

method repr*(self: List): string =
  result = "<{$self.class_name}: ref {cast[int](self):#x} Slots: [\n".fmt
  for name, value in self.slots.pairs:
    result &= "  \"{name}\" {$value.class_name} ref {cast[int](value):#x}\n".fmt
  result &= "] > [".fmt
  var separator = ""

  for value in self.items:
    result.add("$#$#" % [separator, $value])
    if separator == "":
      separator = " "

  result.add("]")

proc newList*(parent: Object): List =
  ## Create a new empty List.
  result = new List
  result.class_name = listName
  result.slots[objectSlotParent] = parent

base_objects.base_list = newList(base_objects.base_object)
base_objects.global_object.slots[listName] = base_objects.base_list

proc newList*(parent: Object, items: seq[Object]): List =
  ## Create a new List of items.
  result = new List
  result.class_name = listName
  result.slots[objectSlotParent] = parent
  result.items = items

proc newList*(): List =
  ## Create a new List with base_list as it's parent.
  result = newList(base_objects.base_list)

proc newList*(items: seq[Object]): List =
  ## Create a new List of items with base_list as it's parent.
  result = newList(base_objects.base_list, items)

proc listNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- List }
  ## Create new empty List.
  stack.append(newList(self))

base_objects.base_list.slots["new"] = newNativeProc(listNew)

iterator items*(self: List): Object =
  ## Iterate over a Lists items.
  for item in self.items:
    yield item

proc len*(self: List): int =
  ## Return the number of items in a List
  self.items.len

proc listLen*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Integer }
  ## Return number of Objects in List.
  stack.append(newInteger(List(self).items.len))

base_objects.base_list.slots["len"] = newNativeProc(listLen)

proc append*(self: var List, item: Object) =
  ## Append an item to a List.
  self.items.add(item)

proc listAppend*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object List-self -- }
  ## Append object to the end of List.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object]])
  except ParameterError as error:
    raise newError[ListError](fmt"append - {error.msg}")

  List(self).items.add(stack.pop)

base_objects.base_list.slots["append"] = newNativeProc(listAppend)

proc pop*(self: var List): Object =
  ## Pop the last item from the List.
  if self.items.len < 1:
    raise newError[EmptyListError]("")
  result = self.items.pop()

proc listPop*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Pop the last item from the List.
  if List(self).items.len < 1:
    raise newError[EmptyListError]("")
  stack.append(List(self).items.pop)

base_objects.base_list.slots["pop"] = newNativeProc(listPop)

proc first*(self: List):Object =
  ## Return the first item of a List.
  try:
    result = self.items[0]
  except IndexDefect:
    raise newError[EmptyListError]("")

proc listFirst*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Return the first Object from a List.
  try:
    stack.append(List(self).items[0])
  except IndexDefect:
    raise newError[EmptyListError]("")

base_objects.base_list.slots["first"] = newNativeProc(listFirst)

proc last*(self: List): Object =
  ## Return the last item of a List.
  try:
    result = self.items[^1]
  except IndexDefect:
    raise newError[EmptyListError]("")

proc listLast*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Return the last Object from a List.
  try:
    stack.append(List(self).items[^1])
  except IndexDefect:
    raise newError[EmptyListError]("")

base_objects.base_list.slots["last"] = newNativeProc(listLast)

proc butFirst*(self: List): Object =
  ## Return a List with everything but the first entry of the given list.
  result = newList(self.slots[objectSlotParent], self.items[1 .. ^1])

proc listButFirst*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- List }
  ## Return a List with everything but the first entry of the given list.
  var the_list = List(self)
  stack.append(the_list.butFirst)

base_objects.base_list.slots["butfirst"] = newNativeProc(listButFirst)

proc listAt*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer List-self -- Object }
  ## Return the object a the given index in a List.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_Integer)]])
  except ParameterError as error:
    raise newError[ListError](fmt"at - {error.msg}")

  let index = Integer(stack.pop).value
  stack.append(List(self).items[index])

base_objects.base_list.slots["at"] = newNativeProc(listAt)

## Stacks
## A Stack is a List, but has a different set of methods.
## All Stack methods begin with a full stop.

proc newStack*(parent: Object): List =
  ## Create a new Stack inheriting from another Stack.
  result = new List
  result.class_name = stackName
  result.slots[objectSlotParent] = parent

base_objects.base_stack = newStack(base_objects.base_Object)
base_objects.global_object.slots[stackName] = base_objects.base_stack

proc newStack*(): List =
  ## Create a new Stack with base_stack as it's parent.
  result = newStack(base_objects.base_stack)

proc stackDrop*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object (Stack-self) -- }
  ## Drop the top of Stack.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object]])
  except ParameterError as error:
    raise newError[StackError](fmt".drop - {error.msg}")

  var self_stack = List(self)
  discard self_stack.pop

base_objects.base_stack.slots[".drop"] = newNativeProc(stackDrop)

proc stackDup*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object (Stack-self) -- Object Object }
  ## Duplicate the top of Stack.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object]])
  except ParameterError as error:
    raise newError[StackError](fmt".dup - {error.msg}")

  var self_stack = List(self)
  self_stack.append(self_stack.last)

base_objects.base_stack.slots[".dup"] = newNativeProc(stackDup)

proc stackSwap*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-1 Object-2 (Stack-self) -- Object-2 Object-1 }
  ## Swap the top two Objects of a Stack.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object, base_objects.base_object]])
  except ParameterError as error:
    raise newError[StackError](fmt".swap - {error.msg}")

  var self_stack = List(self)
  let
    first = self_stack.pop
    second = self_stack.pop

  self_stack.append(first)
  self_stack.append(second)

base_objects.base_stack.slots[".swap"] = newNativeProc(stackSwap)

proc stackOver*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-1 Object-2 (Stack-self) -- Object-1 Object-2 Object-1 }
  ## Duplicate the second Object on a Stack and att it to the top of Stack.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object, base_objects.base_object]])
  except ParameterError as error:
    raise newError[StackError](fmt".over - {error.msg}")

  var self_stack = List(self)
  let
    obj = stack.items[^2]

  self_stack.append(obj)

base_objects.base_stack.slots[".over"] = newNativeProc(stackOver)

proc stackRot*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-1 Object-2 Object-3 (Stack-self) -- Object-2 Object-3 Object-1 }
  ## Move the third item on a Stack to top of Stack.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object, base_objects.base_object, base_objects.base_object]])
  except ParameterError as error:
    raise newError[StackError](fmt".rot - {error.msg}")

  var self_stack = List(self)
  let
    obj = self_stack.items[^3]

  self_stack.items[^3] = self_stack.items[^2]
  self_stack.items[^2] = self_stack.items[^1]
  self_stack.items[^1] = obj

base_objects.base_stack.slots[".rot"] = newNativeProc(stackRot)

## Scope

proc newScope*(parent: Object): Object =
  ## Create a new scope Object, linked to an outer scope.
  result = newObject(parent)
  result.slots[localObjectName] = result

proc newScope*(): Object =
  ## Create a new scope Object.
  result = newScope(base_objects.base_object)
