require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/controller.rb'
require 'lib/xy_vector.rb'

# <name of sample app> is a twinstick prototype designed to be 'stateless'
# Stateless in this sense describes the usage of modular functions that do
# not depend on a state to give correct output.
# The inspiration for designing the code base in this way comes from two
# presentations:
#
# https://www.infoq.com/presentations/Simple-Made-Easy/
# https://www.youtube.com/watch?v=-6BsiVyC1kM
#
# Please watch the above lectures to gain insight into how this code was
# constructed.
#
# WASD to move, arrow keys to shoot in the respective direction.

# @param [GTK::Args] args
def tick(args)
  # Calls the Game module's tick function with a single parameter args.
  # See game.rb for more info.
  Game::tick args
end
