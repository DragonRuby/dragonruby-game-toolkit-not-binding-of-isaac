module Game
  def Game::initial_state
    {
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
        Player::renderables(game[:player]),
        Bullets::renderables(game[:bullets]),
        {x: 10, y: 120, text: "FPS : #{$gtk.current_framerate.to_s.to_i}", r: 255, g: 0, b:0},
        {x: 10, y: 90, text: "TPS : #{$state.tps.round}", r: 255, g: 0, b:0},
        {x: 10, y: 60, text: "Bullet Count : #{game[:bullets].length}", r: 255, g: 0, b:0},
     {x: 10, y: 30, text: "Player Speed : #{(100.0*XYVector.abs(game[:player][:vel])/game[:player][:stats][:total][:speed]).round}%", r: 255, g: 0, b:0},
    ].reduce(&:append)
  end

  # @param [Hash] game
  # @param [GTK::Inputs] raw_input
  def Game::tick_diff(game, raw_input)
    {
        player:  Player::tick_diff(game),
        bullets: Bullets::tick_diff(game),
        # keymap:  game[:keymap], #TODO: Allow player to rebind controls?
        intent: Controller::get_player_intent(raw_input, game)
    }
  end

  # @param [GTK::Args] args
  def Game::tick(args)
    args.state.game ||= Game::initial_state
    # @type Hash
    prev_state      = args.state.game

    args.outputs.background_color = [128, 128, 128]
    args.outputs.primitives << Game::renderables(prev_state)
    args.outputs.debug << args.gtk.framerate_diagnostics_primitives
    diff = Game::tick_diff(prev_state, args.inputs)
    # puts diff
    args.state.game.deep_merge!(diff)
  end
end