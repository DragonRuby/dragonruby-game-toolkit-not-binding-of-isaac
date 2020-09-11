module Bullets

  # @return [Array] The initial array of bullets.
  def self::initial_state
    [] # Since there would be no bullets on screen at the start of a new game, just return an empty array
  end

  # @param [Hash] player_intent
  # @param [Hash] game
  # @return [Array] The array of bullets for the next state.
  def Bullets::next_state(game)
    game[:bullets].map { |b| Bullet::next_state(b) } # Update the state of all bullets on screen.
                  .reject { |b| Bullet::despawn?(b, game) } # If a bullet is supposed to be despawned, don't include it in the array of bullets for the next state.
                  .concat(Bullets::spawn_new_player_bullets(game[:player], game[:intent])) # Spawn the bullets fired by the player.
    # Another `.concat` for enemy fired bullets would go here.
  end

  # @param [Hash] bullets
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Bullets::renderables(bullets)
    bullets.map { |b| Bullet::renderables(b) }
  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] player_intent
  # @return [Array] The list of bullets to fire. This is a collection, as you may want to add multi-shot upgrades.
  def Bullets::spawn_new_player_bullets(player, player_intent)
    # If the player is still on fire cooldown or doesn't want to fire, just return an empty array.
    return [] if (player[:attack][:cooldown] != 0) || player_intent[:shoot].compact.empty?

    # For now, we just want to fire one bullet, either vertically or horizontally.
    direction = player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal]

    # Unit vectors in the directions we can fire a bullet
    unit_v = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }

    # The base velocity of the bullet is a unit vector scaled by the player's base shot speed
    # If there were shot speed upgrades, they'd be applied here, or velocity would be scaled by some other value.
    base_vel = XYVector::scale(unit_v[direction], player[:attrs][:attack][:base_shot_speed])

    # Having bullets move slower if fired in the opposite direction of the player's movement
    #  is realistic in theory, but it feels really awkward and clunky to control in practice.
    #
    # The following mess of linear algebra makes sure the bullets only get a speed boost if
    #  fired in the same general direction of the player's velocity, while still allowing the
    #  player to angle shots by moving side to side.
    a = player[:vel]
    b = base_vel
    # This is the cosine of the angle formed by the player's velocity vector and the bullet's velocity vector
    cos_theta = (XYVector::dot(a, b) / (XYVector::abs(a) * XYVector::abs(b)))
    # This is the portion of the player's velocity vector going in the same direction as the bullet's velocity vector.
    parallel_vel = XYVector::scale(b, (XYVector::dot(a, b) / XYVector::dot(b, b)))
    # This is the portion of the player's velocity vector going in an perpendicular direction to the bullet's velocity vector.
    # If a player wants to "hook" a shot by running to the side, this vector is the sideways velocity.
    perpendicular_vel = XYVector::sub(a, parallel_vel)
    # If cos_theta is greater than zero, that means the player is moving in the same direction as the fired bullet. Thus, we should boost the bullet's speed.
    # If cos_theta is less than or equal to zero, we don't want to slow the bullet down. Therefore, we just use <0,0> as the adjustment vector.
    adjustment_vector = cos_theta > 0 ? parallel_vel : {x: 0, y: 0}
    # The momentum vector is just adding the perpendicular velocity and the adjusted parallel velocity back together, multiplied by a small value.
    momentum_vector = XYVector::scale(XYVector::add(perpendicular_vel, adjustment_vector), player[:attrs][:physics][:base_bullet_momentum])
    # By adding the momentum vector and the velocity vector, we get the actual velocity vector for the bullet.
    bullet_true_vel = XYVector::add(momentum_vector, base_vel)

    # By alternating the "eye" the bullet is fired from, the projectiles are spread out a little.
    # This reduces accuracy, but makes it easier to hit enemies when using "spray and pray" tactics.
    eye_offset = {
        true:  {
            up:    {x: 12.0, y: 64.0},
            down:  {x: 12.0, y: 44.0},
            left:  {x: -16.0, y: 36.0},
            right: {x: 16.0, y: 60.0},
        },
        false: {
            up:    {x: -12.0, y: 64.0},
            down:  {x: -12.0, y: 44.0},
            left:  {x: -16.0, y: 60.0},
            right: {x: 16.0, y: 36.0},
        },
    }
    pos        = XYVector.add(player[:pos], eye_offset[player[:attack][:left_eye].to_s.to_sym][direction])
    [
        # Create a new bullet
        Bullet::spawn(pos, bullet_true_vel, {
            sprite: {
                #TODO: Put magic values somewhere better
                w:          32,
                h:          32,
                path:       'sprites/bullets/standard.png',
                angle_snap: 10.0 # Allowing arbitrary angles tends to look ugly.
            },
            bbox:   [pos[:x], pos[:y], 32, 32].anchor_rect(0.5, 0.5) # Used for collision detection.
        })
    ]
  end


end