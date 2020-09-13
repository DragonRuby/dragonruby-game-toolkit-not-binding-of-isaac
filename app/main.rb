require 'lib/deepmerge.rb'
require 'lib/xy_vector.rb'
require 'lib/prng.rb'
require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/dungeon_master.rb'
require 'app/controller.rb'

# @param [GTK::Args] args
def tick(args)
  Game::tick args
end