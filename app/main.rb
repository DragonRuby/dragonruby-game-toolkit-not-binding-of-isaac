require 'app/constants.rb'

class XYPair
  attr_accessor :x, :y

  def initialize(x = nil, y = nil)
    @x = x
    @y = y
  end

  def +(o)
    XYPair.new(@x + o.x, @y + o.y)
  end

  def -(o)
    XYPair.new(@x - o.x, @y - o.y)
  end

  def *(scalar)
    XYPair.new(@x * scalar, @y * scalar)
  end

  def /(scalar)
    XYPair.new(@x / scalar, @y / scalar)
  end

  def len
    Math.sqrt(@y ** 2 + @x ** 2)
  end
end

class Sprite
  #noinspection RubyResolve
  attr_sprite
end

class Bullet
  attr_accessor :sprite, :pos, :vel

  # @param [XYPair] pos
  # @param [XYPair] vel
  def initialize(pos, vel)
    trace! if TRACING_ENABLED
    @sprite = Sprite.new
    @sprite.path = BULLET_SPRITE_PATH
    @sprite.w = BULLET_SPRITE_SIZE
    @sprite.h = BULLET_SPRITE_SIZE
    @sprite.r = 0
    @sprite.g = 0
    @sprite.b = 0
    @pos = pos
    @vel = vel
  end

  def sprite
    @sprite.x = offset.x
    @sprite.y = offset.y
    @sprite
  end

  def tick
    @pos += @vel
  end

  def offset
    @pos - XYPair.new(@sprite.w, @sprite.h) * 0.5
  end
end

class Player
  attr_accessor :sprite, :pos, :fire_cooldown
  # @param [XYPair] pos
  def initialize(pos)
    trace! if TRACING_ENABLED
    @sprite = Sprite.new
    @sprite.path = PLAYER_SPRITE_PATH
    @sprite.w = PLAYER_SPRITE_SIZE
    @sprite.h = PLAYER_SPRITE_SIZE
    @pos = pos
    @vel = XYPair.new(0, 0)
    @fire_cooldown = 0
  end

  def sprite
    @sprite.x = offset.x
    @sprite.y = offset.y
    @sprite
  end

  def offset
    @pos - XYPair.new(@sprite.w, @sprite.h) * 0.5
  end

  def shoot(direction)
    return nil if (@fire_cooldown -= 1) > 0 || direction == :none
    @fire_cooldown = BULLET_COOLDOWN
    b_vel = nil
    b_vel = XYPair.new(BULLET_SPEED, 0) if direction == :right
    b_vel = XYPair.new(-BULLET_SPEED, 0) if direction == :left
    b_vel = XYPair.new(0, BULLET_SPEED) if direction == :up
    b_vel = XYPair.new(0, -BULLET_SPEED) if direction == :down
    if b_vel
      return Bullet.new(@pos, b_vel + @vel * BULLET_MOMENTUM)
    end
  end

  # @param [XYPair] direction
  def move(direction)
    @vel.x = (@vel.x + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.x == :right
    @vel.x = (@vel.x - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.x == :left
    @vel.y = (@vel.y + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.y == :up
    @vel.y = (@vel.y - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.y == :down
    diagonal_comp = PLAYER_SPEED_LIMIT / @vel.len
    @vel *= diagonal_comp if diagonal_comp < 1.0
    @vel.x *= PLAYER_FRICT if direction.x == :none
    @vel.y *= PLAYER_FRICT if direction.y == :none
    @pos += @vel
  end
end

class Game
  attr_accessor :player, :bullets

  def initialize
    trace! if TRACING_ENABLED
    @player = Player.new XYPair.new(640, 360)
    @bullets = []
  end

  def get_move_dir(keyboard)
    dir = XYPair.new
    dir.x = if keyboard.a == keyboard.d
              :none
            else
              keyboard.a ? :left : :right
            end
    dir.y = if keyboard.w == keyboard.s
              :none
            else
              keyboard.w ? :up : :down
            end
    dir
  end

  def get_shoot_dir(keyboard)
    if keyboard.up == keyboard.down
      if keyboard.left == keyboard.right
        :none
      else
        keyboard.left ? :left : :right
      end
    else
      keyboard.up ? :up : :down
    end
  end

  # @param [AttrGTK] args
  def tick(args)
    player.move get_move_dir args.inputs.keyboard.key_held
    bullet = player.shoot get_shoot_dir args.inputs.keyboard.key_held
    @bullets << bullet if bullet
    # Todo: Find a more efficient method.
    @bullets = @bullets.each { |b| b.tick }
                   .find_all { |b| b.pos.x.between?(0 - DSPWN_RNG, 1280 + DSPWN_RNG) && b.pos.y.between?(0 - DSPWN_RNG, 720 + DSPWN_RNG) } # Check if bullet is on-screen
  end
end

$game = Game.new

def tick(args)
  $game.tick args
  args.outputs.background_color = [128, 128, 128]
  args.outputs.sprites << $game.bullets.map { |b| b.sprite } # Todo: static sprites?
  args.outputs.sprites << $game.player.sprite #Todo: static sprites?
  args.outputs.labels << [10, 30, "FPS: #{args.gtk.current_framerate.to_s.to_i}", 255, 0, 0, 255]
end
