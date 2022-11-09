## Wibble Stack.

import std/[strformat, tables]
import base, list

proc newStack*(parent: Object): List =
  ## Create a new Stack inheriting from another Stack.
  result = new List
  result.class_name = stackName
  result.slots[objectSlotParent] = parent

base_objects.base_stack = newStack(base_objects.base_Object)
base_objects.global_object.slots[stackName] = base_objects.base_stack

base_objects.base_stack.slots[objectSlotStringify] = newNativeProc(listToString)
base_objects.base_stack.slots[objectSlotRepr] = newNativeProc(listToString)

proc newStack*(): List =
  ## Create a new Stack with base_stack as it's parent.
  result = newStack(base_objects.base_stack)

# Stack methods.

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