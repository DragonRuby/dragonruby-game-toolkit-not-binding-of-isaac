require 'stateful_app/constants.rb'
require 'stateful_lib/prng.rb'
require 'stateful_lib/xy_vector.rb'
require 'stateful_app/dungeon.rb'
require 'stateful_app/room.rb'
require 'stateful_lib/profiler.rb'
require 'stateful_lib/tests.rb'

# puts 'RUNNING TESTS'
# (1..10).each { |n| Tests.test_dungeon_generation n }

class Sprite
  attr_sprite
  # @param [Integer] w width2
  # @param [Integer] h height
  def initialize(w, h)
    @w = w
    @h = h
  end

  # @param [String] new_path
  def path=(new_path)
    @path = new_path if @path != new_path
  end
end

class Bullet
  attr_accessor :sprite, :pos, :vel

  # @param [XYVector] pos
  # @param [XYVector] vel
  def initialize(pos, vel)
    trace! if TRACING_ENABLED
    @sprite      = Sprite.new BULLET_SPRITE_SIZE, BULLET_SPRITE_SIZE
    @sprite.path = BULLET_SPRITE_PATH
    @pos         = pos
    @vel         = vel
    # Point the Bullet in the direction of motion, snapped to the nearest BULLET_VISUAL_ANGLE_SNAP degrees
    @sprite.angle          = (vel.theta * 180 / (BULLET_VISUAL_ANGLE_SNAP * Math::PI)).round * BULLET_VISUAL_ANGLE_SNAP
    @sprite.angle_anchor_x = 0.5
    @sprite.angle_anchor_y = 0.5
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

    #noinspection
    @pos - XYVector.new(@sprite.w, @sprite.h) * 0.5
  end
end

