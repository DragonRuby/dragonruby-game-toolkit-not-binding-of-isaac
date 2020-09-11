require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/controller.rb'
require 'lib/xy_vector.rb'

# <name of sample app> is a prototype of a top-down twin-stick shooter
# similar to Smash TV or The Binding of Issac, designed to be 'stateless'.
# Stateless in this sense refers to the fact that all the defined methods
# are pure functions that do not modify their input parameters, while
# producing the same output given the same input. Rather than using class
# objects, functions use Hashes as universal inputs and outputs.
# Functions that operate on similar entities, such as bullets, the player
# character, etc. are grouped into modules, which are broken out into
# separate files for easier organization.
#
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
