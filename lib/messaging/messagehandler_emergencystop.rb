require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerEmergencyStop < MessageHandlerBase

  def whitelist
    ["emergency_stop","emergency_stop_reset"]
  end

  ## emergency stop

  # emergency stop activate
  #
  def emergency_stop(message)

    @dbaccess.write_to_log(2,'handle emergency stop')

    $status.emergency_stop = true
    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

  # emergency stop activate
  #
  def emergency_stop_reset(message)

    @dbaccess.write_to_log(2,'handle emergency stop reset')

    $status.emergency_stop = false
    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

end
