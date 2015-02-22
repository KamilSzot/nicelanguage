{ runtime: {OMeta, subclass} } = require 'metacoffee'
util = require 'util'


ometa MultiplicativeInterpreter
  expr     = mulExpr:x "+" mulExpr:y  -> x + y
           | mulExpr:x "-" mulExpr:y  -> x - y
           | mulExpr:x                -> x
  mulExpr  = mulExpr:x "*" primExpr:y -> x * y
           | mulExpr:x "/" primExpr:y -> x / y
           | primExpr
  primExpr = "(" expr:x ")"           -> x
           | number
  number   = "" digit:d               -> valueOfDigit d
           | "-" digit:d              -> -valueOfDigit d

valueOfDigit = (digit) ->
  +digit

# console.log MultiplicativeInterpreter.matchAll '5-2+2', 'expr'
# console.log MultiplicativeInterpreter.matchAll '2-2', 'expr'
# console.log MultiplicativeInterpreter.matchAll '((7 * 8) / (8 / 6)) - (4+5)', 'expr'

ometa LISPInterpreter
  expr    = list
          | apply
          | literal
          | symbol
  list    = "" "'(" expr*:els ")"          -> els
  apply   = "" "(" expr+:els ")"           -> els[0].apply(@, els[1..])
  atom    = "" (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> first + rest.join('')
  literal = "" "'" atom
  symbol  = atom:name  -> env[name]

env =
  l: (args...) -> args
#  def: (name, value) -> env[name] = value
  do: (args..., last) -> last
  c: -> 5
  n: 100
# console.log LISPInterpreter.matchAll "
# (do
#   (def 'b 'rest)
#   (def 'a 'test)
#   b
# )", 'expr'

l = (s, o) ->
  console.log('-----------')
  console.log(s)
  console.log(o)
  o

Object.assign = (object, sources...) ->
  for properties in source
    for key, val of properties
      object[key] = val
    object

ometa NiceParser
  wholeProgram = program:p end -> p
  expr        = "" (rassoc | ter ):e          -> ['e', e]
  program     = "" listOf("expr", ";"):statements                               -> ['program', statements]
  block       = "" '{' "" program:p "" '}'                                      -> ['block', p]
  ter         = literal | block | plusExp | lookup | def
  rassoc      = (rassoc | ter):e "." identifier:id -> ['.'+id, e]
              | (rassoc | ter):fn "" '(' listOf("expr", ','):args ')'  -> ['call', args, fn]
  def         = "def" "" identifier:name "" args?:args "" block:body            -> ['def', name, args, body]
  identifier  = (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> ':'+first+rest.join ''
  args        = "(" listOf("identifier", ","):args ")"                          -> ['args', args]
  lookup      = identifier:name                                                 -> ['lookup', name]
  literal     = "'" (!"'" anything)*:chars "'"                                  -> ['literal', chars.join '']
  plusExp     = expr:x "" "+" "" expr:y                                         -> '+'

ometa NiceCompiler
  wholeProgram = program end
  statement   = call | expr

  expr        = "" (call | def | literal | block | plusExp | lookup )
  program     = "" listOf("statement", ";"):statements                               -> (scope) -> statements.reduce ((_, fn) -> fn(scope)), null
  block       = "" '{' "" program:p "" '}'                                      -> (scope, args = []) ->
                                                                                      (actualArgs...) ->
                                                                                        scopeChild = Object.create(scope);
                                                                                        for name, position in args
                                                                                          scopeChild[name] = actualArgs[position]
                                                                                        p(scopeChild)
  def         = "def" "" identifier:name "" args?:args "" block:body            -> (scope) -> scope[name] = body(scope, args)
  call        = (call | block | lookup):fn "" '(' listOf("expr", ','):args ')'  -> (scope) -> fn(scope).apply(null, args.map (fn) -> fn(scope))
  identifier  = (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> [first].concat(rest).join('')
  args        = "(" listOf("identifier", ","):args ")"                          -> args
  lookup      = "" identifier:name ""                                           -> (scope) -> scope[name]
  literal     = "'" (!"'" anything)*:chars "'"                                  -> (scope) -> chars.join ''
  plusExp     = expr:x "" "+" "" expr:y                                         -> (scope) -> "" + x(scope) + y(scope)

program = "
  'a'.a().b.c().dads.e.f
"

error = (m, idx) ->
  console.log(m.input.lst[0..idx] + "<<^^^ " + m.input.lst[idx..])

console.log util.inspect (NiceParser.matchAll program, 'wholeProgram', [], error), false, 10

# console.log util.inspect (NiceCompiler.matchAll program, 'program')(env), false, 10



# console.log env.b.toString();
  # def b { 'z' };
  # l('abc','def', l())
  # b()
