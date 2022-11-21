## Wibble FileStream.

import std/[streams, strformat, tables]
import base, list

proc newAFileStream*(parent: Object, from_stream: FileStream, filename: string): AFileStream =
  ## Create a new AFile from a File, given a parent Object.
  result = new AFileStream
  result.class_name = aFileStreamName
  result.slots[objectSlotParent] = parent
  result.slots[streamName] = newString(filename)
  result.stream = from_stream

base_objects.base_file_stream = newAFileStream(base_objects.base_stream, nil, "")
base_objects.global_object.slots[aFileStreamName] = base_objects.base_file_stream

base_objects.stdin = newAFileStream(base_objects.base_object, newFileStream(stdin), streamStdIn)
base_objects.global_object.slots[streamStdIn] = base_objects.stdin
base_objects.stdout = newAFileStream(base_objects.base_object, newFileStream(stdout), streamStdOut)
base_objects.global_object.slots[streamStdOut] = base_objects.stdout
base_objects.stderr = newAFileStream(base_objects.base_object, newFileStream(stderr), streamStdErr)
base_objects.global_object.slots[streamStdErr] = base_objects.stderr

proc fileStreamOpen*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String Symbol FileStream-self -- FileStream }
  ## Open a FileStream from the given filename String, with the mode Symbol.
  var
    filename: string
    mode: FileMode

  try:
    let index = checkArgs(stack, scope, [
      @[Object(base_objects.base_string), Object(base_objects.base_symbol)],
      @[Object(base_objects.base_string)]
    ])
    if index == 0:
      let mode_sym = Symbol(stack.pop).value
      case mode_sym:
        of "read", "r": mode = fmRead
        of "write", "w": mode = fmWrite
        of "readWriteCreate", "rwc": mode = fmReadWrite
        of "readWrite", "rw": mode = fmReadWriteExisting
        of "append", "a": mode = fmAppend
        else:
          raise newError[FileStreamError](fmt"open - mode '{mode_sym}' not valid.")
    else:
      mode = fmRead

    filename = String(stack.pop).value
  except ParameterError as error:
    raise newError[FileStreamError](fmt"open - {error.msg}")

  try:
    var
      stream = openFileStream(filename, mode)
      result = new AFileStream
    result.class_name = aFileStreamName
    result.slots[objectSlotParent] = base_objects.base_file_stream
    result.slots[streamName] = newString(filename)
    result.stream = stream
    stack.append(result)
  except IOError as error:
    raise newError[FileStreamError](fmt"open - {error.msg}")

base_objects.base_file_stream.slots["open"] = newNativeProc(fileStreamOpen)

proc fileStreamClose*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { FileStream-self -- }
  ## Close a FileStream.
  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"close - FileStream already closed")
  file.stream.close()
  file.stream = nil

base_objects.base_file_stream.slots["close"] = newNativeProc(fileStreamClose)

proc fileStreamAtEnd*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { FileStream-self -- Boolean }
  ## Determine whether a FileStream is at it's end.
  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"atEnd - FileStream closed")
  stack.append(toBoolean(file.stream.atEnd()))

base_objects.base_file_stream.slots["atEnd"] = newNativeProc(fileStreamAtEnd)

proc fileStreamFlush*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { FileStream-self -- }
  ## Flush a FileStream.
  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"flush - FileStream closed")
  file.stream.flush()

base_objects.base_file_stream.slots["flush"] = newNativeProc(fileStreamFlush)

proc fileStreamGetPos*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { FileStream-self -- Integer }
  ## Get position within a FileStream.
  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"getPos - FileStream closed")
  stack.append(newInteger(file.stream.getPosition()))

base_objects.base_file_stream.slots["getPos"] = newNativeProc(fileStreamGetPos)

proc fileStreamSetPos*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer FileStream-self -- }
  ## Set position within a FileStream.
  try:
    checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[FileStreamError](fmt"setPos - {error.msg}")

  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"setPos - FileStream closed")

  file.stream.setPosition(Integer(stack.pop).value)

base_objects.base_file_stream.slots["setPos"] = newNativeProc(fileStreamSetPos)

# proc fileStreamReadChar*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
#   ## { FileStream-self -- String }
#   ## Read a character from a FileStream.
#   let file = AFileStream(self)
#   if file.stream.isNil:
#     raise newError[FileStreamError](fmt"readChar - FileStream closed")
#   stack.append(newString(file.stream.readChar()))

# base_objects.base_file_stream.slots["readChar"] = newNativeProc(fileStreamReadChar)

proc fileStreamReadString*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { Integer FileStream-self -- String }
  ## Read a String of a given length from a FileStream.
  try:
    checkArgs(stack, scope, [@[Object(base_objects.base_integer)]])
  except ParameterError as error:
    raise newError[FileStreamError](fmt"readString - {error.msg}")

  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"readString - FileStream closed")

  let
    length = Integer(stack.pop).value
    result = file.stream.readStr(length)
  
  stack.append(newString(result))

base_objects.base_file_stream.slots["readString"] = newNativeProc(fileStreamReadString)

proc fileStreamReadLine*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { FileStream-self -- String }
  ## Read a line from a FileStream.
  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"readLine - FileStream closed")

  var result: string
  let not_eof = file.stream.readLine(result)
  if not not_eof:
    raise newError[FileStreamError](fmt"readLine - at EOF")
  
  stack.append(newString(result))

base_objects.base_file_stream.slots["readLine"] = newNativeProc(fileStreamReadLine)

proc fileStreamWrite*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String FileStream-self -- String }
  ## Write a String to a FileStream.
  try:
    checkArgs(stack, scope, [@[Object(base_objects.base_string)]])
  except ParameterError as error:
    raise newError[FileStreamError](fmt"write - {error.msg}")

  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"write - FileStream closed")

  file.stream.write(String(stack.pop).value)

base_objects.base_file_stream.slots["write"] = newNativeProc(fileStreamWrite)

proc fileStreamWriteLine*(stack: var List, scope: var Object, self: Object, proc_def: Proc) =
  ## { String FileStream-self -- String }
  ## Write a String to a FileStream followed by a newline.
  try:
    checkArgs(stack, scope, [@[Object(base_objects.base_string)]])
  except ParameterError as error:
    raise newError[FileStreamError](fmt"writeLine - {error.msg}")

  let file = AFileStream(self)
  if file.stream.isNil:
    raise newError[FileStreamError](fmt"writeLine - FileStream closed")

  file.stream.writeLine(String(stack.pop).value)

base_objects.base_file_stream.slots["writeLine"] = newNativeProc(fileStreamWriteLine)