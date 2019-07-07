module GeoJSONEx
using DataFrames

export to_features, to_featurecollection

function to_features(data::DataFrame, geofield::Symbol)
    propertykeys = [k for k in names(data) if k != geofield]
    [Dict("type" => "Feature",
          "geometry" => data[geofield][i],
          "properties" => Dict([String(k) => data[k][i] for k in propertykeys]),
    ) for i in 1:size(data, 1)]
end

function to_featurecollection(data::DataFrame, geofield::Symbol)
    Dict("type" => "FeatureCollection",
        "features" => to_features(data, geofield))
end

end
