module Boss
  def Boss::initial_state
    {
        alive:  false,
        x:      640,
        y:      680,
        bbox:   [640 - 160, 680 - 80, 160 * 2, 80 * 2],
        health: 50.0
    }
  end

  def Boss::tick_diff(game)
    {
        alive:  Kernel.tick_count == 60 * 5 || (game[:boss][:alive] && game[:boss][:health] > 0),
        health: Boss::get_hp(game)
    }
  end

  def Boss::renderables(boss)
    if boss[:alive]
      [
          {
              x: boss[:x] - 160,
              y: boss[:y] - 80,
              w: 160 * 2,
              h: 80 * 2,
              r: 255,
              g: 0,
              b: 0,
              a: 255
          }.solid
      ]
    else
      []
    end
  end

  def Boss::get_hp(game)
    return game[:boss][:health] unless game[:boss][:alive]
    bullets = game[:bullets][:player_bullets].find_all { |b| b[:attrs][:bbox].intersect_rect?(game[:boss][:bbox]) }
    damage_taken = bullets.map { |b| b[:attrs][:stats][:damage] }.reduce(0, &:plus)
    return game[:boss][:health] - damage_taken
  end
end