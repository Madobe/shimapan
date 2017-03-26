require_relative '../database'

# Represents a query for the SQLite3 database.
class Query < Database
  @distinct = false
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
    @@condition ||= []
    if condition.is_a? String
      @@condition << condition
    else
      @@condition << condition[0] % condition[1..-1]
    end
  end

  # Sets the fields that we'll be operating on in the table.
  # @param fields [Array] An array containing all the field names.
  def set_fields(*fields)
    @fields = fields
  end

  # Sets the values that we'll be inserting. Only for queries of type :insert.
  # @param values [Array] An array containing all the values.
  def set_values(*values)
    @values = values
  end

  # Marks this query as requiring the DISTINCT modifier.
  def distinct
    @distinct = true
  end

  # Executes the query. Defers to Database#execute.
  def execute
    super(self)
  end
end
