module Player
  # @return [Hash]
  def self.initial_state
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
                base_speed: 5.0,
                base_accel: 0.5,
                base_frict: 0.85
            },
            attack:      {
                base_cooldown: 12
            }
        }
    }
  end

  # @param [Hash] input
  # @param [Hash] game
  def self.next_state(input, game)
    pos     = Player.next_pos(game[:player])
    vel     = Player.next_vel(game[:player], input)
    attack  = Player.next_attack(game[:player], input)
    facing  = Player.next_facing(input)
    sprites = game[:player][:sprites] #Const for now
    attrs   = game[:player][:attrs] #Const for now
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
  def self.renderables(player)
    player[:facing].map { |part, direction| Player.part_sprite(player, part, direction) }
  end

  private

  # @param [Hash] player
  # @return [Hash{Symbol->Float}] pos
  def self.next_pos(player)
    XYVector.add(player[:pos], player[:vel])
  end

  # @param [Hash] player
  # @param [Hash] input
  # @return [Hash{Symbol->Float}] vel
  def self.next_vel(player, input)
    unit_v  = {
        up:    {x: 0.0, y: 1.0},
        down:  {x: 0.0, y: -1.0},
        left:  {x: -1.0, y: 0.0},
        right: {x: 1.0, y: 0.0},
    }
    raw_vel = input[:walk].map { |dir, active| XYVector.mul(unit_v[dir], (active ? player[:attrs][:physics][:base_accel] : 0.0)) }
                          .reduce(player[:vel]) { |acc, v| XYVector.add(acc, v) }
    limiter = XYVector.abs(raw_vel).fdiv(player[:attrs][:physics][:base_speed]).greater(1.0)
    lim_vel = XYVector.div(raw_vel, limiter)
    {
        x: lim_vel[:x] * ((input[:walk][:left] || input[:walk][:right]) ? 1.0 : player[:attrs][:physics][:base_frict]),
        y: lim_vel[:y] * ((input[:walk][:up] || input[:walk][:down]) ? 1.0 : player[:attrs][:physics][:base_frict])
    }

  end

  # @param [Hash] player
  # @param [Hash{Symbol=>Hash}] input
  def self.next_attack(player, input)
    {
        cooldown: if player[:attack][:cooldown] == 0 && input[:shoot].values.any?
                    player[:attrs][:attack][:base_cooldown]
                  else
                    player[:attack][:cooldown].greater(0)
                  end,
        left_eye: if player[:attack][:cooldown] == 0 && input[:shoot].values.any?
                    !player[:attack][:left_eye]
                  else
                    player[:attack][:left_eye]
                  end
    }
  end

  # @param [Hash{Symbol=>Hash}] input
  def self.next_facing(input)
    shoot_dir = if input[:shoot][:up] == input[:shoot][:down]
                  if input[:shoot][:left] == input[:shoot][:right]
                    nil
                  else
                    input[:shoot][:left] ? :left : :right
                  end
                else
                  input[:shoot][:up] ? :up : :down
                end
    move_dir  = if input[:walk][:up] || input[:walk][:down]
                  input[:walk][:up] ? :up : :down
                elsif input[:walk][:right] || input[:walk][:left]
                  input[:walk][:right] ? :right : :left
                else
                  nil
                end
    {
        body: move_dir || :down,
        head: shoot_dir || move_dir || :down,
        face: shoot_dir || move_dir || :down,
    }
  end

  # @param [Hash] player
  # @param [Symbol] part The body part to build a sprite for
  # @param [Symbol] direction The direction the body part is facing
  def self.part_sprite(player, part, direction)
    {
        x:    player[:pos][:x],
        y:    player[:pos][:y],
        w:    player[:attrs][:render_size][:w],
        h:    player[:attrs][:render_size][:h],
        path: player[:sprites][part][direction]
    }.anchor_rect(-0.5, 0.0)
  end

end