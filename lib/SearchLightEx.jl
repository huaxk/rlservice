# module SearchLightEx

using SearchLight

# import SearchLight.Database.prepare_column_name


struct SQLFunction <: SQLType
    value::String
end

macro sqlfn_str(f)
    SQLFunction(f)
end

SQLColumn(f::SQLFunction) = SQLColumn(f.value)
Base.convert(::Type{SQLColumn}, f::SQLFunction) = SQLColumn(f)

# Base.convert(::Type{SQLColumn}, r::SQLRaw) = SQLColumn(r.value, raw=true)
# Base.convert(::Type{SQLColumn}, e::Expr) = SQLColumn(string(e), raw=true)
# begin
#     columnstr = "$(e.args[1])($(e.args[2]))"
#     SQLFunctionColumn(columnstr, raw=true)
# end

function prepare_sqlfunction(c::String)::Tuple{String,Dict{Symbol,String}}
    result = Dict{Symbol,String}()

    parts = split(c, "(")
    result[:sql_function] = parts[1]
    c_string = parts[2][1:end-1]   
    result[:original_string] = c_string

    c_string, result
end

function SearchLight.from_literal_column_name(c::String)::Dict{Symbol,String}
    
    if startswith(uppercase(c), "ST_")
        c, result = prepare_sqlfunction(c)
    else
        result = Dict{Symbol,String}()
        result[:original_string] = c
    end
    
    # has alias?
    if occursin(" AS ", c)
      parts = split(c, " AS ")
      result[:column_name] = parts[1]
      result[:alias] = parts[2]
    else
      result[:column_name] = c
    end
  
    # is fully qualified?
    if occursin(".", result[:column_name])
      parts = split(result[:column_name], ".")
      result[:table_name] = parts[1]
      result[:column_name] = parts[2]
    end
  
    result
end

function SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column::SQLColumn, column_data::Dict{Symbol,Any})::String
    sql_function = get(column_data, :sql_function, "")
    if isempty(sql_function)
        "$(to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
    else
        "$(column_data[:sql_function])($(to_fully_qualified(column_data[:column_name], column_data[:table_name]))) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
    end
end

function SearchLight.Database.prepare_column_name(column::SQLColumn, _m::T)::String where {T<:AbstractModel}
    if column.raw
      column.value |> string        
    else
        column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(column.value)
        if ! haskey(column_data, :table_name)
            column_data[:table_name] = table_name(_m)
        end
        if ! haskey(column_data, :alias)
            column_data[:alias] = ""
        end

        if startswith(uppercase(column.value), "ST_")
            println("ST_Function: $(column.value)")
            println(column_data)

            SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column, column_data)
        else
            SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column, column_data)
        end
    end
end

# end
