require 'active_record'

# Modifier types:
# n (nick)       display_name changes
# e (edit)       message edits
# d (delete)     message deletes
# v (voice)      user voice channel changes
# m (mute)       user mutes, only via this bot (also includes unmutes)
# p (punish)     user punishing, only via this bot (also includes unpunishing)
# b (ban)        user bans (also includes unbans)
class Feed < ActiveRecord::Base
  validates_presence_of :server_id, :modifier, :target
  validates_uniqueness_of :target, scope: [:server_id, :allow, :modifier]
  validates_inclusion_of :allow, in: [true, false]

  # The long descriptions for each modifier. Used for printing.
  def self.descriptions
    {
      'n' => 'display name changes',
      'r' => 'role changes',
      'e' => 'message edits',
      'd' => 'message deletion',
      'v' => 'voice channel changes',
      'm' => 'mutes',
      'p' => 'punishments',
      'b' => 'bans'
    }
  end

  # All the modlog modifiers.
  def self.modlog_modifiers
    %w( m mute p punish b ban )
  end

  # All the serverlog modifiers.
  def self.serverlog_modifiers
    %w( n nick r role e edit d delete v voice )
  end

  # All the modifiers.
  def self.modifiers
    self.modlog_modifiers | self.serverlog_modifiers
  end

  # All the one character modifiers.
  def self.short_modifiers
    self.modifiers.reject { |modifier| modifier.length > 1 }
  end

  # Only the one character modifiers for the modlog.
  def self.short_modlog_modifiers
    self.modlog_modifiers.reject { |modifier| modifier.length > 1 }
  end

  # Only the one character modifiers for the serverlog.
  def self.short_serverlog_modifiers
    self.serverlog_modifiers.reject { |modifier| modifier.length > 1 }
  end

  # Gets the single character modifier for a long version. Also checks if the modifier is valid.
  def self.shorten_modifier(modifier)
    raise Feed::InvalidModifierError.new(modifier) unless (self.modlog_modifiers | self.serverlog_modifiers).include? modifier
    modifier[0]
  end
end

# The error raised when the specified modifier doesn't exist.
class Feed::InvalidModifierError < StandardError
  def initialize(modifier)
    super("Invalid modifier `#{modifier}`")
  end
end
