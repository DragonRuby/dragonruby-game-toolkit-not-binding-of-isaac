require 'app/constants.rb'

class XYPair
  attr_accessor :x, :y

  def initialize(x = nil, y = nil)
    @x = x
    @y = y
  end
end

class Sprite
  #noinspection RubyResolve
  attr_sprite
end

class Bullet
  attr_accessor :sprite, :x, :y, :vel_x, :vel_y
  # @param [Integer, Float] x
  # @param [Integer, Float] y
  # @param [Integer, Float] vel_x
  # @param [Integer, Float] vel_y
  def initialize(x, y, vel_x, vel_y)
    @sprite = Sprite.new
    @sprite.path = BULLET_SPRITE_PATH
    @sprite.w = BULLET_SPRITE_SIZE
    @sprite.h = BULLET_SPRITE_SIZE
    @sprite.r = 0
    @sprite.g = 0
    @sprite.b = 0
    @x = x
    @y = y
    @vel_x = vel_x
    @vel_y = vel_y
  end

  def sprite
    @sprite.x = @x - (@sprite.w / 2)
    @sprite.y = @y - (@sprite.h / 2)
    @sprite
  end

  def tick
    @x += @vel_x
    @y += @vel_y
  end

  def center
    [@x - (@sprite.w / 2), @y - (@sprite.h / 2)]
  end
end

class Player
  attr_accessor :sprite, :x, :y, :fire_cooldown
  # @param [Integer, Float] x
  # @param [Integer, Float] y
  def initialize(x, y)
    @sprite = Sprite.new
    @sprite.path = PLAYER_SPRITE_PATH
    @sprite.w = PLAYER_SPRITE_SIZE
    @sprite.h = PLAYER_SPRITE_SIZE
    @x = x
    @y = y
    @x_vel = 0
    @y_vel = 0
    @fire_cooldown = 0
  end

  def sprite
    @sprite.x = @x - (@sprite.w / 2)
    @sprite.y = @y - (@sprite.h / 2)
    @sprite
  end

  def center
    [@x + (@sprite.w / 2), @y + (@sprite.h / 2)]
  end

  def shoot(direction)
    return nil if (@fire_cooldown -= 1) > 0
    @fire_cooldown = BULLET_COOLDOWN
    return Bullet.new(x, y, BULLET_SPEED, 0) if direction == :right
    return Bullet.new(x, y, -BULLET_SPEED, 0) if direction == :left
    return Bullet.new(x, y, 0, BULLET_SPEED) if direction == :up
    return Bullet.new(x, y, 0, -BULLET_SPEED) if direction == :down
  end

  # @param [XYPair] direction
  def move(direction)
    @x_vel = (@x_vel + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.x == :right
    @x_vel = (@x_vel - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.x == :left
    @y_vel = (@y_vel + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.y == :up
    @y_vel = (@y_vel - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if direction.y == :down
    diagonal_comp = PLAYER_SPEED_LIMIT / Math.sqrt(@y_vel ** 2 + @x_vel ** 2)
    @x_vel *= diagonal_comp if diagonal_comp < 1.0
    @y_vel *= diagonal_comp if diagonal_comp < 1.0
    @x_vel *= PLAYER_FRICT if direction.x == :none
    @y_vel *= PLAYER_FRICT if direction.y == :none
    @x += @x_vel
    @y += @y_vel
  end
end

class Game
  attr_accessor :player, :bullets

  def initialize
    @player = Player.new(640, 360)
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
    b = player.shoot get_shoot_dir args.inputs.keyboard.key_held
    bullets << b if b
    bullets.each { |bu| bu.tick }
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
