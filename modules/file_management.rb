module FileManagement
  # This module is meant to hold all the operations related to creating, editing and saving the
  # various YAML files in the project.
  module CustomCommands
    # Serializes and saves custom commands to a YAML file.
    # @param trigger [String] The custom command trigger.
    # @param output [String] The output of the custom command.
    def update(trigger = nil, output = nil)
      self[trigger] = output unless trigger.nil?
      File.open('data/custom_commands.yaml', 'w') { |f| f.write self.to_yaml }
    end
  end
end
