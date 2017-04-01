require_relative '../database'

# Represents a query for the SQLite3 database.
class Query < Database
  @distinct = false

  # Allows getting of the results instance variable.
  def result
    @result
  end

  # Allows getting of the errors encountered in the last execute.
  def errors
    @errors
  end

  # Creates a query. Requires at least a table name.
  # @param table [String] A table name.
  # @option type [Symbol] The type of operation this query is for. Defaults to select.
  def initialize(table, type = :select)
    @table = table # Table name
    @type = type # Type of query (select, insert, etc.)
  end

  # Adds a WHERE clause to the statement. Can be called multiple times for one query to add more conditions.
  # @param condition [String, Array] Either a string that follows SQL convention or an array of such
  # with interpolation.
  #   Example: .where(["user_id = ?", user_id])
  def where(condition)
    @conditions ||= []
    if condition.is_a? String
      @conditions << condition
    else
      condition[0].gsub!("?", "%s")
      @conditions << condition[0] % condition[1..-1]
    end
  end

  # The accessor for @conditions so we can check if it's nil or not before plunking it into a query
  # when resolved.
  def conditions
    if @conditions.nil? or @conditions.empty?
      ["1 = 1"]
    else
      @conditions
    end
  end

  # Sets the fields that we'll be operating on in the table.
  # @param fields [Array] An array containing all the field names.
  def fields=(fields)
    @fields = fields
  end

  # Sets the values that we'll be inserting. Only for queries of type :insert.
  # @param values [Array] An array containing all the values.
  def values=(values)
    values.map! { |value|
      if value.is_a? String
        "\"%s\"" % value
      else
        value
      end
    }
    @values = values
  end

  # Marks this query as requiring the DISTINCT modifier.
  def distinct
    @distinct = true
  end

  # Resolves the Query object to an executable format.
  def resolve
    case @type
    when :select
      "SELECT %{distinct}%{fields} FROM %{table} WHERE %{conditions};" % {
        table:      @table,
        fields:     if @fields.nil? then "id,*" else @fields.join(",") end,
        conditions: conditions.join(" AND "),
        distinct:   if @distinct then " DISTINCT" else "" end,
      }
    when :insert
      "INSERT INTO %{table} (%{fields}) VALUES (%{values});" % {
        table:  @table,
        fields: @fields.join(","),
        values: @values.map { |x| x.dump }.join(",")
      }
    when :update
      "UPDATE %{table} SET %{statements} WHERE %{conditions};" % {
        table:      @table,
        statements: @fields.zip(@values).map { |x| "%s = %s" % [x[0], x[1]] }.join(","),
        conditions: conditions.join(" AND ")
      }
    when :delete
      "DELETE FROM %{table} WHERE %{conditions};" % {
        table:      @table,
        conditions: conditions.join(" AND ")
      }
    end
  end

  # Executes the query. Defers to Database#execute. Saves the result to @result so we can possibly
  # run this again if necessary.
  # @return [Array] Returns an array of the results.
  def execute
    begin
      @result = super(self.resolve)
    rescue StandardError => e
      @errors = e
      raise e
    end
  end
end
