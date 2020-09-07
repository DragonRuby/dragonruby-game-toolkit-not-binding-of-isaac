module Game
  def self.initial_state
    {
        player: Player.initial_state,
    }
  end

  # @param [Hash] game
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def self.renderables(game)
    [
        Player.renderables(game[:player]),

    ].reduce(&:plus)
  end

  # @param [Hash] input
  # @param [Hash] game
  def self.next_state(input, game)
    {
        player: Player.next_state(input, game),
    }
  end

  # @param [GTK::Args] args
  def self.tick(args)
    args.state.game ||= Game.initial_state
    args.outputs.primitives << Game.renderables(args.state.game)
    input           = [InputMapper.process(args.inputs), args.state.game]
    output          = Game.next_state(*input)
    args.state.game = output
  end
end