module Rlservice

using Genie, Genie.Router, Genie.Renderer, Genie.AppServer

function main()
  Base.eval(Main, :(const UserApp = Rlservice))

  include("../genie.jl")

  Base.eval(Main, :(const Genie = Rlservice.Genie))
  Base.eval(Main, :(using Genie))
end

main()

end
