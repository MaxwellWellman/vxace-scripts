# encoding: UTF-8
%w[██████████████████████████████████████████████████████████████████████████]
'  █ LCM BUGFIX █████████████████████████████████████████████████████████████'
#  █ Saving During Follower Movement ████████████████████████████████████████
:__██████████████████████████████████████████████████████████████████████████
%w[██████████████████████████████████████████████████████████████████████████]
'  ██████████████████████████████████████████████████████████████████████████'
#  ██████████████████████████████████████████████████████████████████████████
:__██████████████████████████████████████████████████████████████████████████
%w[██████████████████████████████████████████████████████████████████████████]
'  ████████████████████████████████████████████████████████ MAXWELL WELLMAN █'
#  ██████████████████████████████████████████████████████████████████████████

=begin

 Fixes the bug where saving the game during character movement will delete
 the savefile you're trying to overwrite.

=end

class Class

  def patch(method_name, &new_body)
    patch_name = "___patch___#{method_name}".to_sym
    old_body = instance_method(method_name)
    define_method(patch_name, &new_body)
    new_body = instance_method(patch_name)
    undef_method(patch_name)
    class_exec do
      define_method method_name do |*args, &block|
        new_body.bind(self)[old_body.bind(self), *args, &block]
      end
    end
  end

end

class Object

  def invar(name)
    instance_variable_get(name)
  end

  def invar!(name, val)
    instance_variable_set(name, val)
  end

end

DataManager.singleton_class.class_eval do

  if $imported && $imported['Liam-LisaCoreMove']
    patch(:save_game) do |super_, index|
      fibers = {}
      [$game_player, $game_player.followers].flatten.each do |flw|
        next if flw.lcmCustomConsecutiveMoveRoutesFiber.nil?
        next if flw.actor.nil?

        fibers[flw.actor.id] = flw.lcmCustomConsecutiveMoveRoutesFiber
        flw.lcmCustomConsecutiveMoveRoutesFiber = nil
      end

      save_game_without_rescue(index)

      [$game_player, $game_player.followers].flatten.each do |flw|
        next if flw.actor.nil?

        flw.lcmCustomConsecutiveMoveRoutesFiber = fibers[flw.actor.id]
      end
      true
    end
  else
    msg = "\n\n\n\n\n\n\n"
    msg.concat 'LCM BUGFIX : Saving During Follower Movement'
    msg.concat "\nmust be ordered after LCM."
    msg.concat "\n\n\n\n\n\n\n"
    raise msg
  end

end

Scene_Map.class_eval do

  patch(:start) do |super_|
    super_[]
    [$game_player, $game_player.followers].flatten.each do |flw|
      flw.lcmCustomConsecutiveMoveRoutesList = nil
      flw.invar!(:@move_route, nil)
      flw.lcmCustomConsecutiveMoveRoutesFiber = nil
      flw.setuplcmCustomConsecutiveMoveRoutes(RPG::MoveRoute.new)
    end
  end

end
