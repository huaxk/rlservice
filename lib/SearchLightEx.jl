# module SearchLightEx

using SearchLight

struct SQLFunction <: SQLType
    name::Symbol
    fields::Tuple
end

struct SQLFunctionName <: SQLType
    name::Symbol
end
(f::SQLFunctionName)(args...) = SQLFunction(f.name, args)

function sql_functions(s)
    :(($(s...),) = $(map(x->SQLFunctionName(x), s)))
end

macro sql_functions(args...)
    esc(sql_functions(args))
end

# function AS(a::SQLFunction, b::Symbol)
    
# end

###### SearchLight ###############
function SearchLight.to_select_part(m::Type{T}, cols::Vector{Union{SQLColumn, SQLFunction}}, joins = SQLJoin[])::String where {T<:AbstractModel}
    SearchLight.Database.to_select_part(m, cols, joins)
end

function SearchLight.to_select_part(m::Type{T}, c::SQLFunction)::String where {T<:AbstractModel}
    SearchLight.to_select_part(m, [c])
end

########## SearchLight.Database ##############
function SearchLight.Database.prepare_column_name(fn_column::SQLFunction, _m::T) where {T<:AbstractModel}
    function process_sql_function(fn_column::SQLFunction)
        "$(fn_column.name)($(process_fields(fn_column.fields)))"
    end

    function process_fields(fields::Tuple)
        result = []

        for field in fields
            field_processed = if isa(field, SQLFunction)
                process_sql_function(field)
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

    process_sql_function(fn_column)
end

function SearchLight.Database.to_select_part(m::Type{T}, cols::Vector{Union{SQLColumn, SQLFunction}}, joins = SQLJoin[])::String where {T<:AbstractModel}
    SearchLight.Database.DatabaseAdapter.to_select_part(m, cols, joins)
end

function SearchLight.Database._to_select_part(m::Type{T}, cols::Vector{Union{SQLColumn, SQLFunction}}, joins = SQLJoin[])::String where {T<:AbstractModel}
    _m::T = m()
  
    joined_tables = []
  
    if has_relation(_m, RELATION_HAS_ONE)
      rels = _m.has_one
      joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
    end
  
    if has_relation(_m, RELATION_HAS_MANY)
      rels = _m.has_many
      joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
    end
  
    if has_relation(_m, RELATION_BELONGS_TO)
      rels = _m.belongs_to
      joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
    end
  
    filter!(x -> x != nothing, joined_tables)
  
    if ! isempty(cols)
      table_columns = []
      cols = vcat(cols, columns_from_joins(joins))
  
      for column in cols
        push!(table_columns, prepare_column_name(column, _m))
      end
  
      return join(table_columns, ", ")
    else
      table_columns = join(to_fully_qualified_sql_column_names(_m, persistable_fields(_m), escape_columns = true), ", ")
      table_columns = isempty(table_columns) ? String[] : vcat(table_columns, map(x -> prepare_column_name(x, _m), columns_from_joins(joins)))
  
      related_table_columns = String[]
      for rels in map(x -> to_fully_qualified_sql_column_names(x, persistable_fields(x), escape_columns = true), joined_tables)
        for col in rels
          push!(related_table_columns, col)
        end
      end
  
      return join([table_columns ; related_table_columns], ", ")
    end
end
  
####### SearchLight.Database.DatabaseAdapter ###########

# end
