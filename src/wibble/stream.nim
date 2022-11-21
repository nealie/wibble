## Wibble Stream.

import std/[strutils, tables]
import base

proc newAStream*(parent: Object): AStream =
  ## Create a new AStream.
  ## This is only used to create base_stream.
  result = new AStream
  result.class_name = aStreamName
  result.slots[objectSlotParent] = parent
  result.slots[streamName] = newString("")

base_objects.base_stream = newAStream(base_objects.base_object)
base_objects.global_object.slots[aStreamName] = base_objects.base_stream

abstractMethod(aStreamNew, "new", "create", aStreamName, base_stream)
abstractMethod(aStreamOpen, "open", "open", aStreamName, base_stream)
abstractMethod(aStreamClose, "close", "close", aStreamName, base_stream)
abstractMethod(aStreamAtEnd, "atEnd", "atEnd", aStreamName, base_stream)
abstractMethod(aStreamFlush, "flush", "flush", aStreamName, base_stream)
abstractMethod(aStreamGetPos, "getPos", "getPos", aStreamName, base_stream)
abstractMethod(aStreamSetPos, "setPos", "setPos", aStreamName, base_stream)
abstractMethod(aStreamReadChar, "readChar", "readChar", aStreamName, base_stream)
abstractMethod(aStreamReadString, "readString", "readString", aStreamName, base_stream)
abstractMethod(aStreamReadLine, "readLine", "readLine", aStreamName, base_stream)
abstractMethod(aStreamWrite, "write", "write", aStreamName, base_stream)
abstractMethod(aStreamWriteLine, "writeLine", "writeLine", aStreamName, base_stream)