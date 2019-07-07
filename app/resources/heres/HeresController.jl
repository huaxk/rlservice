module HeresController
using Genie.Renderer
# using JSON
using SearchLight
using GeoJSONEx
using JSON2

function index()
    rs = SearchLight.query("select id, name, ST_ASGeoJSON(lnglat) as lnglat from heres")
    # respond(JSON.json(to_featurecollection(rs, :lnglat)), "application/json")
    respond(JSON2.write(to_featurecollection(rs, :lnglat)), "application/json")
end

end
