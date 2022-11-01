## Wibble executor.

import std/[strutils, strformat, streams, tables, os, dynlib]
import core, parser #, thread

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
    when debug: echo ">> " & to_string(stack, scope, item)
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
              when debug: echo "* Add from stack to stack"
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
            when debug: echo "* " & to_repr(stack, scope, tos)
            let obj = tos.get_slot(item_symbol.value)
            if obj.isNil:
              when debug: echo("* No slot in TOS")
            else:
              discard stack.pop
              if obj.callable:
                when debug: echo "* Callable on TOS"
                Proc(obj).call(stack, scope, tos, Proc(obj))
              else:
                when debug: echo "* Add from TOS to stack"
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
                when debug: echo "* Add from local to stack"
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
                when debug: echo "* Add from global to stack"
                stack.append(obj)
              done = true
        except CoreError as error:
          echo(error.msg)
          break

# List

proc listExecCode*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- }
  ## Execute a List in the current scope.
  ## You probably want to be using do instead as this will leave side effects.
  exec(stack, scope, List(self))

base_objects.base_list.slots["exec"] = newNativeProc(listExecCode)

proc listDoCode*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-self -- }
  ## Execute a List in a new scope scope.
  var do_scope = newScope(scope)
  exec(stack, do_scope, List(self))

base_objects.base_list.slots["do"] = newNativeProc(listDoCode)

proc listWhile*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List List-self -- }
  ## The first list is executed in a new scope and List-self is executed in the same scope
  ## if there is a true on TOS. This repeats until there is a false on TOS.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_list)]])
  except ParameterError as error:
    raise newError[ListError](fmt"while - {error.msg}")

  let
    exec_list = List(self)
    guard_list = List(stack.pop)
  var exec_scope = newScope(scope)

  exec(stack, exec_scope, guard_list)

  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_boolean)]])
  except ParameterError as error:
    raise newError[ListError](fmt"while - guard produces error: {error.msg}")

  var guard_value = Boolean(stack.pop)
  while guard_value == base_objects.base_true:
    exec(stack, exec_scope, exec_list)
    exec(stack, exec_scope, guard_list)

    try:
      discard checkArgs(stack, scope, [@[Object(base_objects.base_boolean)]])
    except ParameterError as error:
      raise newError[ListError](fmt"while - guard produces error: {error.msg}")

    guard_value = Boolean(stack.pop)

base_objects.base_list.slots["while"] = newNativeProc(listWhile)

proc listFor*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List List-self -- }
  ## List-self is executed for each element for the previous List, which is put on the stack.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_list)]])
  except ParameterError as error:
    raise newError[ListError](fmt"for - {error.msg}")

  let
    exec_list = List(self)
    value_list = List(stack.pop)
  var exec_scope = newScope(scope)

  for obj in value_list:
    stack.append(obj)
    exec(stack, exec_scope, exec_list)

base_objects.base_list.slots["for"] = newNativeProc(listFor)

# Integer

proc integerFor*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List Integer Integer-self / List Integer-self -- }
  ## Iterate either from the first Integer to the second Integer, or from 1 to the Integer,
  ## putting the value onto the stack and calling the List. If the first Integer is greater
  ## than the second, the values decrement.
  var
    index_start = 1
    index_end = 0

  try:
    let param_index = checkArgs(stack, scope, [
      @[Object(base_objects.base_list), Object(base_objects.base_integer)],
      @[Object(base_objects.base_list)],
    ])

    if param_index == 0:
      index_start = Integer(stack.pop).value

  except ParameterError as error:
    raise newError[IntegerError](fmt"for - {error.msg}")

  index_end = Integer(self).value

  let exec_list = List(stack.pop)
  var exec_scope = newScope(scope)

  if index_start <= index_end:
    for index in index_start .. index_end:
      stack.append(newInteger(index))
      exec(stack, exec_scope, exec_list)
  else:
    for index in countdown(index_start, index_end):
      stack.append(newInteger(index))
      exec(stack, exec_scope, exec_list)

base_objects.base_integer.slots["for"] = newNativeProc(integerFor)


# String

const
  fileExt = "wib"
  libExt = "so"
  libPrefix = "lib"
  initName* = "init"

type
  InitProc* = proc(base_objs: var BaseObjects, stack: var List, scope: var Object) {.gcsafe, stdcall.}

proc stringExecFile*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- }
  ## Read and execute code from a file using the current scope.
  try:
    let
      path = absolutePath(String(self).value).addFileExt(fileExt)
      stream = openFileStream(path)
      parsed_input = parse_data(stream)
    exec(stack, scope, parsed_input)
  except IOError as error:
    raise newError[ExecError](fmt"execFile - {error.msg}")

base_objects.base_string.slots["execFile"] = newNativeProc(stringExecFile)

