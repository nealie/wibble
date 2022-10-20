# Package

version       = "0.1.0"
author        = "Neal Nelson"
description   = "The wibble language."
license       = "MIT"
srcDir        = "src"
bin           = @["wibble"]

backend       = "c"

# Dependencies

requires "nim >= 1.6.8"

# Build modules.

import std/[os, strformat, strutils]

before build:
  for file in listFiles("src/modules"):
    if file.endsWith(".nim"):
      let cmd = "nim {backend} -p:./src/wibble --app:lib --outdir:. {file}".fmt
      echo cmd
      exec cmd