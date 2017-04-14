require 'active_record'

# Modifier types:
# n (nick)       display_name changes
# e (edit)       message edits
# d (delete)     message deletes
# c (channel)    channel-specific message editing or deletion
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
      'c' => 'channel-specific message edits/deletes',
      'v' => 'voice channel changes',
      'm' => 'mutes',
      'p' => 'punishments',
      'b' => 'bans'
    }
  end

  # All the modifiers.
  def self.modifiers
    self.modlog_modifiers | self.serverlog_modifiers
  end

  # All the one character modifiers.
  def self.short_modifiers
    self.short_modlog_modifiers | self.short_serverlog_modifiers
  end

  # Only the one character modifiers for the modlog.
  def self.short_modlog_modifiers
    %w( m p b )
  end

  # Only the one character modifiers for the serverlog.
  def self.short_serverlog_modifiers
    %w( n r e d c v )
  end

  # All the modlog modifiers.
  def self.modlog_modifiers
    self.short_modlog_modifiers | %w( mute punish ban )
  end

  # All the serverlog modifiers.
  def self.serverlog_modifiers
    self.short_serverlog_modifiers | %w( nick role edit delete channel voice )
  end

  # Gets the single character modifier for a long version. Also checks if the modifier is valid.
  # @param modifier [String] The modifier we're shortening.
  def self.shorten_modifier(modifier)
    raise Feed::InvalidModifierError.new(modifier) unless self.modifiers.include? modifier
    modifier[0]
  end

  # Check whether the target has permissions defined for them. Return true if there's nothing.
  #   1. Check if any settings exist on the server for the modifier. If not, return true.
  #   2. Check if there's a blanket setting (inclusive of every ID) for the modifier. If so, return
  #   that setting's `allow` value.
  #   3. If none of the above, use the user-specific value which -must- exist.
  # @param server [Server] The server this is being checked for.
  # @param modifier [String] The type of permission we're checking.
  # @param target [Integer] The channel/user ID being checked.
  def self.check_perms(server, modifier, target)
    modifier = self.shorten_modifier(modifier)
    perm_type = self.perm_types[modifier]
    settings = self.where(server_id: server.id, modifier: modifier.to_s)
    return true if settings.empty? # All logs are on by default
    blanket = self.where(server_id: server.id, modifier: modifier.to_s, target: 0).first
    user_specific = self.where(server_id: server.id, modifier: modifier.to_s, target: target).first
    return blanket.allow if blanket && !user_specific
    user_specific.allow
  rescue NoMethodError => e
    return true # If we hit an error, assume the logging is allowed.
  end
end

# The error raised when the specified modifier doesn't exist.
class Feed::InvalidModifierError < StandardError
  def initialize(modifier)
    super("Invalid modifier `#{modifier}`")
  end
end
