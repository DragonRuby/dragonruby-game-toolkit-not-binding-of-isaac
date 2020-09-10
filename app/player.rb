module Player
  # @return [Hash]
  def Player::initial_state
    {
        pos:     {x: 640.0, y: 360.0},
        vel:     {x: 0.0, y: 0.0},
        attack:  {
            cooldown: 0,
            left_eye: true
        },
        facing:  {
            body: :down,
            head: :down,
            face: :down
        },
        sprites: {
            body: {
                down:  'sprites/player/body_y.png',
                up:    'sprites/player/body_y.png',
                left:  'sprites/player/body_left.png',
                right: 'sprites/player/body_right.png',
            },
            face: {
                down:  'sprites/player/face_down.png',
                up:    'sprites/player/face_up.png',
                left:  'sprites/player/face_left.png',
                right: 'sprites/player/face_right.png'
            },
            head: {
                down:  'sprites/player/head_down.png',
                up:    'sprites/player/head_up.png',
                left:  'sprites/player/head_left.png',
                right: 'sprites/player/head_right.png'
            },
            health: {
                full: 'sprites/health/full.png',
                half: 'sprites/health/half.png',
                empty: 'sprites/health/empty.png',
                soul_full: 'sprites/health/soul-full.png',
                soul_half: 'sprites/health/soul-half.png'
            }
        },
        attrs:   {
            render_size: {
                w: 64,
                h: 128
            },
            physics:     {
                base_speed:           5.0,
                base_accel:           0.5,
                base_friction:        0.85,
                base_bullet_momentum: 0.66,
                bbox:                 [640, 360, 64, 88].anchor_rect(0.5, 0)
            },
            attack:      {
                base_cooldown:   12,
                base_shot_speed: 8.0
            },
            health:      { # Max health can be calculated from items
                normal: 6,
                soul: 0
            }
        }
    }
  end

  # @param [Hash] player_intent
  # @param [Hash] game
  def Player::next_state(game)
    pos     = Player::next_pos(game[:player])
    vel     = Player::next_vel(game[:player], game[:intent])
    attack  = Player::next_attack(game[:player], game[:intent])
    facing  = Player::next_facing(game[:intent])
    sprites = game[:player][:sprites] #Const for now
    attrs   = Player::next_attrs(game[:player], pos)
    {
        pos:     pos,
        vel:     vel,
        attack:  attack,
        facing:  facing,
        sprites: sprites,
        attrs:   attrs
    }
  end

  # @param [Hash] player
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Player::renderables(player)
    debug_outline = $DEBUG ? [{
                                  x:                player[:attrs][:physics][:bbox][0],
                                  y:                player[:attrs][:physics][:bbox][1],
                                  w:                player[:attrs][:physics][:bbox][2],
                                  h:                player[:attrs][:physics][:bbox][3],
                                  r:                0,
                                  g:                255,
                                  b:                0,
                                  a:                255,
                                  primitive_marker: :border
                              }] : []

    # Calc health sprites
    # Calc number of full hearts is
    num_full = (player[:attrs][:health][:normal] / 2).floor
    # Render fulls
    health = (0...num_full).map do |i|
        health_primitive(i+1, player[:sprites][:health][:full])
    end
    # Render half
    if player[:attrs][:health][:normal] % 2 == 1
        num_full += 1
        health.push(health_primitive(num_full, player[:sprites][:health][:half]))
    end
    # Render emptys
    (num_full+1..max_health(player)/2).each do |i|
        health.push(health_primitive(i, player[:sprites][:health][:empty]))
    end

    [
        *debug_outline,
        *player[:facing].map { |part, direction| Player::part_sprite(player, part, direction) },
        *health
    ]
  end

  # @param [Hash] player
  # @return [Hash{Symbol->Float}] pos
  def Player::next_pos(player)
    XYVector.add(player[:pos], player[:vel])
  end

  # @param [Hash] player
  # @param [Hash] player_intent
  # @return [Hash{Symbol->Float}] vel
  def Player::next_vel(player, player_intent)
    unit_v  = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }
    raw_vel = player_intent[:move].compact.map { |_, direction| unit_v[direction] }
                                  .reduce(player[:vel]) { |acc, v| XYVector.add(acc, v) }
    limiter = XYVector.abs(raw_vel).fdiv(player[:attrs][:physics][:base_speed]).greater(1.0)
    lim_vel = XYVector.div(raw_vel, limiter)
    vel     = {
        x: lim_vel[:x] * ((player_intent[:move][:horizontal] != nil) ? 1.0 : player[:attrs][:physics][:base_friction]),
        y: lim_vel[:y] * ((player_intent[:move][:vertical] != nil) ? 1.0 : player[:attrs][:physics][:base_friction])
    }
    vel
  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] player_intent
  def Player::next_attack(player, player_intent)
    {
        cooldown: if player[:attack][:cooldown] == 0 && (player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal])
                    player[:attrs][:attack][:base_cooldown]
                  else
                    (player[:attack][:cooldown] - 1).greater(0)
                  end,
        left_eye: if player[:attack][:cooldown] == 0 && (player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal])
                    !player[:attack][:left_eye]
                  else
                    player[:attack][:left_eye]
                  end
    }
  end

  # @param [Hash{Symbol=>Hash}] player_intent
  def Player::next_facing(player_intent)
    head_dir = player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal] || :down
    body_dir = player_intent[:move][:vertical] || player_intent[:move][:horizontal] || :down
    {
        body: body_dir,
        head: head_dir,
        face: head_dir,
    }
  end

  # @param [Hash] player
  # @param [Symbol] part The body part to build a sprite for
  # @param [Symbol] direction The direction the body part is facing
  def Player::part_sprite(player, part, direction)
    {
        x:    player[:pos][:x],
        y:    player[:pos][:y],
        w:    player[:attrs][:render_size][:w],
        h:    player[:attrs][:render_size][:h],
        path: player[:sprites][part][direction]
    }.anchor_rect(-0.5, 0.0)
  end

  # @param [Hash] player
  # @param [Hash] new_pos
  def Player::next_attrs(player, new_pos)
    # Merge to keep unchanged attrs
    player[:attrs].merge ({
        render_size: player[:attrs][:render_size],
        physics:     {
            base_speed:           player[:attrs][:physics][:base_speed],
            base_accel:           player[:attrs][:physics][:base_accel],
            base_friction:        player[:attrs][:physics][:base_friction],
            base_bullet_momentum: player[:attrs][:physics][:base_bullet_momentum],
            bbox:                 [new_pos[:x], new_pos[:y], player[:attrs][:physics][:bbox][2], player[:attrs][:physics][:bbox][3]].anchor_rect(0.5, 0.05)
        },
        attack:      player[:attrs][:attack]
    })
  end

  # @param [Hash] player
  # @return [Int] max_health
  def Player::max_health(player)
      # TODO: Calculate based on player items
      6
  end

  def Player::health_primitive(offset, path, y: 10)
    {
        x: offset*50 + 100,
        y: y,
        w: 40,
        h: 40,
        path: path
    }
  end
end
