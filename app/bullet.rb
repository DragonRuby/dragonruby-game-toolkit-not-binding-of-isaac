module Bullet
  # @param [Hash] pos
  # @param [Hash] vel
  # @param [Hash] attrs
  def self::spawn(pos, vel, attrs)
    {
        pos:   pos,
        vel:   vel,
        attrs: attrs
    }
  end

  # @param [Hash] bullet
  def self::next_state(bullet)
    pos   = Bullet::next_pos(bullet)
    vel   = Bullet::next_vel(bullet)
    attrs = Bullet::next_attrs(bullet, pos)
    {
        pos:   pos,
        vel:   vel,
        attrs: attrs
    }
  end

  # @param [Hash] bullet
  # @return [Array] An array of render primitives, in render order. (Background first, foreground last)
  def self::renderables(bullet)
    debug_outline = [{
                         x:                bullet[:attrs][:bbox][0],
                         y:                bullet[:attrs][:bbox][1],
                         w:                bullet[:attrs][:bbox][2],
                         h:                bullet[:attrs][:bbox][3],
                         r:                0,
                         g:                255,
                         b:                0,
                         a:                255,
                         primitive_marker: :border
                     }.anchor_rect(0, 0)]
    debug_outline.append [
                             {
                                 x:              bullet[:pos][:x],
                                 y:              bullet[:pos][:y],
                                 w:              bullet[:attrs][:sprite][:w],
                                 h:              bullet[:attrs][:sprite][:h],
                                 path:           bullet[:attrs][:sprite][:path],
                                 angle_anchor_x: 0.5,
                                 angle_anchor_y: 0.5,
                                 angle:          (XYVector::theta(bullet[:vel]) * 180.0 / (bullet[:attrs][:sprite][:angle_snap] * Math::PI)).round * bullet[:attrs][:sprite][:angle_snap],
                             }.anchor_rect(-0.5, -0.5)
                         ]
  end

  # @param [Hash] bullet
  # @param [Hash] game
  def Bullet::despawn?(bullet, game)
    false #TODO: Out of bounds, collision, age
  end

  # @param [Hash] bullet
  def Bullet::next_pos(bullet)
    XYVector.add(bullet[:pos], bullet[:vel])
  end

  # @param [Hash] bullet
  def Bullet::next_vel(bullet)
    bullet[:vel]
  end

  # @param [Hash] bullet
  # @param [Hash] new_pos
  def Bullet::next_attrs(bullet, new_pos)
    {
        sprite: bullet[:attrs][:sprite],
        bbox:   [new_pos[:x], new_pos[:y], bullet[:attrs][:bbox][2], bullet[:attrs][:bbox][3]]
    }
  end
end