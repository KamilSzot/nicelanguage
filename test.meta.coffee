{ runtime: {OMeta, subclass} } = require 'metacoffee'
util = require 'util'
colors = require 'colors'

l = (o) ->
  console.log(o)
  o

Object.assign = (object, sources...) ->
  for properties in source
    for key, val of properties
      object[key] = val
    object


# ometa NiceParser
#   wholeProgram = program:p end -> p
#   expr        = "" (rassoc | ter ):e          -> ['e', e]
#   program     = "" listOf("expr", ";"):statements                               -> ['program', statements]
#   block       = "" '{' "" program:p "" '}'                                      -> ['block', p]
#   ter         = literal | block | plusExp | lookup | def
#   rassoc      = (rassoc | ter):e "." identifier:id -> ['.'+id, e]
#               | (rassoc | ter):fn "" '(' listOf("expr", ','):args ')'  -> ['call', args, fn]
#   def         = "def" "" identifier:name "" args?:args "" block:body            -> ['def', name, args, body]
#   identifier  = (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> ':'+first+rest.join ''
#   args        = "(" listOf("identifier", ","):args ")"                          -> ['args', args]
#   lookup      = identifier:name                                                 -> ['lookup', name]
#   literal     = "'" (!"'" anything)*:chars "'"                                  -> ['literal', chars.join '']
#   plusExp     = expr:x "" "+" "" expr:y                                         -> '+'

class Parser
  program: (statements) -> {program: statements }
  block: (program) -> {block: program}
  def: (name, args, body) -> {def:{name: name, args: args, body: body}}
  call: (fn, args) -> {call: args, fn: fn }
  identifier: (str) -> str
  args: (args) -> args.join(', ')
  lookup: (name) -> name
  literal: (str) -> '"'+str+'"'
  plusExp: (x,y) -> {plus:[x,y]}
  partialApplication: (fn, args) -> {partialApplication: args, fn: fn}
  lazyApplication: (fn, args) -> {lazyApplication: args, fn: fn}


class Compiler
  program: (statements) -> (scope) -> statements.reduce ((_, fn) -> fn(scope)), null
  block: (program) -> (scope, args = []) ->
           (actualArgs...) ->
             scopeChild = Object.create(scope);
             for name, position in args
               scopeChild[name] = actualArgs[position]
             program(scopeChild)
  def: (name, args, body) -> (scope) -> scope[name] = body(scope, args)
  call:               (fn, args) -> (scope) -> fn(scope).apply(null, args.map (fn) -> fn(scope))
  lazyApplication:    (fn, args) -> (scope) -> fn(scope).apply(null, args.map (fn) -> fn.bind(null, scope))
  partialApplication: (fn, args) -> (scope) -> Function::bind.apply(fn(scope), [null].concat args.map (fn) -> fn(scope))
  identifier: (str) -> str
  args: (args) -> args
  lookup: (name) -> (scope) -> scope[name]
  literal: (str) -> (scope) -> str
  plusExp: (x,y) -> (scope) -> "" + (x(scope) + y(scope))

nice = (A) ->
  ometa NiceCompiler
    program     = statements:statements end                                       -> statements
    statement   = ';'* expr:e                                                     -> e
    statements  = "" statement+:statements ';'*                                   -> A.program statements

    block       = "" '{' "" statements:statements "" '}'                          -> A.block statements

    def         = "def" "" identifier:name "" args?:args "" block:body            -> A.def name, args, body

    identifier  = (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> A.identifier [first].concat(rest).join('')
    args        = "(" listOf("identifier", ","):args ")"                          -> A.args args

    literal     = "" (number | string):value ""                                   -> A.literal value
    number      = (digit+):number                                                 -> +number
    string      = "'" (!"'" anything)*:chars "'"                                  -> chars.join('')

    lookup      = "" identifier:name ""                                           -> A.lookup name

    lazyExpr    = '^' expr


    expr        = leftrec | others
    others      = def | literal | block | lookup
    leftrec     = (leftrec | others):fn "" '(' listOf("expr", ','):args ')'       -> A.call fn, args
                | (leftrec | others):fn "" "^(" listOf("expr", ','):args ')'      -> A.lazyApplication fn, args
                | (leftrec | others):fn "" '<' listOf("expr", ','):args '>'       -> A.partialApplication fn, args
                | (leftrec | others):x "" "+" "" expr:y                           -> A.plusExp x, y





program = ";;;
  def a(x) { x };
  def b(y) { y };
  def q { a<'g'> };
  q()()+b('h');
  1 + 2;
  3;

  if^(1, t(), e())

"

env = {
  c: -> 1,
  t: -> l "t called"; 1
  e: -> l "e called"; 0
  'if': (cond, whenTrue, whenFalse) -> if(cond()) then whenTrue() else whenFalse()
}


error = (m, idx) ->
  console.log(m.input.lst[0..idx] + "<<^^^ ".red + m.input.lst[idx+1..])

# console.log util.inspect (NiceParser.matchAll program, 'wholeProgram', [], error), false, 20

compiled = nice(new Compiler).matchAll(program, 'program', [], error)
console.log util.inspect compiled, false, 15
if typeof compiled == 'function'
  console.log util.inspect compiled(env), false, 15



# console.log env.b.toString();
  # def b { 'z' };
  # l('abc','def', l())
  # b()
