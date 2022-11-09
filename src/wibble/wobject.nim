## Wibble base Object.

import std/[strformat, tables]
import base, list

proc objectNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- Object }
  ## Create a new Object.
  stack.append(newObject(self))

base_objects.base_object.slots["new"] = newNativeProc(objectNew)

proc objectToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- String }
  ## Return a string representation of an Object.
  var result = "<{$self.class_name}: ref {cast[int](self):#x}>".fmt
  stack.append(newString(result))

base_objects.base_object.slots[objectSlotStringify] = newNativeProc(objectToString)
base_objects.global_object.slots[objectSlotStringify] = base_objects.base_object.slots[objectSlotStringify]

base_objects.base_object.slots[objectSlotRepr] = base_objects.base_object.slots[objectSlotStringify]
base_objects.global_object.slots[objectSlotRepr] = base_objects.base_object.slots[objectSlotStringify]

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