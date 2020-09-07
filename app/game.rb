module Game
  # @param [Hash] inputs
  # @param [String] seed
  def self.initial_state(inputs, seed="12345678")
    {
        player: Player.initial_state,
        inputs: inputs
    }
  end

  # @param [GTK::Args] args
  # @return [Hash] Input game state
  def self.initialize(args)
    args.state.game ||= Game.initial_state(InputMapper.process(args.inputs))
  end

  # @param [GTK::Args] args
  def self.render(args)
    args.outputs.sprites << Player.renderables(args.state.game[:player])
  end

  # @param [GTK::Args] args
  # @return [Hash]
  def self.input(args)
    InputMapper.process(args.inputs)
  end

  # @param [Hash] input
  # @param [Hash] game
  def self.do_tick(input, game)
    {
        player: Player.next_state(input, game),
        inputs: input
    }
  end

  # @param [GTK::Args] args
  def self.tick(args)
    Game.initialize(args)
    Game.render(args)
    args.state.game = Game.do_tick(Game.input(args), args.state.game)
  end
end