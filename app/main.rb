require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/input_mapper.rb'
require 'lib/xy_vector.rb'

# $gtk.define_singleton_method(:production) { true }

# @param [GTK::Args] args
def tick(args)
  Game::tick args
end