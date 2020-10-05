module Bullet
  # @param [Hash] pos
  # @param [Hash] vel
  # @param [Hash] attrs
  def self::spawn(pos, vel, attrs, sprite_opts)
    {
        pos:    pos,
        vel:    vel,
        age:    0,
        attrs:  attrs,
        sprite: BulletSprite.new(sprite_opts)
    }
  end

  # @param [Hash] bullet
  def self::tick_diff(bullet)
    out = {
        age: bullet[:age] + 1,
        sprite: bullet[:sprite].update(bullet)
    }
    out.deep_merge! Bullet::next_pos(bullet)
    out.deep_merge! Bullet::next_vel(bullet)
    out.deep_merge! Bullet::next_attrs(bullet)
    out
  end

  # @param [Hash] bullet
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def self::renderables(bullet)
    sprite = bullet[:sprite]
    out    = [sprite]
    out.unshift({
        x:                bullet[:attrs][:bbox][0],
        y:                bullet[:attrs][:bbox][1],
        w:                bullet[:attrs][:bbox][2],
        h:                bullet[:attrs][:bbox][3],
        r:                0,
        g:                255,
        b:                0,
        a:                255,
        primitive_marker: :border
    }) if $DEBUG
    out.push(sprite)
    out
  end

  # @param [Hash] bullet
  # @param [Hash] game
  def Bullet::despawn?(bullet, game)
    out = (bullet[:age] > bullet[:attrs][:stats][:range]) || # Range despawn
        !bullet[:pos][:x].between?(-50, 1330) || !bullet[:pos][:y].between?(-50, 770) || # Offscreen despawn
        (game[:boss][:alive] && bullet[:attrs][:bbox].intersect_rect?(game[:boss][:bbox]))
    out
    #TODO: collision
  end

  # @param [Hash] bullet
  def Bullet::next_pos(bullet)
    pos = XYVector.add(bullet[:pos], bullet[:vel])
    {
        pos:   pos,
        attrs: {
            bbox: [pos[:x], pos[:y], bullet[:attrs][:bbox][2], bullet[:attrs][:bbox][3]].anchor_rect(0.5, 0.5)
        }
    }
  end

  # @param [Hash] bullet
  def Bullet::next_vel(bullet)
    return {} if true # vel is currently const
    {
        vel: bullet[:vel]
    }
  end

  # @param [Hash] bullet
  def Bullet::next_attrs(bullet)
    return {} if true # attrs are currently const
    {
        attrs: {
            stats:  bullet[:attrs][:stats],
        }
    }
  end
end

# A necessary evil - Class sprites are much faster than hash sprites, and there can be a *lot* of bullets on screen.
class BulletSprite
  attr_sprite

  # @param [Hash] opts
  def initialize(opts)
    @x = -50
    @y = -50
    @w              = opts[:w]
    @h              = opts[:h]
    @off_x = @w/2
    @off_y = @h/2
    @path           = opts[:path]
    @angle_anchor_x = 0.5
    @angle_anchor_y = 0.5
    @angle_snap     = 10.0
  end

  # @param [Hash] bullet
  def update(bullet)
    @x     = bullet[:pos][:x] - @off_x
    @y     = bullet[:pos][:y] - @off_y
    @angle ||= (XYVector::theta(bullet[:vel]) * 180.0 / (@angle_snap * Math::PI)).round * @angle_snap # Expensive to calculate. Vel is currently constant, so only do this once.
    self
  end

  def serialize
    {
        x: x,
        y: y,
        off_x: @off_x,
        off_y: @off_y,
        w: w,
        h: h,
        path: path,
        angle: angle,
        angle_anchor_x: angle_anchor_x,
        angle_anchor_y: angle_anchor_y,
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end