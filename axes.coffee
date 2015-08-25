
Entity = {
  as: {
  }
}
App = Object.create(Entity)
Router = Object.create(Entity)

App.as.web = 1;
console.log Router.as

{DOMParser, XMLSerializer} = require('xmldom')
xpath = require('xpath')

xml = "<book><title>Harry Potter</title></book>"
doc = new DOMParser().parseFromString(xml)
nodes = xpath.select(".//title", doc)
console.log(nodes[0].localName + ": " + nodes[0].firstChild.data)
console.log("node: " + nodes[0].toString())

ui = new DOMParser().parseFromString("<ui />")
root = xpath.select("/ui", ui)[0]

fns = {}
bind = (ob) ->
  uid = (""+Math.random()).substr(2)
  fns[uid] = ob
  uid

root.setAttribute("bind", bind(-> console.log "wow"))

console.log fns[root.getAttribute("bind")]();

console.log new XMLSerializer().serializeToString(ui)
