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

proc do
  unless ($imported ||= {})['Liam-LisaCoreMove']
    raise("LCM BUGFIX - 'Saving During Follower Movement' must be ordered after LCM")
  end

  p = Object.method_defined?(:patch)

  def patch(method_name, &new_body)
    old_body = instance_method(method_name)
    class_exec do
      define_method method_name do |*args, &block|
        temp_name = "unbound"
        while singleton_class.method_defined?(temp_name)
          temp_name.concat("_")
        end
        define_singleton_method(temp_name, &new_body)
        unbound = singleton_class.instance_method(temp_name)
        singleton_class.send(:remove_method, temp_name)
        unbound.bind(self)[old_body.bind(self), *args, &block]
      end
    end
  end

  DataManager.singleton_class.class_eval do

    patch(:save_game) do |_, index|
      fibers = {}
      [$game_player, $game_player.followers].flatten.each do |flw|
        next if flw.lcmCustomConsecutiveMoveRoutesFiber.nil?
        next if flw.actor.nil?

        fibers[flw.actor.id] = flw.lcmCustomConsecutiveMoveRoutesFiber
        flw.lcmCustomConsecutiveMoveRoutesFiber = nil
      end

      begin
        save_game_without_rescue(index)
      rescue => err
        raise(err)
      end

      [$game_player, $game_player.followers].flatten.each do |flw|
        next if flw.actor.nil?

        flw.lcmCustomConsecutiveMoveRoutesFiber = fibers[flw.actor.id]
      end
      true
    end

  end

  Scene_Map.class_eval do

    patch(:start) do |super_|
      super_[]
      [$game_player, $game_player.followers].flatten.each do |flw|
        flw.lcmCustomConsecutiveMoveRoutesList = nil
        flw.instance_variable_set(:@move_route, nil)
        flw.lcmCustomConsecutiveMoveRoutesFiber = nil
        flw.setuplcmCustomConsecutiveMoveRoutes(RPG::MoveRoute.new)
      end
    end

  end

  Object.remove_method(:patch) unless p

end[]
