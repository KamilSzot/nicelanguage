{ runtime: {OMeta, subclass} } = require 'metacoffee'
util = require 'util'
colors = require 'colors'
esprima = require 'esprima'
CoffeeScript = require 'coffee-script'

l = (o) ->
  console.log util.inspect o, false, 10
  o


ast =  CoffeeScript.nodes """

  q = -> 1

  for i in [0...10]
    q i

"""

# l ast

# ast = esprima.parse("""
#   for(i = 0; i < 10; i++) {
#
#   }
# """)

# l ast

ast = { a: 'block', c: [ { q: 'exz' } ] }

# ometa Smart
#   block  = { expressions: }:a {@input.lst.constructor.name == 'Block'}      -> l 'Block'
#   assign = anything:a {@input.lst.constructor.name == 'Assign'}     -> l 'Assign'
#

ometa Smart
  block   = anything:b &{b.a == 'block'} exps(b.c):xs -> ['block', xs]
  exps    = [exp*:e] -> e
  exp     = anything:a string(a.q) -> '#'+a.q

error = (msg) -> l msg

l Smart.match ast, 'block' #, [], error
# l ast.expressions[0].constructor.name
