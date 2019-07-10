# module SearchLightEx

using SearchLight

struct SQLFn <: SQLType
    name::Symbol
    fields::Tuple
end

# Base.string(io::IO, s::SQLFn) = """$(s.name)($(s.fields[1]))"""
# Base.print(io::IO, s::SQLFn) = print(io, string(s))
# Base.string(s::SQLFn) = "$(s.name)($(process_fields(s.fields)))"
# SQLColumn(s::SQLFn) = SQLColumn(string(s), raw=true)
# Base.convert(::Type{SQLColumn}, s::SQLFn) = SQLColumn(s)

# function process_fields(fields::Tuple)
#     for field in fields
#         if isa(field, SQLFn)
#             return string(field)
#         else
#             return """$(join(fields, ","))"""
#         end
#     end
# end

# function collect_fn_fields(fn_column::SQLFn)::Vector
#     column_names = []
#     function collcect_fields(fields::Tuple)
#         for field in fields
#             if isa(field, SQLFn)
#                 collcect_fields(field.fields)
#             elseif isa(field, Symbol)
#                 # 意味着定义数据字段名必须是Symbol
#                 push!(column_names, field) 
#             else
#                 continue
#             end
#         end        
#     end

#     collcect_fields(fn_column.fields)
#     column_names
# end

struct SQLFunctionName <: SQLType
    name::Symbol
end
(f::SQLFunctionName)(args...) = SQLFn(f.name, args)

function sql_functions(s)
    :(($(s...),) = $(map(x->SQLFunctionName(x), s)))
end

macro sql_functions(args...)
    esc(sql_functions(args))
end

# struct SQLFunction <: SQLType
#     value::String
# end

# macro sqlfn_str(f)
#     SQLFunction(f)
# end

# SearchLight.SQLColumn(f::SQLFunction) = SQLColumn(f.value)
# Base.convert(::Type{SQLColumn}, f::SQLFunction) = SQLColumn(f)

# Base.convert(::Type{SQLColumn}, r::SQLRaw) = SQLColumn(r.value, raw=true)
# Base.convert(::Type{SQLColumn}, e::Expr) = SQLColumn(string(e), raw=true)
# begin
#     columnstr = "$(e.args[1])($(e.args[2]))"
#     SQLFunctionColumn(columnstr, raw=true)
# end

# function prepare_sqlfunction(c::String)::Tuple{String,Dict{Symbol,String}}
#     result = Dict{Symbol,String}()

#     parts = split(c, "(")
#     result[:sql_function] = parts[1]
#     c_string = parts[2][1:end-1]   
#     result[:original_string] = c_string

#     c_string, result
# end

###### SearchLight ###############
# function SearchLight.from_literal_column_name(c::String)::Dict{Symbol,String}
    
#     if startswith(uppercase(c), "ST_")
#         c, result = prepare_sqlfunction(c)
#     else
#         result = Dict{Symbol,String}()
#         result[:original_string] = c
#     end
    
#     # has alias?
#     if occursin(" AS ", c)
#       parts = split(c, " AS ")
#       result[:column_name] = parts[1]
#       result[:alias] = parts[2]
#     else
#       result[:column_name] = c
#     end
  
#     # is fully qualified?
#     if occursin(".", result[:column_name])
#       parts = split(result[:column_name], ".")
#       result[:table_name] = parts[1]
#       result[:column_name] = parts[2]
#     end
  
#     result
# end

########## SearchLight.Database ##############

function SearchLight.Database.prepare_column_name(fn_column::SQLFn, _m::T) where {T<:AbstractModel}
    function process_fn_column(fn_column::SQLFn)
        "$(fn_column.name)($(process_fields(fn_column.fields)))"
    end

    function process_fields(fields::Tuple)
        result = []

        for field in fields
            field_processed = if isa(field, SQLFn)
                process_fn_column(field)
            elseif isa(field, Symbol)
                column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(field |> String)

                if ! haskey(column_data, :table_name)
                    column_data[:table_name] = table_name(_m)
                end
                if ! haskey(column_data, :alias)
                    column_data[:alias] = ""
                end

                "$(SearchLight.to_fully_qualified(column_data[:column_name], column_data[:table_name]))"
            else
                "$field"
            end
            push!(result, field_processed)
        end

        """$(join(result, ","))"""
    end

    process_fn_column(fn_column)
end

# function SearchLight.Database.prepare_column_name(column::SQLColumn, _m::T)::String where {T<:AbstractModel}
#     if column.raw
#       column.value |> string        
#     else
#         column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(column.value)
#         if ! haskey(column_data, :table_name)
#             column_data[:table_name] = table_name(_m)
#         end
#         if ! haskey(column_data, :alias)
#             column_data[:alias] = ""
#         end

#         if startswith(uppercase(column.value), "ST_")
#             println("ST_Function: $(column.value)")
#             println(column_data)

#             SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column, column_data)
#         else
#             SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column, column_data)
#         end
#     end
# end

####### SearchLight.Database.DatabaseAdapter ###########
# function SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column::SQLFn, column_data::Dict{Symbol,Any})::String
#     "$(column.name)($(to_fully_qualified(column_data[:column_name], column_data[:table_name]))) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
# end

# function SearchLight.Database.DatabaseAdapter.column_data_to_column_name(column::SQLColumn, column_data::Dict{Symbol,Any})::String
#     sql_function = get(column_data, :sql_function, "")
#     if isempty(sql_function)
#         "$(to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
#     else
#         "$(column_data[:sql_function])($(to_fully_qualified(column_data[:column_name], column_data[:table_name]))) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
#     end
# end

# end
