module Bullets

  def self::initial_state
    []
  end

  # @param [Hash] input
  # @param [Hash] game
  def Bullets::next_state(input, game)
    game[:bullets].map { |b| Bullet::next_state(b) } # Advance time for each existing bullet
                  .reject { |b| Bullet::despawn?(b, game) } # Discard bullets that should be despawned
                  .concat(Bullets::spawn_new_player_bullets(game[:player], input)) # Player fired bullets always exist for at least one tick.
  end

  # @param [Hash] bullets
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Bullets::renderables(bullets)
    bullets.map { |b| Bullet::renderables(b) }
  end

  # @param [Hash] player
  # @param [Hash] input
  def Bullets::spawn_new_player_bullets(player, input)
    return [] if (player[:attack][:cooldown] != 0) || (Player::shoot_direction(input) == nil)
    unit_v  = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }
    base_vel = XYVector::scale(unit_v[Player::shoot_direction(input)], player[:attrs][:attack][:base_shot_speed])
    a                 = player[:vel]
    b                 = base_vel
    cos_theta         = (XYVector::dot(a, b) / (XYVector::abs(a) * XYVector::abs(b)))
    parallel_vel      = XYVector::scale(b, (XYVector::dot(a, b) / XYVector::dot(b, b)))
    perpendicular_vel = XYVector::sub(a, parallel_vel)
    adjustment_vector = cos_theta > 0 ? parallel_vel : {x:0, y:0}
    momentum_vector   = XYVector::scale(XYVector::add(perpendicular_vel, adjustment_vector), player[:attrs][:physics][:base_bullet_momentum])
    bullet_true_vel   = XYVector::add(momentum_vector, base_vel)
    [
        Bullet::spawn(player[:pos], bullet_true_vel, {
            sprite: {
                #TODO: Put magic values somewhere better
                w: 32,
                h: 32,
                path: 'sprites/bullets/standard.png',
                angle_snap: 10.0
            }
        })
    ]
  end


end