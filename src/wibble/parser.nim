## Wibble parser.

import std/[lexbase, streams, strformat, strutils, parseutils]
import core

const
  whitespace = {' ', '\t', ','}
  eof = '\0'
  quotes = '"'
  list_start = '['
  list_end = ']'
  inline_comment_start = '#'
  block_comment_start = '{'
  block_comment_end = '}'
  line_feed = '\l'
  carriage_return = '\c'

type
  TokenKind {.pure.} = enum
    EOF
    list_start
    list_end
    symbol
    string
    integer
    float
    comment

  Token = ref object
    case kind: TokenKind
      of TokenKind.symbol: symbol_value: string
      of TokenKind.string: str_value: string
      of TokenKind.integer: int_value: int
      of TokenKind.float: float_value: float
      of TokenKind.comment: comment: string
      else: discard # Nothing else carries a value.

  ParserError* = ref object of CatchableError

# proc `$`(token: Token):string =
#   case token.kind
#     of TokenKind.EOF:
#       result = "EOF"
#     of TokenKind.list_start:
#       result = "List_start ["
#     of TokenKind.list_end:
#       result = "] List_end"
#     of TokenKind.symbol:
#       result = "Symbol: <$#>" % token.symbol_value
#     of TokenKind.string:
#       result = "String: <$#>" % token.str_value
#     of TokenKind.integer:
#       result = "Int: $#" % $token.int_value
#     of TokenKind.float:
#       #result = "Float: $#" % formatFloat(token.float_value, precision = -1)
#       result = "Float: $#" % $token.float_value
#     of TokenKind.comment:
#       result = "Comment <$#>" % token.comment

type
  UnexpectedEndOfStringError* = ref object of ParserError

  UnrecognisedEscapeStringError* = ref object of ParserError

  InvalidNumberError* = ref object of ParserError

  UnexpectedBlockCommentEndError* = ref object of ParserError

proc newParserError[T](line, column: int): T =
  ## Create a new ParserError concrete type with added line and column data.
  result = new T
  result.msg = "{$T.type} at line {line}, column {column}".fmt

proc handle_eol(lexer: var BaseLexer, eol_char: char) =
  ## Handle End of Line.
  if eol_char == line_feed:
    lexer.bufpos = lexer.handleLF(lexer.bufpos)
  else:
    lexer.bufpos = lexer.handleCR(lexer.bufpos)

proc lex_number(lexer: var BaseLexer): Token =
  ## Try to read the next token as a Number.
  var
    text = ""
    kind: TokenKind
    int_value: int
    float_value: float

  if lexer.buf[lexer.bufpos] == '0' and lexer.buf[lexer.bufpos+1] in {'x', 'X'}:
    # Hex number.
    inc(lexer.bufpos, 2)
    while lexer.buf[lexer.bufpos] in HexDigits:
      text.add(lexer.buf[lexer.bufpos])
      inc(lexer.bufpos)

    kind = TokenKind.integer
    int_value = parseHexInt(text)
  else:
    if lexer.buf[lexer.bufpos] in {'+', '-'}:
      text.add(lexer.buf[lexer.bufpos])
      inc(lexer.bufpos)

    if lexer.buf[lexer.bufpos] == '.':
      text.add("0.")
      inc(lexer.bufpos)
    else:
      while lexer.buf[lexer.bufpos] in Digits:
        text.add(lexer.buf[lexer.bufpos])
        inc(lexer.bufpos)
      if lexer.buf[lexer.bufpos] == '.':
        text.add('.')
        inc(lexer.bufpos)

    while lexer.buf[lexer.bufpos] in Digits:
      text.add(lexer.buf[lexer.bufpos])
      inc(lexer.bufpos)

    if lexer.buf[lexer.bufpos] in {'E', 'e'}:
      text.add(lexer.buf[lexer.bufpos])
      inc(lexer.bufpos)
      if lexer.buf[lexer.bufpos] in {'+', '-'}:
        text.add(lexer.buf[lexer.bufpos])
        inc(lexer.bufpos)
      while lexer.buf[lexer.bufpos] in Digits:
        text.add(lexer.buf[lexer.bufpos])
        inc(lexer.bufpos)

    if {'.', 'e', 'E'} in text:
      kind = TokenKind.float
      float_value = parseFloat(text)
    else:
      kind = TokenKind.integer
      int_value = parseInt(text)

  if lexer.buf[lexer.bufpos] notIn {' ', ',', ']', 't', ')', '\c', '\l', '\0'}:
    # Next character isn't a valid separator.
    raise newParserError[InvalidNumberError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))
  else:
    result = Token(kind: kind)
    #result.kind = kind
    if kind == TokenKind.integer:
      result.int_value = int_value
    else:
      result.float_value = float_value


