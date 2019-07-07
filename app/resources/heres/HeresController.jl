module HeresController
using Genie, Genie.Renderer, Genie.Requests, Genie.Router
# using JSON
using SearchLight
using GeoJSONEx
using JSON2

function index()
    rs = SearchLight.query("select id, name, ST_ASGeoJSON(lnglat) as lnglat from heres")
    # respond(JSON.json(to_featurecollection(rs, :lnglat)), "application/json")
    respond(JSON2.write(to_featurecollection(rs, :lnglat)), "application/json")
end

function show()
    id = @params(:id)
    rs = SearchLight.query("select id, name, ST_ASGeoJSON(lnglat) as lnglat from heres where id=$id")
    if size(rs, 1) == 1
        fs = to_features(rs, :lnglat)
        respond(JSON2.write(fs[1]), "application/json")
    else
        respond("""{"error": "No value with $id"}""", "application/json")
    end
end

function create()
    json = jsonpayload()
    name = json["name"]
    lnglat = json["lnglat"] |> JSON2.write
    SearchLight.query("insert into heres (name, lnglat) values (
        '$name',
        ST_SetSRID(ST_GeomFromGeoJSON('$lnglat'), 4326)
    )")
end

function delete()
    id = @params(:id)
    SearchLight.query("delete from heres where id=$id")
end

end
