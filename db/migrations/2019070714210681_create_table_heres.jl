module CreateTableHeres

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table
using SearchLight

function up()
  SearchLight.query("""
    CREATE TABLE heres (
      id serial,
      name varchar(255),
      lnglat geometry(point, 4326),
      primary key(id)
    );
  """)
  # create_table(:heres) do
  #   [
  #     primary_key()
  #     column(:name, :string)
  #     column(:lnglat, :geometry)
  #   ]
  # end

  # add_index(:heres, :name)
end

function down()
  drop_table(:heres)
end

end
