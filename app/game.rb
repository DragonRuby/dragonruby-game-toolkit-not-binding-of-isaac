module Game
  def Game::initial_state
    {
        player:  Player::initial_state,
        bullets: Bullets::initial_state,
        keymap:  Controller::controls
    }
  end

  # @param [Hash] game
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Game::renderables(game)
    [
        Player::renderables(game[:player]),
        Bullets::renderables(game[:bullets]),
        [10, 30, "FPS : #{$gtk.current_framerate.to_s.to_i}", 255, 0, 0].label
    ].reduce(&:append)
  end

  # @param [Hash] player_intent
  # @param [Hash] game
  def Game::next_state(player_intent, game)
    {
        player:  Player::next_state(player_intent, game),
        bullets: Bullets::next_state(player_intent, game),
        keymap:  game[:keymap], #TODO: Allow player to rebind controls?
    }
  end

  # @param [GTK::Args] args
  def Game::tick(args)
    args.state.game ||= Game::initial_state
    prev_state      = args.state.game

    args.outputs.background_color = [128, 128, 128]
    args.outputs.primitives << Game::renderables(prev_state)

    player_intent = Controller::get_player_intent(args.inputs, args.state.game[:keymap])

    args.state.game = Game::next_state(player_intent, prev_state)
  end
end