proc importModule*(scope: var Object, module_name: string) =
  ## Import a module and save into current scope.
  ## If the module has already been imported, simply return that.
  try:
    let
      path = absolutePath(module_name)
      name = extractFilename(path)
    var modulesObj = base_objects.global_object.slots[modulesObjectName]

    if path in modulesObj.slots:
      # Don't re-import if we already have it.
      scope.slots[name] = modulesObj.slots[name]
    else:
      let full_path = path.addFileExt(fileExt)

      if full_path.fileExists():
        # Import wibble module.
        let
          stream = openFileStream(full_path)
          parsed_input = parse_data(stream)

        var
          exec_scope = newScope(scope)
          exec_stack = newStack()

        exec(exec_stack, exec_scope, parsed_input)

        modulesObj.slots[name] = exec_scope
        scope.slots[name] = exec_scope
      else:
        let
          (dir, _) = path.splitPath()
          lib_path = (dir / libPrefix & name).addFileExt(libExt)
        if not lib_path.fileExists():
          raise newError[ExecError](fmt"import - Module {path} does not exist.")

        # Import library module.
        let lib = loadLib(lib_path)
        if lib.isNil:
          raise newError[ExecError](fmt"import - Unable to import module {path}.")

        var
          exec_scope = newScope(scope)
          exec_stack = newStack()

        let init = cast[InitProc](lib.symAddr(initName))

        if init.isNil:
          raise newError[ExecError](fmt"import - Can't find {initName} in {lib_path}")

        # Call library.
        echo "> base_objects: ref {cast[int](base_objects):#x}".fmt
        echo "> stack: ref {cast[int](exec_stack):#x}".fmt
        echo "> scope: ref {cast[int](exec_scope):#x}".fmt
        init(base_objects, exec_stack, exec_scope)

        modulesObj.slots[name] = exec_scope
        scope.slots[name] = exec_scope
  except IOError as error:
    raise newError[ExecError](fmt"import - {error.msg}")
  except OSError as error:
    raise newError[ExecError](fmt"import - {error.msg}")

proc stringImport*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String-self -- }
  ## Import a module and save into current scope.
  ## If the module has already been imported, simply return that.
  scope.importModule(String(self).value)

base_objects.base_string.slots["import"] = newNativeProc(stringImport)

# Symbol

proc symbolImport*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Symbol-self -- }
  ## Import a module and save into current scope.
  ## If the module has already been imported, simply return that.
  scope.importModule(Symbol(self).value)

base_objects.base_symbol.slots["import"] = newNativeProc(symbolImport)

# Boolean

proc booleanIf*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List Boolean -- }
  ## Execute List in a new scope if Boolean is true.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_list)]])
  except ParameterError as error:
    raise newError[BooleanError](fmt"if - {error.msg}")

  let code_block = List(stack.pop)
  if Boolean(self).value:
    var if_scope = newScope(scope)
    exec(stack, if_scope, code_block)

base_objects.base_boolean.slots["if"] = newNativeProc(booleanIf)

proc booleanIfElse*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List-1 List-2 Boolean -- }
  ## Execute List-1 if Boolean is true, else execute List-2. Execution is in a new scope.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_list), Object(base_objects.base_list)]])
  except ParameterError as error:
    raise newError[BooleanError](fmt"ifelse - {error.msg}")

  let
    false_code_block = List(stack.pop)
    true_code_block = List(stack.pop)

  var if_scope = newScope(scope)

  if Boolean(self).value:
    exec(stack, if_scope, true_code_block)
  else:
    exec(stack, if_scope, false_code_block)

base_objects.base_boolean.slots["ifelse"] = newNativeProc(booleanIfElse)

# Proc

proc procExec*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## Execute the Proc stored in List-self.
  let
    exec_args = List(proc_def.slots[procSlotArgs])
    exec_returns = List(proc_def.slots[procSlotReturn])
  var
    exec_scope = newScope(proc_def.slots[procSlotScope])
    exec_stack = newStack()
    index = exec_args.len - 1

  # Populate the arguments.
  while index >= 0:
    let
      param_spec = List(exec_args.items[index])
      name = Symbol(param_spec.items[0]).value
      kind = param_spec.items[1]
      tos = stack.pop

    if not objectIsA(tos, kind):
      raise newError[ProcExecError](fmt"Invalid parameter type, expected: {to_repr(stack, scope, exec_args)}.")

    exec_scope.slots[name] = tos
    index.dec

  # Create the return slots.
  for ret_def in exec_returns:
    let
      return_def = List(ret_def)
      name = Symbol(return_def.items[0]).value

    exec_scope.slots[name] = base_objects.base_nil

  exec(exec_stack, exec_scope, List(proc_def.slots[procSlotCode]))

  # Place return value onto stack.
  for ret_def in exec_returns:
    let
      return_def = List(ret_def)
      name = Symbol(return_def.items[0]).value
      kind = return_def.items[1]
      return_value = exec_scope.slots[name]

    if not objectIsA(return_value, kind):
      raise newError[ProcExecError](fmt"Invalid return type, expected: {name} {kind.class_name}.")

    stack.append(return_value)

  # Ensure that there is nothing left on the stack.
  if exec_stack.len > 0:
    var name: string
    if procName in proc_def.slots:
      name = Symbol(proc_def.slots[procName]).value
    else:
      name = "anonymous"
    raise newError[ProcExecError](fmt"After executing proc {name}, stack still contains {exec_stack.len} objects.")

