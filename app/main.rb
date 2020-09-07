require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/controller.rb'
require 'lib/xy_vector.rb'

# @param [GTK::Args] args
def tick(args)
  Game::tick args
end