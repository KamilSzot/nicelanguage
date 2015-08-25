{ runtime: {OMeta, subclass} } = require 'metacoffee'

{ SourceMapGenerator, SourceMapConsumer, SourceNode } = require 'source-map'

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
  plusExp: (x,y) -> (scope) -> x(scope) + y(scope)

nice = (A) ->
  ometa NiceCompiler
    program     = statements:statements end                                       -> statements

    statements  = listOf("spacedExpression", ";"):statements ";"?                             -> A.program statements
    spacedExpression = space* expr:e space*  -> e

    block       = '{' statements:statements '}'                                   -> A.block statements

    def         = "def" space+ identifier:name space* args?:args space* block:body-> console.log(util.inspect @input.lst.substr(at[0], at[1]-at[0])); A.def name, args, body

    identifier  = (letter | '_' | '-'):first ( letter | digit | '-' | '_' )*:rest -> A.identifier [first].concat(rest).join('')
    args        = "(" listOf("identifier", ","):args ")"                          -> A.args args

    literal     = "" (numeric | quoted):value ""                                   -> A.literal value
    numeric     = <digit+:whole (".":sep digit+:decim)?>:n -> +n
    quoted      = "'" <(!"'" anything)*>:str "'"                                  -> str

    lookup      = "" identifier:name ""                                         -> A.lookup name

    expr        = expr:fn '(' listOf("spacedExpression", ','):args ')'                      -> A.call fn, args
                | expr:fn "^(" listOf("spacedExpression", ','):args ')'                     -> A.lazyApplication fn, args
                | expr:fn '<' listOf("spacedExpression", ','):args '>'                      -> A.partialApplication fn, args
                | expr:x "+" expr:y                                             -> A.plusExp x, y
                | (def | literal | block | lookup):e                            -> e
program = "
  def a(x) { x };
  def q(o) { def e(x) { x+1 }; 123 + e(9) };
  q<'a'>();
  def c(m) { m()+1+3 }^(2);
"
  # def q { a^(1) }
#   q()()+b('h');
#   1 + 2;
#   3;
#
#   if^(1, t(), e());
#
#   a(3)+a(2+2);
#   3
# "

env = {
  c: -> 1,
  t: -> l "t called"; 1
  e: -> l "e called"; 0
  'if': (cond, whenTrue, whenFalse) -> if(cond()) then whenTrue() else whenFalse()
}


error = (m, idx) ->
  console.log(m.input.lst[0..idx] + "<<^^^ ".red + m.input.lst[idx+1..])

# console.log util.inspect (NiceParser.matchAll program, 'wholeProgram', [], error), false, 20
comp = nice(new Compiler)

compiled = comp.matchAll(program, 'program', [], error)
console.log util.inspect compiled, false, 15
if typeof compiled == 'function'
  console.log util.inspect compiled(env), false, 15



# console.log env.b.toString();
  # def b { 'z' };
  # l('abc','def', l())
  # b()
