## Wibble base types.

import std/[strformat, tables]

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
  objectSlotCall* = "_call"
  objectSlotStringify* = "$"
  objectSlotRepr* = "repr"
  procSlotArgs* = "arguments"
  procSlotReturn* = "returns"
  procSlotScope* = "scope"
  procSlotName* = "name"
  procSlotCode* = "code"
  globalObjectName* = "global"
  localObjectName* = "local"
  modulesObjectName* = "modules"
  trueObjectName* = "true"
  falseObjectName* = "false"
  selfReferentialSlots* = [globalObjectName, localObjectName]

type
  Object* {.inheritable.} = ref object
    ## Basic Object.
    class_name*: string             ## Natively implemented Objects have special names.
    slots*: Table[string, Object]   ## All Object values go into a slot.

  # Nil* = ref object of Object
  #   ## Singleton Nil Object.

  ProcSig* = proc(stack: var List, scope: var Object, self: Object, proc_def: Proc)
    ## Call signature.

  Proc* = ref object of Object
    ## Procedure.
    call*: ProcSig                  ## Callable proc.

  NativeProc* = ref object of Proc
    ## Native Procedure.

  Symbol* = ref object of Object
    ## Symbolic value.
    value*: string

  String* = ref object of Symbol
    ## String value.
    #value*: string

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

  BaseObjects* = ref object
    ## Collection of all base objects.
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
  base_objects* = new BaseObjects    ## Base of the Object hierarchy.

# Object creation.

proc newError*[T](msg: string): T =
  ## Create a new CoreError concrete type with added message.
  result = new T
  result.msg = "{$T.type}: {msg}".fmt

proc newNativeProc*(the_proc: ProcSig): NativeProc =
  ## Create a callable NativeProc from a nim proc.
  result = new NativeProc
  result.class_name = nativeProcName
  result.call = the_proc
  result.slots[objectSlotCall] = result

proc newObject*(parent: Object): Object =
  ## Create a new Object, inheriting from a parent Object.
  result = new Object
  result.class_name = objectName
  result.slots[objectSlotParent] = parent

proc newObject*(): Object =
  ## Create a new Object, inheriting from the base_object.
  result = newObject(base_objects.base_object)

proc newSymbol*(parent: Object, value: string): Symbol =
  ## Create a new Symbol.
  result = new Symbol
  result.class_name = symbolName
  result.slots[objectSlotParent] = parent
  result.value = value

proc newSymbol*(value: string): Symbol =
  ## Create a new Symbol, inheriting from base_symbol.
  result = newSymbol(base_objects.base_symbol, value)

proc newString*(parent: Object, value: string): String =
  result = new String
  result.class_name = stringName
  result.slots[objectSlotParent] = parent
  result.value = value

proc newString*(value: string): String =
  ## Create a new String.
  result = newString(base_objects.base_string, value)

proc newNumber*(parent: Object): Number =
  ## Create a new Number.
  ## This is only used to create base_number.
  result = new Number
  result.class_name = numberName
  result.slots[objectSlotParent] = parent

proc newInteger*(parent: Object): Integer =
  ## Create a new Integer, given a parent Object.
  result = new Integer
  result.class_name = integerName
  result.slots[objectSlotParent] = parent

proc newInteger*(value: int): Integer =
  ## Create a new Integer with base_integer as it's parent.
  result = newInteger(base_objects.base_integer)
  result.value = value

proc newFloat*(parent: Object, value: float): Float =
  ## Create a new Float, given a parent and value.
  result = new Float
  result.class_name = floatName
  result.slots[objectSlotParent] = parent
  result.value = value

proc newFloat*(value: float): Float =
  ## Create a new Float with base_float as it's parent.
  result = newFloat(base_objects.base_float, value)

proc newBoolean*(parent: Object, value: bool): Boolean =
  ## Create a new Boolean.
  result = new Boolean
  result.class_name = booleanName
  result.slots[objectSlotParent] = parent
  result.value = value

proc newList*(parent: Object): List =
  ## Create a new empty List.
  result = new List
  result.class_name = listName
  result.slots[objectSlotParent] = parent

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

# Instantiation.

base_objects.global_object = newObject(nil)
base_objects.global_object.slots[globalObjectName] = base_objects.global_object

base_objects.base_object = newObject(nil)
base_objects.global_object.slots[objectName] = base_objects.base_object

# Create Nil singleton.
base_objects.base_nil = newObject(base_objects.base_object)
base_objects.base_nil.class_name = nilName
base_objects.global_object.slots[nilName] = base_objects.base_nil

# Create base Number.
base_objects.base_number = newNumber(base_objects.base_object)
base_objects.global_object.slots[numberName] = base_objects.base_number

# Create modules Object.
base_objects.global_object.slots[modulesObjectName] = newObject(base_objects.base_object)

# Object internals.

proc get_slot*(self: Object, slot: string): Object =
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

proc callable*(self: Object): bool =
  ## Determine whether an Object is callable.
  result = objectSlotCall in self.slots

proc call_slot*(stack: var List, scope: var Object, self: Object, slot: string) =
  ## Call a callable slot on an Object.
  let obj = self.get_slot(slot)
  if obj.isNil:
    raise newError[ObjectError](fmt"call_slot - Slot {slot} not found.")

  # Is it callable?
  if obj.callable:
    Proc(obj).call(stack, scope, self, Proc(obj))
  else:
    raise newError[ObjectError](fmt"call_slot - Slot {slot} not callable.")

proc objectIsA*(a, b: Object): bool =
  ## Determine whether Object a is a b.
  result = false
  if a == b:
    return true
  var parent = a.slots[objectSlotParent]
  while not(parent.isNil):
    if parent == b:
      return true
    parent = parent.slots[objectSlotParent]

proc toBoolean*(value: bool): Boolean =
  ## Convert a bool to Boolean.
  if value:
    result = base_objects.base_true
  else:
    result = base_objects.base_false