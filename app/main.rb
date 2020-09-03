require 'app/constants.rb'

unless respond_to?(:trace!)
  def trace!; end
end

class XYVector
  #@type [Float]
  attr_accessor :x
  #@type [Float]
  attr_accessor :y

  # @param [Float] x
  # @param [Float] y
  def initialize(x = 0.0, y = 0.0)
    #@type [Float]
    @x = x.to_f
    #@type [Float]
    @y = y.to_f
  end

  # @param [XYVector] lhs
  def +(lhs)
    XYVector.new(@x + lhs.x, @y + lhs.y)
  end

  # @param [XYVector] lhs
  def -(lhs)
    XYVector.new(@x - lhs.x, @y - lhs.y)
  end

  # @param [Float, XYVector] lhs
  # @return [XYVector, Float] Returns scaled vector if lhs is a scalar, and dot product if lhs is a vector.
  def *(lhs)
    return (@x * lhs.x + @y * lhs.y) if lhs.is_a? XYVector # Dot product
    XYVector.new(@x * lhs, @y * lhs) # Scalar multiplication
  end

  # @param [Numeric] lhs
  def /(lhs)
    XYVector.new(@x / lhs, @y / lhs)
  end

  # @return [Float]
  def len
    Math.sqrt(@y ** 2 + @x ** 2)
  end

  def serialize; { x: x, y: y }; end
  def inspect; serialize.to_s end
  def to_s; serialize.to_s; end
end


class Sprite
  
  attr_sprite
  def initialize(w, h)
    @w = w
    @h = h
  end
end

class Bullet
  attr_accessor :sprite, :pos, :vel

  # @param [XYVector] pos
  # @param [XYVector] vel
  def initialize(pos, vel)
    trace! if TRACING_ENABLED
    @sprite = Sprite.new BULLET_SPRITE_SIZE, BULLET_SPRITE_SIZE
    @sprite.path = BULLET_SPRITE_PATH
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
    
    @pos - XYVector.new(@sprite.w, @sprite.h) * 0.5
  end
end

class Player
  attr_accessor :sprites, :fire_cooldown
  #@type [XYVector]
  attr_accessor :pos

  
  # @param [XYVector] pos
  def initialize(pos)
    #@type [XYVector]
    @pos = pos
    @vel = XYVector.new
    @fire_cooldown = 0

    trace! if TRACING_ENABLED
    #player uses three layers of sprites: head_sprite, body_sprite, face_sprite
    @sprites = {
        body: Sprite.new(PLAYER_SPRITE_W,PLAYER_SPRITE_H),
        head: Sprite.new(PLAYER_SPRITE_W,PLAYER_SPRITE_H),
        face: Sprite.new(PLAYER_SPRITE_W,PLAYER_SPRITE_H),
    }
    turn( :body, :down)
    turn( :head, :down)
    turn( :face, :down)

    #Since body_sprite will need to be animated at some point I am leaving these here
    #@sprites[:body].tile_x = 0
    #@sprites[:body].tile_y = 0
    #@sprites[:body].tile_w = PLAYER_SPRITE_W
    #@sprites[:body].tile_h = PLAYER_SPRITE_H
    #
  end

  def turn(part, direction)
    @sprites[part].path = PLAYER_SPRITES[part][direction]
  end

  #Sprite functions. can all these be put together somehow?
  def offset_sprite part
    @sprites[part].x = offset.x
    @sprites[part].y = offset.y
    @sprites[part]
  end

  
  def offset
    @pos - XYVector.new(PLAYER_SPRITE_W.to_f, PLAYER_SPRITE_H.to_f) * 0.5
  end

  def shoot(direction)

    turn(:head, direction) if direction != :none
    #items will modify these beyond direction. will need their own function
    turn(:face, direction) if direction != :none

    #fire the bullet
    return nil if (@fire_cooldown -= 1) > 0 || direction == :none
    @fire_cooldown = BULLET_COOLDOWN
    b_vel = nil
    b_vel = XYVector.new(BULLET_SPEED, 0.0) if direction == :right
    b_vel = XYVector.new(-BULLET_SPEED, 0.0) if direction == :left
    b_vel = XYVector.new(0.0, BULLET_SPEED) if direction == :up
    b_vel = XYVector.new(0.0, -BULLET_SPEED) if direction == :down
    if b_vel
      Bullet.new(@pos, b_vel + @vel * BULLET_MOMENTUM)
    end
  end

  # @param [XYVector] direction
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

    turn(:body, direction) if direction != :none

  end
end

class Game
  attr_accessor :player, :bullets
  
  def initialize
    trace! if TRACING_ENABLED

    @player = Player.new XYVector.new(640.0, 360.0)

    @bullets = []
  end

  
  def get_move_dir(keyboard) # TODO: Don't use XYVector to represent anything that isn't an ACTUAL VECTOR!!!
    dir = XYVector.new
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

  # @param [Object] args
  def tick(args)
    player.move get_move_dir args.inputs.keyboard.key_held
    bullet = player.shoot get_shoot_dir args.inputs.keyboard.key_held
    @bullets << bullet if bullet
    # Todo: Find a more efficient method.
    @bullets = @bullets.each { |b| b.tick }
                   .find_all { |b| b.pos.x.between?(0 - BULLET_DESPAWN_RANGE, 1280 + BULLET_DESPAWN_RANGE) && b.pos.y.between?(0 - BULLET_DESPAWN_RANGE, 720 + BULLET_DESPAWN_RANGE) } # Check if bullet is on-screen
  end
end

$game = Game.new

def tick(args)
  $game.tick args
  args.outputs.background_color = [128, 128, 128]
  args.outputs.sprites << $game.player.offset_sprite(:body) #Todo: static sprites?
  args.outputs.sprites << $game.player.offset_sprite(:head) #Todo: static sprites?
  args.outputs.sprites << $game.player.offset_sprite(:face) #Todo: static sprites?
  args.outputs.sprites << $game.bullets.map { |b| b.sprite } # Todo: static sprites?
  args.outputs.labels << [10, 30, "FPS: #{args.gtk.current_framerate.to_s.to_i}", 255, 0, 0, 255]
end
