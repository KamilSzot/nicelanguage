{ runtime: { OMeta, subclass } } = require 'metacoffee'


# { SourceMapGenerator, SourceMapConsumer, SourceNode } = require 'source-map'

util = require 'util'
colors = require 'colors'
l = (o) ->
  console.log(o)
  o

ometa graphql
  SourceCharacter     = anything
  WhiteSpace          = '\u0009' | '\u000B' | '\u000C' | '\u0020' | '\u00A0'
  LineTerminator      = '\u000A' | '\u000D' | '\u2028' | '\u2029'
  Comment             = "#" CommentChar*
  CommentChar         = !LineTerminator SourceCharacter
  Comma               = ","
  Token               = Punctuator
                      | Name
                      | IntValue
                      | FloatValue
                      | StringValue
  Ignored             = WhiteSpace
                      | LineTerminator
                      | Comment
                      | Comma
  Punctuator          = Ignored* ("!" | "$" | "(" | ")" | "..." | ":" | "=" | "@" | "[" | "]" | "{" | "}") Ignored*
  Name                = Ignored* <(letter | "_") (letter | digit | "_")*>:n Ignored* -> n
  Document            = (Definition+ | QueryShorthand):e end -> e
  Definition          = (OperationDefinition | FragmentDefinition):e -> e
  OperationDefinition = OperationType Name VariableDefinitions? Directives? SelectionSet
                      | SelectionSet
  OperationType       = "query" | "mutation"
  QueryShorthand      = SelectionSet
  SelectionSet        = "{" Selection+ "}"
  Selection           = Field
                      | FragmentSpread
                      | InlineFragment
  Field               = Alias? Name Arguments? Directives? SelectionSet?
  Arguments           = "(" Argument+ ")"
  Argument            = Name ":" Value
  Alias               = Name ":"
  FragmentSpread      = "..." FragmentName Directives?
  FragmentDefinition  = "fragment" FragmentName:n "on" TypeCondition Directives? SelectionSet -> n
  FragmentName        = !"on" Name
  TypeCondition       = NamedType
  InlineFragment      = "..." space+ "on" TypeCondition Directives? SelectionSet
  Value               = !"Const" Variable
                      | IntValue
                      | FloatValue
                      | StringValue
                      | BooleanValue
                      | EnumValue
                      | ListValue
                      | ObjectValue
  IntValue            = Ignored* IntegerPart Ignored*
  IntegerPart         = NegativeSign? 0
                      | NegativeSign? NonZeroDigit Digit*
  NegativeSign        = "-"
  Digit               = digit
  NonZeroDigit        = !"0" digit
  FloatValue          = Ignored* (IntegerPart FractionalPart
                      | IntegerPart ExponentPart
                      | IntegerPart FractionalPart ExponentPart) Ignored*
  FractionalPart      = "." Digit+
  ExponentPart        = ExponentIndicator Sign? Digit+
  ExponentIndicator   = "e" | "E"
  Sign                = "-" | "+"
  BooleanValue        = "true" | "false"
  StringValue         = Ignored* ('""' | '"' <StringCharacter+>:s '"') Ignored* -> s ? ""
  StringCharacter     = !'"' !'\n' !'\\' SourceCharacter
                      | '\\' EscapedUnicode
                      | '\\' EscapedCharacter
  EscapedUnicode      = "u/[a-fA-F0-7]{4}/"
  EscapedCharacter    = '"' | '\\' | '/' | 'b' | 'f' | 'n' | 'r' | 't'
  EnumValue           = !"true" !"false" !"null" Name
  ListValue           = '[' ']'
                      | '[' Value+ ']'
  ObjectValue         = '{' '}'
                      | '{' ObjectField+ '}'
  ObjectField         = Name ":" Value
  Variable            = "$" Name
  VariableDefinitions = Variable ":" Type DefaultValue?
  DefaultValue        = "=" Value
  Type                = NamedType
                      | ListType
                      | NonNullType
  NamedType           = Name
  ListType            = "[" Type "]"
  NonNullType         = NamedType "!"
                      | ListType "!"
  Directives          = Directive+
  Directive           = "@" Name Arguments?



# TODO: no regexps

# ometa tok
#   word = <letter+>:e space* -> e
#   doc = word+:w anything* end -> w


code = """
fragment maybeFragment on Query {
  me {
    name
  }
}"""
# for n of graphql.prototype
#   if graphql.prototype.hasOwnProperty(n) && n != 'constructor' && n != 'initialize'
#     do (f = graphql.prototype[n], n = n) -> 
#       graphql.prototype[n] = (args...) -> 
#         ol = @.input.idx
#         res = f.call(@, args...)
#         ne = @.input.idx
#         if ne != ol
#           l n
#         res
        
      
#comp = createCompiler()
error = (m, idx) ->
  console.log(m.input.lst[0..idx] + "<<^^^ ".red + m.input.lst[idx+1..])

console.log graphql.matchAll(code, 'Document', [], error)
# console.log tok.matchAll(code, 'doc', [], error)
