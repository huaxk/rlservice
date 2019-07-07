using Genie.Router
using HeresController

route("/") do
  serve_static_file("welcome.html")
end

route("/hello") do
  "Hello world"
end

route("/heres", HeresController.index)