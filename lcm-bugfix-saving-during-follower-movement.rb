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

 When using Liam's Lisa Core Movement script, and you try to save the game
 while a follower is moving or falling off a cliff or laying down after falling
 the game will silently error, refuse to save, and also delete the save that
 you were trying to overwrite. This is because LCM uses Fibers to execute
 movement, and Marshal doesn't like Fibers.

=end

Object.class_eval do

  define_method(:patch) do |klass, method_name, &_|
    src = klass.instance_method(method_name)
    klass.send(:define_method, method_name) do |*args|
      _.call(self, *args, &src.bind(self))
    end
  end

end

DataManager.singleton_class.class_eval do

  if $imported && $imported['Liam-LisaCoreMove']
    patch(self, :save_game) do |this, index, &_|
      fibers = {}
      $game_player.followers.each do |flw|
        next if flw.lcmCustomConsecutiveMoveRoutesFiber.nil?
        next if flw.actor.nil?

        fibers[flw.actor.id] = flw.lcmCustomConsecutiveMoveRoutesFiber
        flw.lcmCustomConsecutiveMoveRoutesFiber = nil
      end

      this.save_game_without_rescue(index)

      $game_player.followers.each do |flw|
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

  patch(self, :start) do |&_|
    _.call
    $game_player.followers.each do |flw|
      flw.lcmCustomConsecutiveMoveRoutesList = nil
      flw.instance_variable_set(:@move_route, nil)
      flw.lcmCustomConsecutiveMoveRoutesFiber = nil
      flw.setuplcmCustomConsecutiveMoveRoutes(RPG::MoveRoute.new)
    end
  end

end
