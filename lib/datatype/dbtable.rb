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
  def where(clause)
    @query = Query.new(table_name)
    @query.where(clause)
  end

  # Deletes the currently selected record from the database.
  def delete
    query = Query.new(table_name, :delete)
    query.where("rowid = ?", @id)
    query.execute
  end

  # Commits the object to the database.
  def save
    query = Query.new(table_name, if new? then :insert else :update end)
    fields, values = [], []
    attributes.each do |attribute|
      fields << attribute.to_s
      values << send(attribute)
    end
    query.fields = fields
    query.values = values
    query.execute
    @new = false
  end

  protected

  # Performs the select query currently in the @query variable.
  def self.find(id)
    #@query = Query.new(
    #@query.execute
  end
end
