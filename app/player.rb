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
                base_accel:           0.35,
                base_friction:        0.85,
                base_bullet_momentum: 0.66,
                bbox:                 [640, 360, 64, 88].anchor_rect(0.5, 0)
            },
            attack:      {
                base_cooldown:   12,
                base_shot_speed: 8.0
            }
        }
    }
  end

  # @param [Hash] player_intent
  # @param [Hash] game
  def Player::tick_diff(game)
    out = {}
    out.deep_merge!(Player::update_vel(game[:player], game[:intent]))
    out.deep_merge!(Player::update_attack(game[:player], game[:intent]))
    out.deep_merge!(Player::update_facing(game[:player], game[:intent]))
    out.deep_merge!(Player::update_attrs(game[:player]))
    out.deep_merge!(Player::update_pos(game[:player])) if XYVector.abs(game[:player][:vel]) >= 0.001
    out
  end

  # @param [Hash] player
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def Player::renderables(player)
    bbox = {
        x:                player[:attrs][:physics][:bbox][0],
        y:                player[:attrs][:physics][:bbox][1],
        w:                player[:attrs][:physics][:bbox][2],
        h:                player[:attrs][:physics][:bbox][3],
        r:                0,
        g:                255,
        b:                0,
        a:                255,
        primitive_marker: :border
    }
    out  = []
    out.push bbox if $DEBUG
    out.append(player[:facing].map { |part, direction| Player::part_sprite(player, part, direction) })
  end

  # @param [Hash] player
  # @return [Hash] deep-mergeable sub-hash of player with updated values related to position
  def Player::update_pos(player)
    pos = XYVector.add(player[:pos], player[:vel])
    {
        pos:   pos,
        attrs: {
            physics: {
                bbox: [
                          pos[:x],
                          pos[:y],
                          player[:attrs][:physics][:bbox][2],
                          player[:attrs][:physics][:bbox][3]
                      ].anchor_rect(0.5, 0.05)
            }
        }
    }
  end

  # @param [Hash] player
  # @param [Hash] player_intent
  # @return [Hash] deep-mergeable sub-hash of player with updated values related to velocity
  def Player::update_vel(player, player_intent)
    unit_v  = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }
    raw_vel = player_intent[:move].compact
                                  .map { |_, direction| XYVector.scale(unit_v[direction], player[:attrs][:physics][:base_accel]) }
                                  .reduce(player[:vel]) { |acc, v| XYVector.add(acc, v) }
    limiter = XYVector.abs(raw_vel).fdiv(player[:attrs][:physics][:base_speed]).greater(1.0)
    lim_vel = XYVector.div(raw_vel, limiter)
    {
        vel: {
            x: lim_vel[:x] * ((player_intent[:move][:horizontal] != nil) ? 1.0 : player[:attrs][:physics][:base_friction]),
            y: lim_vel[:y] * ((player_intent[:move][:vertical] != nil) ? 1.0 : player[:attrs][:physics][:base_friction])
        }
    }
  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] player_intent
  # # @return [Hash] deep-mergeable sub-hash of player with updated values related to attack data
  def Player::update_attack(player, player_intent)
    out = {}
    if player[:attack][:cooldown] <= 1 && (player_intent[:shoot][:vertical] || player_intent[:shoot][:horizontal])
      out[:cooldown] = player[:attrs][:attack][:base_cooldown]
      out[:left_eye] = !player[:attack][:left_eye]
    elsif player[:attack][:cooldown] > 0
      out[:cooldown] = player[:attack][:cooldown] - 1
    end
    {
        attack: out
    }
  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] player_intent
  # @return [Hash] deep-mergeable sub-hash of player with updated values related to facing direction
  def Player::update_facing(player, player_intent)
    body_dir = player_intent[:move][:vertical] ||
        player_intent[:move][:horizontal] ||
        (XYVector.abs(player[:vel]) > 0.5 ? player[:facing][:body] : nil) ||
        player[:facing][:head]
    head_dir = player_intent[:shoot][:vertical] ||
        player_intent[:shoot][:horizontal] ||
        player_intent[:move][:vertical] ||
        player_intent[:move][:horizontal] ||
        (player[:attack][:cooldown] > 0 ? player[:facing][:head] : nil) ||
        :down
    {
        facing: {
            body: body_dir,
            head: head_dir,
            face: head_dir,
        }
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
  # # @return [Hash] deep-mergeable sub-hash of player with updated values related to attribute data
  def Player::update_attrs(player)
    min_rate = 8.0
    cooldown_progress = 2.0*((min_rate-(player[:attrs][:attack][:base_cooldown] - player[:attack][:cooldown])).fdiv(8.0))
    cooldown_eased    = 1-((0.0 + ((1.0-cooldown_progress) * (1.0-cooldown_progress))).clamp(0.0,1.0))
    cooldown_eased    = player[:attack][:cooldown].lesser(1) if player[:attrs][:attack][:base_cooldown] < min_rate
    {
        attrs: {
            render_size: {
                w: Player::initial_state[:attrs][:render_size][:w] + (cooldown_eased * 16).to_int,
                h: Player::initial_state[:attrs][:render_size][:h] - (cooldown_eased * 12).to_int
            }
        }
    }
  end
end