module Bullets

  def self::initial_state
    []
  end

  # @param [Hash] player_intent
  # @param [Hash] game
  def Bullets::tick_diff(game)
    # TODO: How do we do a deep_merge on an array of bullets without duplicating bullets?
    # Maybe each bullet could get a uuid, and we'd replace the array with a Hash{UUID=>Bullet}?
    game[:bullets].map { |b| Bullet::tick_diff(b) } # Advance time for each existing bullet
                  .reject { |b| Bullet::despawn?(b, game) } # Discard bullets that should be despawned
                  .concat(Bullets::spawn_new_player_bullets(game[:player], game[:intent])) # Player fired bullets always exist for at least one tick.
  end

  # @param [Hash] bullets
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Bullets::renderables(bullets)
    bullets.map { |b| Bullet::renderables(b) }
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
            sprite: {
                #TODO: Put magic values somewhere better
                w:          32,
                h:          32,
                path:       'sprites/bullets/standard.png',
                angle_snap: 10.0
            },
            bbox:   [pos[:x], pos[:y], 32, 32].anchor_rect(0.5, 0.5),
            stats: {
                damage: player[:stats][:total][:damage],
                range: player[:stats][:total][:range]
            }
        })
    ]
  end


end