proc newBaseProc(): Proc =
  ## Create a new base_proc.
  result = new Proc
  result.class_name = procName
  result.call = nil
  result.slots[objectSlotParent] = base_objects.base_object
  result.slots[objectSlotCall] = result
  result.slots[procSlotArgs] = base_objects.base_nil
  result.slots[procSlotReturn] = base_objects.base_nil
  result.slots[procSlotCode] = base_objects.base_nil
  result.slots[procSlotScope] = base_objects.base_nil

base_objects.base_proc = newBaseProc()
base_objects.global_object.slots[procName] = base_objects.base_proc

proc doProc*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { ... Proc-self -- ... }
  ## Call a Proc directly.
  Proc(self).call(stack, scope, self, Proc(self))

base_objects.base_proc.slots["do"] = newNativeProc(doProc)


proc newProc*(scope: Object, arguments: List, returns: List, the_proc: List): Proc =
  ## Create a new Proc.
  result = new Proc
  result.class_name = procName
  result.call = procExec
  result.slots[objectSlotParent] = base_objects.base_proc
  result.slots[objectSlotCall] = result
  result.slots[procSlotArgs] = arguments
  result.slots[procSlotReturn] = returns
  result.slots[procSlotCode] = the_proc
  result.slots[procSlotScope] = scope

proc procNew*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List Object-self -- }
  ## Generate a Proc. The List must be of the following format:
  ## [ <parameters> <return values> <code> ]
  ## <parameters> and <return values> are Lists of name type pairs.

  var the_spec = List(self)

  if the_spec.items.len < 3:
    # There needs to be a parameter list, return list and at least one operation.
    raise newError[ProcError](fmt"Invalid proc definition: {to_repr(stack, scope, the_spec)}.")

  let
    params = the_spec.items[0]
    returns = the_spec.items[1]
    code = newList(the_spec.items[2 .. ^1])

  if not(params of List):
    raise newError[ProcError]("The second element of a proc definition must be a List.")

  let param_list = List(params)

  if param_list.len mod 2 != 0:
    # There must always been an even number of items in the parameter list.
    raise newError[ProcError]("Invalid proc parameter specification.")

  var
    param_spec: seq[Object]
    index = 0

  while index < param_list.len:
    let
      first = param_list.items[index]
      second = param_list.items[index + 1]

    if not(first of Symbol):
      raise newError[ProcError]("The first element of a proc parameter specification must be a Symbol.")

    var second_kind: Object

    if second of Symbol:
      second_kind = scope.get_slot(Symbol(second).value)
      if second_kind.isNil:
        second_kind = base_objects.global_object.get_slot(Symbol(second).value)
        if second_kind.isNil:
          raise newError[ProcError](fmt"Can't find {Symbol(second).value} in proc parameter specification.")
    else:
      # Since we don't have a Symbol, we must assume that it's a reference Object.
      second_kind = second

    let param_def = newList(@[first, second_kind])
    param_spec.add(param_def)
    index += 2

  let return_list = List(returns)

  if return_list.len mod 2 != 0:
    # There must always been an even number of items in the return list.
    raise newError[ProcError]("Invalid proc return specification.")

  var return_spec: seq[Object]

  index = 0

  while index < return_list.len:
    let
      first = return_list.items[index]
      second = return_list.items[index + 1]

    if not(first of Symbol):
      raise newError[ProcError]("The first element of a proc return specification must be a Symbol.")

    var second_kind: Object

    if second of Symbol:
      second_kind = scope.get_slot(Symbol(second).value)
      if second_kind.isNil:
        second_kind = base_objects.global_object.get_slot(Symbol(second).value)
        if second_kind.isNil:
          raise newError[ProcError](fmt"Can't find {Symbol(second).value} in proc return specification.")
    else:
      # Since we don't have a Symbol, we must assume that it's a reference Object.
      second_kind = second

    let return_def = newList(@[first, second_kind])
    return_spec.add(return_def)
    index += 2

  stack.append(newProc(scope, newList(param_spec), newList(return_spec), code))

base_objects.base_list.slots["proc"] = newNativeProc(procNew)

proc procDef*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { List Symbol Object-self -- }
  ## Define a procedure and store it in an Object.
  try:
    discard checkArgs(stack, scope, [@[Object(base_objects.base_list), Object(base_objects.base_symbol)]])
  except ParameterError as error:
    raise newError[ProcError](fmt"def - {error.msg}")

  let
    name = Symbol(stack.pop)
    proc_list = stack.pop

  procNew(stack, scope, proc_list, proc_def)

  let the_proc = stack.pop
  the_proc.slots[procSlotName] = name

  self.slots[name.value] = the_proc

base_objects.base_object.slots["def"] = newNativeProc(procDef)
base_objects.global_object.slots["def"] = base_objects.base_object.slots["def"]