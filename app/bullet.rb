module Bullet
  # @param [Hash] pos
  # @param [Hash] vel
  # @param [Hash] attrs
  # @return [Hash{Symbol->Hash}] A hash representing a bullet.
  def self::spawn(pos, vel, attrs)
    {
        pos:   pos,
        vel:   vel,
        attrs: attrs
    }
  end

  # @param [Hash] bullet
  # @return [Hash{Symbol->Hash}] The next state of the bullet.
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
    # When in $DEBUG mode (enabled by typing `$DEBUG = true` in the console), show a green box corresponding to the bullet's bounding box.
    debug_outline = $DEBUG ? [{
                                  x:                bullet[:attrs][:bbox][0],
                                  y:                bullet[:attrs][:bbox][1],
                                  w:                bullet[:attrs][:bbox][2],
                                  h:                bullet[:attrs][:bbox][3],
                                  r:                0,
                                  g:                255,
                                  b:                0,
                                  a:                255,
                                  primitive_marker: :border
                              }.anchor_rect(0, 0)] : []
    # Return an array containing a debug bounding box (if applicable), and the bullet's sprite.
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
  # @return [TrueClass, FalseClass] True when the bullet should not exist next tick.
  def Bullet::despawn?(bullet, game)
    return !(bullet[:attrs][:bbox].inside_rect?([-50, -50, 1380, 820]))
    # Right now, this only checks if the bullet is on screen.
    # However, you can easily change the boolean expression to test collisions, the age of the bullet, etc.
  end

  # @param [Hash] bullet
  # @return [Hash{Symbol->Float}] The next state's position vector.
  def Bullet::next_pos(bullet)
    XYVector.add(bullet[:pos], bullet[:vel])
  end

  # @param [Hash] bullet
  # @return [Hash{Symbol->Float}] The next state's velocity vector.
  def Bullet::next_vel(bullet)
    bullet[:vel]
    # If bullets slowed down over time, were attracted to enemies, or otherwise changed direction after firing,
    # you would update the bullet's velocity here.
  end

  # @param [Hash] bullet
  # @param [Hash] new_pos
  # @return [Hash] The bullet's attributes for the next tick
  def Bullet::next_attrs(bullet, new_pos)
    {
        # Keep the old bullet sprite
        sprite: bullet[:attrs][:sprite],
        # But update the bounding box to reflect the new bullet position.
        bbox:   [new_pos[:x], new_pos[:y], bullet[:attrs][:bbox][2], bullet[:attrs][:bbox][3]].anchor_rect(0.5, 0.5)
    }
  end
end