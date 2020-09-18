module Bullets

  def self::initial_state
    {
        player_bullets:     [],
        parametric_bullets: []
    }
  end

  # @param [Hash] game
  def Bullets::tick_diff(game)
    # TODO: How do we do a deep_merge on an array of bullets without duplicating bullets?
    # Maybe each bullet could get a uuid, and we'd replace the array with a Hash{UUID=>Bullet}?
    {
        player_bullets: game[:bullets][:player_bullets]
                            .map { |b| b.deep_merge Bullet::tick_diff(b) } # Advance time for each existing bullet
                            .reject { |b| Bullet::despawn?(b, game) } # Discard bullets that should be despawned
                            .concat(Bullets::spawn_new_player_bullets(game[:player], game[:intent])), # Player fired bullets always exist for at least one tick.
        parametric_bullets: game[:bullets][:parametric_bullets]
                                .map { |b| b.deep_merge ParametricBullet::tick_diff(b) } # Advance time for each existing bullet
                                .reject { |b| ParametricBullet::despawn?(b, game) } # Discard bullets that should be despawned
                                .concat(Bullets::spawn_new_parametric_bullets(game))
    }
  end

  # @param [Hash] bullets
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Bullets::renderables(bullets)
    [
        bullets[:parametric_bullets].flat_map { |b| ParametricBullet::renderables(b) },
        bullets[:player_bullets].map { |b| Bullet::renderables(b) }
    ].flatten

  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] player_intent
  def Bullets::spawn_new_player_bullets(player, player_intent)
    return [] if (player[:attack][:cooldown] > 1) || player_intent[:shoot].compact.empty?
    direction = player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal]
    unit_v    = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }

    # Having bullets move slower if fired in the opposite direction of the player's movement
    #  is realistic in theory, but it feels really awkward and clunky to control in practice.
    #
    # The following mess of linear algebra makes sure the bullets only get a speed boost if
    #  fired in the same general direction of the player's velocity, while still allowing the
    #  player to angle shots by moving side to side.
    base_vel          = XYVector::scale(unit_v[direction], player[:stats][:total][:shot_speed])
    a                 = player[:vel]
    b                 = base_vel
    cos_theta         = (XYVector::dot(a, b) / (XYVector::abs(a) * XYVector::abs(b)))
    parallel_vel      = XYVector::scale(b, (XYVector::dot(a, b) / XYVector::dot(b, b)))
    perpendicular_vel = XYVector::sub(a, parallel_vel)
    adjustment_vector = cos_theta > 0 ? parallel_vel : {x: 0, y: 0}
    momentum_vector   = XYVector::scale(XYVector::add(perpendicular_vel, adjustment_vector), player[:attrs][:physics][:base_bullet_momentum])
    bullet_true_vel   = XYVector::add(momentum_vector, base_vel)
    eye_offset        = {
        true:  {
            up:    {x: 12.0, y: 88.0},
            down:  {x: 12.0, y: 44.0},
            left:  {x: -28.0, y: 44.0},
            right: {x: 28.0, y: 68.0},
        },
        false: {
            up:    {x: -12.0, y: 88.0},
            down:  {x: -12.0, y: 44.0},
            left:  {x: -28.0, y: 68.0},
            right: {x: 28.0, y: 44.0},
        },
    }
    pos               = XYVector.add(player[:pos], eye_offset[player[:attack][:left_eye].to_s.to_sym][direction])
    [
        Bullet::spawn(pos, bullet_true_vel, {
            bbox:  [pos[:x], pos[:y], 32, 32].anchor_rect(0.5, 0.5),
            stats: {
                damage: player[:stats][:total][:damage],
                range:  player[:stats][:total][:range]
            }
        }, {
                          #TODO: Put magic values somewhere better
                          w:          32,
                          h:          32,
                          path:       'sprites/bullets/standard.png',
                          angle_snap: 10
                      })
    ]
  end

  # @param [Object] game
  def Bullets::spawn_new_parametric_bullets(game)
    mod = 40
    return [] if $state.tick_count % mod != 0
    so = {
        path: 'sprites/bullets/parametric.png',
        r:    ($state.tick_count % (2*mod)) == 0 ? 150 : 1,
        g:    ($state.tick_count % (2*mod)) == 0 ? 1 : 150,
        b:    1
    }
    (1..6).map do |i|
      ParametricBullet::spawn(
          :radial_spin_out,
          {x: 640, y: 540},
          32,
          900,
          {
              n:            i,
              max_n:        6,
              turns:        2 * ($state.tick_count % (2*mod) == 0 ? 0.5 : -0.5),
              dist:         1800,
              offset_theta: 0.1 * Math::PI * $state.tick_count * ($state.tick_count % (2*mod) == 0 ? 1 : -1) / 30
          },
          16,
          so
      )
    end
  end


end