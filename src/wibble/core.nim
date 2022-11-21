## Wibble core objects.

import std/[strutils, strformat, tables]

import base
export base

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

import list
export list

proc to_string*(stack: var List, scope: var Object, self: Object): string =
  call_slot(stack, scope, self, objectSlotStringify)
  result = String(stack.pop).value

proc to_repr*(stack: var List, scope: var Object, self: Object): string =
  call_slot(stack, scope, self, objectSlotRepr)
  result = String(stack.pop).value

import wobject
export wobject

proc nilNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Object-self -- Object-self }
  ## Nil is a singleton, so return it.
  stack.append(self)

base_objects.base_nil.slots["new"] = newNativeProc(nilNew)

## Scope

proc newScope*(parent: Object): Object =
  ## Create a new scope Object, linked to an outer scope.
  result = newObject(parent)
  result.slots[localObjectName] = result

proc newScope*(): Object =
  ## Create a new scope Object.
  result = newScope(base_objects.base_object)

import symbol
export symbol

import string
export string

abstractMethod(numberNew, "new", "create", "Number", base_number)

import integer
export integer

import float
export float

import boolean
export boolean

import stack
export stack

import stream
export stream

import filestream
export filestream