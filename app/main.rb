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

# * FIXME: consider using data + functions over classes
# Why a bullets class when something like the
# following would be sufficient and is immediately serializable to disk
# #+begin_src ruby
#   def new_bullet args, vel_x, vel_y
#    args.state.bullets << (args.state.new_entity :bullet,
#                                                 x: args.state.player.x,
#                                                 y: args.state.player.y,
#                                                 w: args.state.bullet_size,
#                                                 h: args.state.bullet_size,
#                                                 path: args.state.bullet_sprite_path,
#                                                 vel_x: vel_x,
#                                                 vel_y: vel_y)
#   end
#
#   def calc_bullets args
#     args.bullets.each do |b|
#       b.x += b.vel_x
#       b.y += b.vel_y
#     end
#   end
#
#   def render_bullets args
#     # Note: you can use ~Primitive#anchor_rect~ instead of calculating the
#     #       offset manually
#     args.outputs.sprites << args.bullets.map { |b| b.anchor_rect 0.5, 0.5 }
#   end
# #+end_src
class Bullet
  attr_accessor :sprite, :pos, :vel

  # @param [XYPair] pos
  # @param [XYPair] vel
  def initialize(pos, vel)
    # * FIXME: use ~args.state~ over constants.
    # I generally put everything in ~args.state~ instead of using constants. You want
    # pretty much the entire game to serialize to disk. Take a look at the 02_collision_02_moving_objects
    # sample app's ~fiddle~ method.
    trace! if TRACING_ENABLED
    @sprite = Sprite.new
    @sprite.path = BULLET_SPRITE_PATH
    @sprite.w = BULLET_SPRITE_SIZE
    @sprite.h = BULLET_SPRITE_SIZE
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

# * FIXME: consider using data + functions over classes
# Why a Player class when something like the when using ~args.state~ + functions is immediately
# serializable to disk? See bullets comments above.
class Player
  attr_accessor :sprites, :pos, :fire_cooldown
  # @param [XYPair] pos
  def initialize(pos)
    trace! if TRACING_ENABLED
    #player uses three layers of sprites: head_sprite, body_sprite, face_sprite
    @head_sprite = Sprite.new
    @head_sprite.path = PLAYER_HEAD_DOWN_SPRITE_PATH
    @head_sprite.w = PLAYER_SPRITE_W
    @head_sprite.h = PLAYER_SPRITE_H

    @body_sprite = Sprite.new
    @body_sprite.path = PLAYER_BODY_X_SPRITE_PATH
    @body_sprite.w = PLAYER_SPRITE_W
    @body_sprite.h = PLAYER_SPRITE_H
    #Since body_sprite will need to be animated at some point I am leaving these here
    #@body_sprite.tile_x = 0
    #@body_sprite.tile_y = 0
    #@body_sprite.tile_w = PLAYER_SPRITE_W
    #@body_sprite.tile_h = PLAYER_SPRITE_H

    @face_sprite = Sprite.new
    @face_sprite.path = PLAYER_FACE_DOWN_SPRITE_PATH
    @face_sprite.w = PLAYER_SPRITE_W
    @face_sprite.h = PLAYER_SPRITE_H

    @pos = pos
    @vel = XYPair.new(0, 0)
    @fire_cooldown = 0
  end

  #Sprite functions. can all these be put together somehow?
  def head_sprite
    @head_sprite.x = offset.x
    @head_sprite.y = offset.y
    @head_sprite
  end

  def body_sprite
    @body_sprite.x = offset.x
    @body_sprite.y = offset.y
    @body_sprite
  end

  def face_sprite
    @face_sprite.x = offset.x
    @face_sprite.y = offset.y
    @face_sprite
  end

  def offset
    @pos - XYPair.new(@head_sprite.w, @head_sprite.h) * 0.5
  end

  def shoot(direction)
    #look in that direction
    @head_sprite.path = PLAYER_HEAD_RIGHT_SPRITE_PATH if direction == :right
    @head_sprite.path = PLAYER_HEAD_LEFT_SPRITE_PATH if direction == :left
    @head_sprite.path = PLAYER_HEAD_UP_SPRITE_PATH if direction == :up
    @head_sprite.path = PLAYER_HEAD_DOWN_SPRITE_PATH if direction == :down

    #items will modify these beyond direction. will need their own function
    @face_sprite.path = PLAYER_FACE_RIGHT_SPRITE_PATH if direction == :right
    @face_sprite.path = PLAYER_FACE_LEFT_SPRITE_PATH if direction == :left
    @face_sprite.path = PLAYER_FACE_UP_SPRITE_PATH if direction == :up
    @face_sprite.path = PLAYER_FACE_DOWN_SPRITE_PATH if direction == :down

    #fire the bullet
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


    #turn the body the way we wish to move
    @body_sprite.path = PLAYER_BODY_Y_SPRITE_PATH if direction.y == :up
    @body_sprite.path = PLAYER_BODY_Y_SPRITE_PATH if direction.y == :down
    @body_sprite.path = PLAYER_BODY_RIGHT_SPRITE_PATH if direction.x == :right
    @body_sprite.path = PLAYER_BODY_LEFT_SPRITE_PATH if direction.x == :left

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
    # * FIXME
    # Short had for ~@bullets.each { |b| b.tick }~ is ~@bulets.each(&:tick)~
    # Consider ~Array#reject~ instead of ~Array#find_all~ since you are removing/rejecting bullets that are not on the screen
    @bullets = @bullets.each { |b| b.tick }
                       .find_all do |b|
                         # consider args.grid.intersect_rect? b.rect
                         # take a look at http://fiddle.dragonruby.org/index.html?tutorial=tutorial-traveling-at-light-speed.html
                         b.pos.x.between?(0 - DSPWN_RNG, 1280 + DSPWN_RNG) &&
                         b.pos.y.between?(0 - DSPWN_RNG, 720 + DSPWN_RNG)
                       end # Check if bullet is on-screen
  end
end

$game = Game.new

def tick(args)
  $game.tick args
  args.outputs.background_color = [128, 128, 128]
  # note don't use static sprites unless you're seeing a performance issue
  args.outputs.sprites << $game.player.body_sprite #Todo: static sprites?
  args.outputs.sprites << $game.player.head_sprite #Todo: static sprites?
  args.outputs.sprites << $game.player.face_sprite #Todo: static sprites?
  args.outputs.sprites << $game.bullets.map { |b| b.sprite } # Todo: static sprites?
  args.outputs.labels << [10, 30, "FPS: #{args.gtk.current_framerate.to_s.to_i}", 255, 0, 0, 255]
end
