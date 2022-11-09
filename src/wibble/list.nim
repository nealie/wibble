## Wibble List.

import std/[strformat, strutils, sugar, tables]
import base

base_objects.base_list = newList(base_objects.base_object)
base_objects.global_object.slots[listName] = base_objects.base_list

proc append*(self: var List, item: Object) =
  ## Append an item to a List.
  self.items.add(item)

iterator items*(self: List): Object =
  ## Iterate over a Lists items.
  for item in self.items:
    yield item

proc pop*(self: var List): Object =
  ## Pop the last item from the List.
  if self.items.len < 1:
    raise newError[EmptyListError]("")
  result = self.items.pop()

proc len*(self: List): int =
  ## Return the number of items in a List
  self.items.len

proc first*(self: List):Object =
  ## Return the first item of a List.
  try:
    result = self.items[0]
  except IndexDefect:
    raise newError[EmptyListError]("")

proc last*(self: List): Object =
  ## Return the last item of a List.
  try:
    result = self.items[^1]
  except IndexDefect:
    raise newError[EmptyListError]("")

proc butFirst*(self: List): Object =
  ## Return a List with everything but the first entry of the given list.
  result = newList(self.slots[objectSlotParent], self.items[1 .. ^1])

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

# List methods.

proc listNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- List }
  ## Create new empty List.
  stack.append(newList(self))

base_objects.base_list.slots["new"] = newNativeProc(listNew)

proc listToString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- String }
  ## Convert the value of a List to a String.
  var result = "["
  var separator = ""

  for value in List(self).items:
    if value == self:
      result.add("{separator}<{$value.class_name} ref {cast[int](value):#x}>".fmt)
      if separator == "":
        separator = " "
    else:
      # Call Object's stringify.
      call_slot(stack, scope, value, objectSlotRepr)
      let value_string = String(stack.pop).value
      result.add("{separator}{value_string}".fmt)
      if separator == "":
        separator = " "

  result.add("]")
  stack.append(newString(result))

base_objects.base_list.slots[objectSlotStringify] = newNativeProc(listToString)
base_objects.base_list.slots[objectSlotRepr] = newNativeProc(listToString)

proc listLen*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Integer }
  ## Return number of Objects in List.
  stack.append(newInteger(List(self).items.len))

base_objects.base_list.slots["len"] = newNativeProc(listLen)

proc listAppend*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object List-self -- }
  ## Append object to the end of List.
  try:
    discard checkArgs(stack, scope, [@[base_objects.base_object]])
  except ParameterError as error:
    raise newError[ListError](fmt"append - {error.msg}")

  List(self).items.add(stack.pop)

base_objects.base_list.slots["append"] = newNativeProc(listAppend)

proc listPop*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Pop the last item from the List.
  if List(self).items.len < 1:
    raise newError[EmptyListError]("")
  stack.append(List(self).items.pop)

base_objects.base_list.slots["pop"] = newNativeProc(listPop)

proc listFirst*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Return the first Object from a List.
  try:
    stack.append(List(self).items[0])
  except IndexDefect:
    raise newError[EmptyListError]("")

base_objects.base_list.slots["first"] = newNativeProc(listFirst)

proc listLast*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- Object }
  ## Return the last Object from a List.
  try:
    stack.append(List(self).items[^1])
  except IndexDefect:
    raise newError[EmptyListError]("")

base_objects.base_list.slots["last"] = newNativeProc(listLast)

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