class Player
  attr_accessor :sprites, :fire_cooldown
  #@type [XYVector]
  attr_accessor :pos
  #@type [XYVector]
  attr_accessor :vel


  # @param [XYVector] pos
  def initialize(pos)
    #@type [XYVector]
    @pos           = pos
    @vel           = XYVector.new
    @fire_cooldown = 0
    @bullet_count  = 0

    trace! if TRACING_ENABLED
    #player uses three layers of sprites: head_sprite, body_sprite, face_sprite
    @sprites = {
        body: Sprite.new(PLAYER_SPRITE_W, PLAYER_SPRITE_H),
        head: Sprite.new(PLAYER_SPRITE_W, PLAYER_SPRITE_H),
        face: Sprite.new(PLAYER_SPRITE_W, PLAYER_SPRITE_H)
    }
    turn(:body, :down)
    turn(:head, :down)
    turn(:face, :down)

    #Since body_sprite will need to be animated at some point I am leaving these here
    #@sprites[:body].tile_x = 0
    #@sprites[:body].tile_y = 0
    #@sprites[:body].tile_w = PLAYER_SPRITE_W
    #@sprites[:body].tile_h = PLAYER_SPRITE_H
    #
  end

  # @param [Symbol] part The body part to turn
  # @param [Symbol] direction The direction to turn the body part towards
  def turn(part, direction)
    unless PLAYER_SPRITES.has_key?(part) && PLAYER_SPRITES[part].has_key?(direction)
      puts part.to_s
      puts direction.to_s
    end
    @sprites[part].path = PLAYER_SPRITES[part][direction]
    nil # Don't return anything
  end

  # @param [Symbol] part Body part to get the sprite for
  def offset_sprite(part)
    @sprites[part].x = offset.x
    @sprites[part].y = offset.y
    @sprites[part]
  end

  def offset_sprites
    @sprites.keys.map { |s| offset_sprite s }
  end


  def offset
    @pos - XYVector.new(PLAYER_SPRITE_W.to_f, PLAYER_SPRITE_H.to_f) * 0.5
  end

  # @param [Symbol] direction
  def shoot(direction)

    turn(:head, direction) if direction != :none
    #items will modify these beyond direction. will need their own function
    turn(:face, direction) if direction != :none

    #reset the bullet count, always start from the same eye
    @bullet_count = 0 if direction == :none


    #fire the bullet
    return nil if (@fire_cooldown -= 1) > 0 || direction == :none
    @fire_cooldown     = BULLET_COOLDOWN
    bullet_initial_vel = nil
    bullet_initial_vel = XYVector.new(BULLET_SPEED, 0.0) if direction == :right
    bullet_initial_vel = XYVector.new(-BULLET_SPEED, 0.0) if direction == :left
    bullet_initial_vel = XYVector.new(0.0, BULLET_SPEED) if direction == :up
    bullet_initial_vel = XYVector.new(0.0, -BULLET_SPEED) if direction == :down
    if bullet_initial_vel
      a                 = @vel
      b                 = bullet_initial_vel
      cos_theta         = ((a * b) / (a.len * b.len))
      parallel_vel      = b * ((a * b) / (b * b))
      perpendicular_vel = a - parallel_vel
      momentum_vector   = (perpendicular_vel + (cos_theta > 0 ? parallel_vel : XYVector.new)) * BULLET_MOMENTUM
      bullet_true_vel   = momentum_vector + bullet_initial_vel

      #calculates where the bullet should appear
      eye_position = case direction
                     when :down
                       @bullet_count % 2 == 0 ? XYVector.new(12.0, -4.0) : XYVector.new(-12.0, -4.0)
                     when :left
                       @bullet_count % 2 == 0 ? XYVector.new(-16.0, -8.0) : XYVector.new(-16.0, 8.0)
                     when :right
                       @bullet_count % 2 == 0 ? XYVector.new(16.0, 8.0) : XYVector.new(16.0, -8.0)
                     when :up
                       @bullet_count % 2 == 0 ? XYVector.new(12.0, 16.0) : XYVector.new(-12.0, 16.0)
                     else
                       @bullet_count % 2 == 0 ? XYVector.new(0.0, 0.0) : XYVector.new(0.0, 0.0)
                     end

      #saves the bullet count to know which eye to appear on
      @bullet_count += 1

      # I don't know why, I don't want to know why, I shouldn't have to wonder why, but for whatever reason,
      # RubyMine thinks both of these are Floats on this line and this line only unless we do this terribleness.
      Bullet.new(eye_position + @pos, XYVector.new + bullet_true_vel)
    end
  end

  # @param [Array<Symbol>] directions
  def move(directions)
    @vel.x        = (@vel.x + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if directions.include? :right
    @vel.x        = (@vel.x - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if directions.include? :left
    @vel.y        = (@vel.y + PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if directions.include? :up
    @vel.y        = (@vel.y - PLAYER_ACCEL).clamp(-PLAYER_SPEED_LIMIT, PLAYER_SPEED_LIMIT) if directions.include? :down
    diagonal_comp = PLAYER_SPEED_LIMIT / @vel.len
    @vel          *= diagonal_comp if diagonal_comp < 1.0
    @vel.x        *= PLAYER_FRICTION unless directions.include?(:right) || directions.include?(:left)
    @vel.y        *= PLAYER_FRICTION unless directions.include?(:up) || directions.include?(:down)
    @pos          += @vel

    facing = if directions.include?(:up) || directions.include?(:down)
               directions.include?(:up) ? :up : :down
             elsif directions.include?(:right) || directions.include?(:left)
               directions.include?(:right) ? :right : :left
             else
               :none
             end
    turn(:body, facing) if facing != :none
    turn(:head, facing) if facing != :none
    turn(:face, facing) if facing != :none
  end
end

class Game
  attr_accessor :player, :bullets, :dungeon

  # @param [String] seed
  def initialize(seed='106dqjno')
    trace! if TRACING_ENABLED

    @player = Player.new XYVector.new(640.0, 360.0)

    @bullets = []

    @dungeon_master = DungeonMaster.new(seed)
    @dungeon        = @dungeon_master.generate(
        {
            normal:       40,
            boss:         2,
            super_secret: 1,
            shop:         2,
            item:         2,
            secret:       5
        }
    )
    puts @dungeon.pretty_str
  end


  # @param [KeySet] keyboard
  # @return [Array<Symbol>]
  def get_move_dir(keyboard)
    #Necessary for mac as args.inputs.keyboard.key_held.<key> equals nil initially
    keyboard.w ||= false; keyboard.a ||= false
    keyboard.s ||= false; keyboard.d ||= false

    dirs = []
    dirs.push(keyboard.a == keyboard.d ? :none : keyboard.a ? :left : :right)
    dirs.push(keyboard.w == keyboard.s ? :none : keyboard.w ? :up : :down)
    dirs
  end

  # @param [GTK::KeyboardKeys] keyboard
  def get_shoot_dir(keyboard)
    #Necessary for mac as args.inputs.keyboard.key_held.<key> equals nil initially
    keyboard.up   ||= false; keyboard.down ||= false
    keyboard.left ||= false; keyboard.right ||= false

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

  def update_room
    buffer = 16.0
    if player.pos.x < buffer
      if dungeon.curr_room&.neighbors[:W]
        player.pos.x = 1280.0 - (buffer*1.5)
        dungeon.set_room dungeon.curr_room&.neighbors[:W]
        @bullets = []
      else
        player.pos.x = buffer
        player.vel.x = 0.0
      end
    elsif player.pos.x > (1280.0 - buffer)
      if dungeon.curr_room&.neighbors[:E]
        player.pos.x = buffer*1.5
        dungeon.set_room dungeon.curr_room&.neighbors[:E]
        @bullets = []
      else
        player.pos.x = 1280.0 - buffer
        player.vel.x = 0.0
      end
    elsif player.pos.y < buffer
      if dungeon.curr_room&.neighbors[:S]
        player.pos.y = 720.0 - (buffer*1.5)
        dungeon.set_room dungeon.curr_room&.neighbors[:S]
        @bullets = []
      else
        player.pos.y = buffer
        player.vel.y = 0.0
      end
    elsif player.pos.y > (720.0 - buffer)
      if dungeon.curr_room&.neighbors[:N]
        player.pos.y = buffer*1.5
        dungeon.set_room dungeon.curr_room&.neighbors[:N]
        @bullets = []
      else
        player.pos.y = (720.0 - buffer)
        player.vel.y = 0.0
      end
    end
  end

  # @param [Args] args
  def tick(args)
    player.move(get_move_dir(args.inputs.keyboard.key_held))
    bullet = player.shoot get_shoot_dir args.inputs.keyboard.key_held
    @bullets << bullet if bullet
    update_room
    # Todo: Find a more efficient method.
    @bullets = @bullets.each { |b| b.tick }
                       .find_all { |b| b.pos.x.between?(0 - BULLET_DESPAWN_RANGE, 1280 + BULLET_DESPAWN_RANGE) && b.pos.y.between?(0 - BULLET_DESPAWN_RANGE, 720 + BULLET_DESPAWN_RANGE) } # Check if bullet is on-screen
  end
end

$game         = Game.new
$sprite_const = PLAYER_SPRITES

# @param [Args] args
def tick(args)
  $game.tick args
  args.outputs.sprites << $game.dungeon.sprite
  args.outputs.sprites << $game.player.offset_sprites
  args.outputs.sprites << $game.bullets.map { |b| b.sprite } # Todo: static sprites?
  #noinspection RubyResolve
  args.outputs.labels << [10,  30, "FPS      : #{args.gtk.current_framerate.to_s.to_i}", 0, 0, 255, 0, 0, 255, 'fonts/jetbrainsmono.ttf']
  args.outputs.labels << [10,  60, "ROOM_TYPE: :#{$game.dungeon.curr_room&.type.to_s}", 0, 0,  255, 0, 0, 255, 'fonts/jetbrainsmono.ttf']
  args.outputs.labels << [10,  90, "ROOM_POS : #{$game.dungeon.curr_room&._coord_str}", 0, 0,  255, 0, 0, 255, 'fonts/jetbrainsmono.ttf']
  args.outputs.labels << [10, 120, "MAP_SEED : #{$game.dungeon.seed}", 0, 0, 255, 0, 0, 255, 'fonts/jetbrainsmono.ttf']
  map_y = 760
  args.outputs.labels << $game.dungeon.whole_map_str.split("\n").map do |str|
    map_y -= 20
    [5, map_y, "#{str}", 0, 0, 255, 0, 0, 255, 'fonts/jetbrainsmono.ttf']
  end
  map_y = 760
  args.outputs.labels << $game.dungeon.room_map_str.split("\n").map do |str|
    map_y -= 20
    [5, map_y, "#{str}", 0, 0, 0, 0, 255, 255, 'fonts/jetbrainsmono.ttf']
  end
end

def reseed(seed="")
  if seed.length != 8
    puts "Enter an 8 character long string of alphanumeric characters."
  else
    $game = Game.new(seed)
  end
end