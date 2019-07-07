using Genie.Router
using HeresController

route("/") do
  serve_static_file("welcome.html")
end

route("/heres", HeresController.index, named=:get_heres)
route("/heres", HeresController.create, method=POST, named=:create_here)
route("/heres/:id", HeresController.show, named=:get_here)
route("/heres/:id", HeresController.delete, method=DELETE, named=:delete_here)
