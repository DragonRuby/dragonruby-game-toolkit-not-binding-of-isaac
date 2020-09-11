module Game
  def Game::initial_state
    {
      # The :: is a unary operator that allows: constants, instance methods and class methods defined within
      # a class or module, to be accessed from anywhere outside the class or module.
      # Game::initial_state calls the respective module's initial_state functions.
      # See player.rb, bullets.rb, controller.rb for more info.
        player:  Player::initial_state,
        bullets: Bullets::initial_state,
        intent:  Controller::initial_state,
        keymap:  Controller::keymap,
    }
  end

  # @param [Hash] game
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Game::renderables(game)
    [
      # Game::renderables is an array of graphics primitives to be displayed on the screen
      # Each module takes the respective object from game as input
        Player::renderables(game[:player]),
        Bullets::renderables(game[:bullets]),
      # FPS output for debugging purposes
        [10, 30, "FPS : #{$gtk.current_framerate.to_s.to_i}", 255, 0, 0].label
    ].reduce(&:append)
  end

  # @param [Hash] game
  # @param [GTK::Inputs] raw_input
  def Game::next_state(game, raw_input)
    {
      # Do not modify the player object directly, instead send the info about the current game state
      # to return a new player object to represent the player. Repeat for bullets
        player:  Player::next_state(game),
        bullets: Bullets::next_state(game),
      # As of now, the default controls are set in stone. However, creation of a key remapping
      # function would be trivial to add. Simply replace game[:keymap] with a function that
      # returns the new keymap
        keymap:  game[:keymap], 

      # intent is raw_input converted into a map for each function of the player
      # move, shooting, init_shoot will contain enough information to determine
      # the player character's next actions
        intent: Controller::get_player_intent(raw_input, game)
    }
  end

  # @param [GTK::Args] args
  def Game::tick(args)
  # Set args.state.game to the initial game state
    args.state.game ||= Game::initial_state
    prev_state      = args.state.game

    args.outputs.background_color = [128, 128, 128]
  # Game::renderables is given the previous game state to display on the screen
  # By not rendering the objects directly, we can assure we get the same results
    args.outputs.primitives << Game::renderables(prev_state)

  # Set the next game state
    args.state.game = Game::next_state(prev_state, args.inputs)
  end
end
