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
                bbox: [640,360,64,126]
            },
            attack:      {
                base_cooldown:   12,
                base_shot_speed: 8.0
            }
        }
    }
  end

  # @param [Hash] input
  # @param [Hash] game
  def Player::next_state(input, game)
    pos     = Player::next_pos(game[:player])
    vel     = Player::next_vel(game[:player], input)
    attack  = Player::next_attack(game[:player], input)
    facing  = Player::next_facing(input)
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
    debug_outline = [{
         x:                player[:attrs][:physics][:bbox][0],
         y:                player[:attrs][:physics][:bbox][1],
         w:                player[:attrs][:physics][:bbox][2],
         h:                player[:attrs][:physics][:bbox][3],
         r:                0,
         g:                255,
         b:                0,
         a:                255,
         primitive_marker: :border
     }]
    debug_outline.append(player[:facing].map { |part, direction| Player::part_sprite(player, part, direction) })
  end

  # @param [Hash] player
  # @return [Hash{Symbol->Float}] pos
  def Player::next_pos(player)
    XYVector.add(player[:pos], player[:vel])
  end

  # @param [Hash] player
  # @param [Hash] input
  # @return [Hash{Symbol->Float}] vel
  def Player::next_vel(player, input)
    unit_v  = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }
    raw_vel = input[:walk].map { |dir, active| XYVector.scale(unit_v[dir], (active ? player[:attrs][:physics][:base_accel] : 0.0)) }
                          .reduce(player[:vel]) { |acc, v| XYVector.add(acc, v) }
    limiter = XYVector.abs(raw_vel).fdiv(player[:attrs][:physics][:base_speed]).greater(1.0)
    lim_vel = XYVector.div(raw_vel, limiter)
    {
        x: lim_vel[:x] * ((input[:walk][:left] || input[:walk][:right]) ? 1.0 : player[:attrs][:physics][:base_friction]),
        y: lim_vel[:y] * ((input[:walk][:up] || input[:walk][:down]) ? 1.0 : player[:attrs][:physics][:base_friction])
    }

  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] input
  def Player::next_attack(player, input)
    {
        cooldown: if player[:attack][:cooldown] == 0 && input[:shoot].values.any?
                    player[:attrs][:attack][:base_cooldown]
                  else
                    (player[:attack][:cooldown] - 1).greater(0)
                  end,
        left_eye: if player[:attack][:cooldown] == 0 && input[:shoot].values.any?
                    !player[:attack][:left_eye]
                  else
                    player[:attack][:left_eye]
                  end
    }
  end

  # @param [Hash] input
  def Player::shoot_direction(input)
    if input[:shoot][:up] == input[:shoot][:down]
      if input[:shoot][:left] == input[:shoot][:right]
        nil
      else
        input[:shoot][:left] ? :left : :right
      end
    else
      input[:shoot][:up] ? :up : :down
    end
  end

  def Player::move_direction(input)
    if input[:walk][:up] || input[:walk][:down]
      input[:walk][:up] ? :up : :down
    elsif input[:walk][:right] || input[:walk][:left]
      input[:walk][:right] ? :right : :left
    else
      nil
    end
  end

  # @param [Hash{Symbol=>Hash}] input
  def Player::next_facing(input)
    shoot_dir = Player::shoot_direction(input)
    move_dir  = Player::move_direction(input)
    {
        body: move_dir || :down,
        head: shoot_dir || move_dir || :down,
        face: shoot_dir || move_dir || :down,
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

  def Player::next_attrs(player, new_pos)
    {
        render_size: player[:attrs][:render_size],
        physics:     {
            base_speed:           player[:attrs][:physics][:base_speed],
            base_accel:           player[:attrs][:physics][:base_accel],
            base_friction:        player[:attrs][:physics][:base_friction],
            base_bullet_momentum: player[:attrs][:physics][:base_bullet_momentum],
            bbox: [new_pos[:x],new_pos[:y],player[:attrs][:physics][:bbox][2],player[:attrs][:physics][:bbox][3]]
        },
        attack:      player[:attrs][:attack]
    }
  end
end