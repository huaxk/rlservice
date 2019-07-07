module HeresChannel

using Genie.WebChannels, Genie.Router


function subscribe()
  WebChannels.subscribe(wsclient(@params), :heres)
  "OK"
end

end
