require_relative 'query'
require_relative '../modules/utilities'

class DBTable
  attr_reader :id

  def initialize
    @new = true
  end

  # Overwrite the attr_accessor method so we can remember what went in it.
  def self.attr_accessor(*vars)
    @attributes ||= []
    @attributes.concat(vars)
    super
  end

  # Get the class instance variable from a Class reference.
  def self.attributes
    @attributes
  end

  # Gets the class instance variable from an instance.
  def attributes
    self.class.attributes
  end

  # Marks one of the fields as a foreign key for another table.
  # @param field [Symbol,String] The field name from the current model that acts as a foreign key on
  # the other table.
  # @param other_table [Symbol,String] The name of the other table.
  def self.acts_as_foreign_key(other_table, field)
    Dir[File.join(ENV['SHIMA_ROOT'], 'models', '*.rb')].each { |file| require file }
    define_method(other_table) do
      model = Object.const_get(other_table.to_s.camelize[0..-2])
      model.where(["? = ?", field.to_s, send(field)])
    end
  end

  # Returns the name of the table that should be associated with the current model.
  def table_name
    "%ss" % self.class.name.underscore
  end

  # Checks if this object has a matching database entry (already saved) or not. Can't be
  # standardized because primary keys aren't enforced on the tables.
  def new?
    return @new
  end

  # Does a where on the current table. This is a select-only command.
  # @params clause [Array] The conditions to check for which records to select.
  # @return [Array<DBTable>] Returns an array representing all the entries that were found.
  def self.where(clause)
    query ||= Query.new("%ss" % self.name.underscore)
    query.fields = ["id"].concat(@attributes.map { |x| x.to_s })
    query.where(clause)
    query.execute

    objects = []
    query.result.each do |values|
      object = self.new
      object.instance_variable_set(:@new, false)
      object.populate(values)
      objects << object
    end
    
    return objects
  end

  # Deletes the currently selected record from the database.
  def destroy
    query = Query.new(table_name, :delete)
    query.where(["id = ?", @id])
    query.execute
  end

  # Commits the object to the database.
  def save
    query = Query.new(table_name, if @new then :insert else :update end)
    fields, values = [], []

    query.where(["id = ?", @id]) if !@new

    attributes.each do |attribute|
      unless send(attribute).nil?
        fields << attribute.to_s
        values << send(attribute)
      end
    end
    query.fields = fields
    query.values = values

    begin
      query.execute
      @id = query.result[0]
      @new = false
      return true
    rescue
      return false
    end
  end

  # Creates a variable and assigns each
  def populate(values)
    @id = values.shift
    values.each_with_index do |value, i|
      unless attributes[i].nil?
        send("#{attributes[i]}=", value)
      end
    end
    self
  end

  protected

  def id=(id)
    @id = id
  end

  # Performs the select query currently in the @query variable.
  def self.find(id)
    @query = Query.new(table_name)
    @query.where(["id = ?", id]).first
    @query.execute
  end
end