proc next_token(lexer: var BaseLexer): Token =
  ## Get the next meaningful token.
  while true:
    # Skip whitespace, including commas.
    while lexer.buf[lexer.bufpos] in whitespace:
      inc(lexer.bufpos)

    let next_char = lexer.buf[lexer.bufpos]

    case next_char
      of eof:
        return Token(kind: TokenKind.EOF)
      of list_start:
        inc(lexer.bufpos)
        return Token(kind: TokenKind.list_start)
      of list_end:
        inc(lexer.bufpos)
        return Token(kind: TokenKind.list_end)
      of line_feed, carriage_return:
        lexer.handle_eol(next_char)
      of inline_comment_start:
        inc(lexer.bufpos)
        result = Token(kind: TokenKind.comment)
        result.comment = ""

        var comment_char = lexer.buf[lexer.bufpos]
        while comment_char notin {line_feed, carriage_return, eof}:
          result.comment &= comment_char
          inc(lexer.bufpos)
          comment_char = lexer.buf[lexer.bufpos]

        if comment_char != eof:
          lexer.handle_eol(comment_char)
        return result
      of block_comment_start:
        inc(lexer.bufpos)
        result = Token(kind: TokenKind.comment)
        result.comment = ""

        var comment_char = lexer.buf[lexer.bufpos]
        while comment_char notin {block_comment_end, eof}:
          result.comment &= comment_char
          if comment_char in {line_feed, carriage_return}:
            lexer.handle_eol(comment_char)
          else:
            inc(lexer.bufpos)
          comment_char = lexer.buf[lexer.bufpos]

        inc(lexer.bufpos)
        return result
      of block_comment_end:
        raise newParserError[UnexpectedBlockCommentEndError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))
      of quotes:
        inc(lexer.bufpos)
        result = Token(kind: TokenKind.string)
        result.str_value = ""

        var quote_char = lexer.buf[lexer.bufpos]
        while quote_char notin {quotes, eof}:
          if quote_char == eof:
            raise newParserError[UnexpectedEndOfStringError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))

          if quote_char == '\\':
            # Handle special character.
            inc(lexer.bufpos)
            quote_char = lexer.buf[lexer.bufpos]

            if quote_char == eof:
              raise newParserError[UnexpectedEndOfStringError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))

            case quote_char
              of '\\':
                result.str_value &= '\\'  # Slash.
              of '"':
                result.str_value &= '"'   # Quotes.
              of '\'':
                result.str_value &= '\''  # Single quote.
              of 'r', 'c':
                result.str_value &= '\r'  # Carriage return.
              of 'n', 'l':
                result.str_value &= '\n'  # Newline.
              of 'f':
                result.str_value &= '\f'  # Form feed.
              of 't':
                result.str_value &= '\t'  # Tab.
              of 'v':
                result.str_value &= '\v'  # Vertical tab.
              of 'a':
                result.str_value &= '\a'  # Alert.
              of 'b':
                result.str_value &= '\b'  # Backspace.
              of 'e':
                result.str_value &= '\e'  # Escape.
              of 'x':
                inc(lexer.bufpos)
                var letter = 0
                lexer.bufpos += parseutils.parseHex(lexer.buf, letter, lexer.bufpos, maxLen = 2) - 1
                result.str_value.add(chr(letter))
              of '0'..'9':
                var letter = 0
                lexer.bufpos += parseutils.parseInt(lexer.buf, letter, lexer.bufpos) - 1
                result.str_value.add(chr(letter))
              #of 'u':
                # Not implemented.
              else:
                raise newParserError[UnrecognisedEscapeStringError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))
          else:
            result.str_value &= quote_char

          if quote_char in {line_feed, carriage_return}:
            lexer.handle_eol(quote_char)
          else:
            inc(lexer.bufpos)
          quote_char = lexer.buf[lexer.bufpos]

        if quote_char == eof:
          raise newParserError[UnexpectedEndOfStringError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))
        inc(lexer.bufpos)

        return result
      else:
        if next_char in {'.', '0'..'9'} or
          (next_char in {'-', '+'} and lexer.buf[lexer.bufpos+1] in {'.', '0'..'9'}):
          let saved_bufpos = lexer.bufpos
          try:
            return lex_number(lexer)
          except InvalidNumberError:
            # Not a number after all.
            lexer.bufpos = saved_bufpos
        result = Token(kind: TokenKind.symbol)
        while lexer.buf[lexer.bufpos] notIn {' ', '\t', ',', line_feed, carriage_return, eof, list_start, list_end, inline_comment_start, block_comment_start, block_comment_end}:
          result.symbol_value &= lexer.buf[lexer.bufpos]
          inc(lexer.bufpos)
        return result

type
  NotInListError* = ref object of ParserError

proc parse_list(lexer: var BaseLexer, data: Stream, top_level: bool = false): List =
  ## Parse a List.
  result = newList()
  var token = lexer.next_token()
  while token.kind notIn {TokenKind.EOF, TokenKind.list_end}:
    case token.kind
      of TokenKind.integer:
        result.append(newInteger(token.int_value))
      of TokenKind.float:
        result.append(newFloat(token.float_value))
      of TokenKind.string:
        result.append(newString(token.str_value))
      of TokenKind.list_start:
        result.append(lexer.parse_list(data))
      of TokenKind.symbol:
        # Check for more stuff here, like booleans
        result.append(newSymbol(token.symbol_value))
      else:
        # EOF, list_end, comment.
        # The first two can't happen and we don't care about the last one.
        discard

    token = lexer.next_token()

  if token.kind == TokenKind.list_end and top_level:
    raise newParserError[NotInListError](lexer.lineNumber, lexer.getColNumber(lexer.bufpos))

proc parse_data*(data: Stream): List =
  ## Parse a stream of text into Objects.
  ## The top level is always considered to be an implicit list.
  var lexer: BaseLexer
  lexer.open(data)
  result = lexer.parse_list(data, top_level=true)
  lexer.close()

when isMainModule:
  import streams, parseopt

  var filename = ""

  # Parse the command line.
  for kind, key, value in getOpt():
    case kind
      of cmdArgument:
        if filename == "":
          filename = key
        else:
          quit("Too many files specified.")
      else:
        quit("No options accepted.")

  if filename == "":
    quit("Filename not specified.")

  let stream = newFileStream(filename)

  echo base_objects.global_object.repr_tree("global")

  let data = parse_data(stream)
  echo("** Parsed Data **\n")
  echo($data)
