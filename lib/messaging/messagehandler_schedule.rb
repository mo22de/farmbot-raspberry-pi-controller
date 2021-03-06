require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'
require_relative 'messagehandler_schedule_cmd_line'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerSchedule < MessageHandlerBase

  attr_accessor :message

  def whitelist
    ["single_command","crop_schedule_update"]
  end

  def single_command(message)

    @dbaccess.write_to_log(2,'handle single command')

    if message.payload.has_key? 'command' 

      command = message.payload['command']
      command_obj = MessageHandlerScheduleCmdLine.new
      command_obj.split_command_line( message.payload['command'])
      command_obj.write_to_log()
      save_single_command(command_obj, message.delay)
      $status.command_refresh += 1;
      message.handler.send_confirmation(message.sender, message.time_stamp)

    else

      message.handler.send_error(sender, time_stamp, 'no command in message')

    end

  end

  def save_single_command(command, delay)
      @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
      save_command_line(command)
      @dbaccess.save_new_command
  end

  def save_command_line(command)
      @dbaccess.add_command_line(command.action, command.x.to_i, command.y.to_i, command.z.to_i, command.speed.to_s, command.amount.to_i, 
        command.pin_nr.to_i, command.pin_value1.to_i, command.pin_value2.to_i, command.pin_mode.to_i, command.pin_time.to_i, command.ext_info)
  end

  def crop_schedule_update(message)
    @dbaccess.write_to_log(2,'handling crop schedule update')

    message_contents = message.payload

    crop_id = message_contents['crop_id']
    @dbaccess.write_to_log(2,"crop_id = #{crop_id}")

    @dbaccess.clear_crop_schedule(crop_id)

    message_contents['commands'].each do |command|
     save_command_with_lines(command)
    end

    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

  def save_command_with_lines(command)

      scheduled_time = Time.parse(command['scheduled_time'])
      crop_id        = command['crop_id']
      @dbaccess.write_to_log(2,"crop command at #{scheduled_time}")
      @dbaccess.create_new_command(scheduled_time, crop_id)

      command['command_lines'].each do |command_line|

        command_obj = MessageHandlerScheduleCmdLine.new
        command_obj.split_command_line( command_line)
        command_obj.write_to_log()
        save_command_line(command_obj)

      end

      @dbaccess.save_new_command
  end

end
