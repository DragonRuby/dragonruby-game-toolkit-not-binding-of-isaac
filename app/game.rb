module Game
  def Game::initial_state
    {
        player:   Player::initial_state,
        bullets:  Bullets::initial_state,
        controls: InputMapper::controls
    }
  end

  # @param [Hash] game
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Game::renderables(game)
    [
        Player::renderables(game[:player]),
        Bullets::renderables(game[:bullets]),
    ].reduce(&:append)
  end

  # @param [Hash] input
  # @param [Hash] game
  def Game::next_state(input, game)
    {
        player:   Player::next_state(input, game),
        bullets:  Bullets::next_state(input, game),
        controls: game[:controls], #TODO: Allow player to rebind controls?
    }
  end

  # @param [GTK::Args] args
  def Game::tick(args)
    args.state.game               ||= Game::initial_state
    args.outputs.background_color = [128, 128, 128]
    args.outputs.primitives << Game::renderables(args.state.game)
    input           = [InputMapper::process(args.inputs, args.state.game[:controls]), args.state.game]
    output          = Game::next_state(*input)
    args.state.game = output
  end
end