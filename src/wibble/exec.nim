## Wibble executor.

import std/[strutils, strformat]
import core

const debug = false

type
  ExecError* = ref object of CoreError

proc exec*(stack: var List, scope: var Object, expr: List) =
  ## Execute an expression given a stack.
  ##
  ## The following are simply added to the stack:
  ##   - Number
  ##   - String
  ##   - List
  ##   - 'Symbol
  ##
  ## Everything else should be a symbol.
  ##
  ## Symbols beginning with "." are applied to the stack, otherwise the appropriate
  ## slot will be looked up the the following order:
  ##
  ## - If there is an Object on the stack, look there.
  ## - Within the scope Object.
  ## - In global.
  ##
  ## If the result is callable, it is called, otherwise it is placed on the stack.
  
  for item in expr:
    when debug: echo ">> " & $item
    # Some Objects are just put on the stack.
    if item of base_objects.base_number.type or
      item of base_objects.base_string.type or
      item of base_objects.base_list.type:
      stack.append(item)
    else:
      # We have a Symbol.
      let item_symbol = Symbol(item)

      if item_symbol.value.startsWith("'"):
        # Quote: Literal Symbol.
        item_symbol.value = item_symbol.value[1 .. ^1]
        stack.append(item_symbol)
      elif item_symbol.value.startsWith("."):
        # Dot: Stack method.
        try:
          let obj = stack.get_slot(item_symbol.value)
          if obj.isNil:
            raise newError[ExecError]("{item_symbol.value} not found.".fmt)
          else:
            # Is it callable?
            if obj.callable:
              when debug: echo "* Callable on stack"
              Proc(obj).call(stack, scope, stack, Proc(obj))
            else:
              when debug: echo "* Add to stack"
              stack.append(obj)
        except CoreError as error:
          echo(error.msg)
          break
      else:
        try:
          var done = false
          if stack.len > 0:
            # Look for a slot in the TOS chain.
            let tos = stack.last
            when debug: echo "* " & $tos
            let obj = tos.get_slot(item_symbol.value)
            #if obj.isNil or obj == stack:
            if obj.isNil:
              when debug: echo("* No slot in TOS")
            else:
              discard stack.pop
              if obj.callable:
                when debug: echo "* Callable on TOS"
                #when debug: echo "** " & $stack
                Proc(obj).call(stack, scope, tos, Proc(obj))
                #when debug: echo "&& " & $stack
              else:
                when debug: echo "* Add to stack 1"
                stack.append(obj)
              done = true              
          if not done:
            # Look for a slot in the scope chain.
            let obj = scope.get_slot(item_symbol.value)
            if not obj.isNil:
              # Is it callable?
              if obj.callable:
                when debug: echo "* Callable on local"
                Proc(obj).call(stack, scope, scope, Proc(obj))
              else:
                when debug: echo "* Add to stack 2"
                stack.append(obj)
              done = true
          if not done:
            # Look for a slot in global.
            let obj = base_objects.global_object.get_slot(item_symbol.value)
            if obj.isNil:
              raise newError[ExecError]("{item_symbol.value} not found.".fmt)
            else:
              # Is it callable?
              if obj.callable:
                when debug: echo "* Callable on Object"
                Proc(obj).call(stack, scope, base_objects.global_object, Proc(obj))
              else:
                when debug: echo "* Add to stack 2"
                stack.append(obj)
              done = true
        except CoreError as error:
          echo(error.msg)
          break