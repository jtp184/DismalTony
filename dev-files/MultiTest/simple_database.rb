class SimpleDatabase
  def initialize
    @tables = {}
  end

  def add_table(table_name)
    @tables[table_name.to_sym] = []
    table_name.to_sym
  end

  def insert(table_name, value)
    @tables[table_name.to_sym] << value
    value
  end

  def get_table(table_name)
    @tables[table_name.to_sym]
  end
end
