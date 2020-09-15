module ParametricBullet
  FUNCTIONS = {
      radial_spin_out: lambda do |age, duration, offset_x, offset_y, params|
        time = age.fdiv(duration)
        theta = time * params[:turns] * Math::PI * 2.0 + (params[:n] * Math::PI * 2.0/ params[:max_n])
        radius = time * params[:dist]
        [
            offset_x + (Math::sin(params[:offset_theta] + theta) * radius),
            offset_y + (Math::cos(params[:offset_theta] + theta) * radius),
        ]
      end,
  }
  # @param [Symbol] function The function to use
  # @param [Hash] pos {x: initial x position, y: initial y position}
  # @param [Integer] initial_age
  # @param [Integer] range
  # @param [Hash] func_params
  def ParametricBullet::spawn(function, pos, initial_age, range, func_params, radius, sprite_opts)
    {
        function: function,
        offset_x: pos[:x],
        offset_y: pos[:y],
        age: initial_age,
        range: range,
        func_params: func_params,
        sprite: ParametricBulletSprite.new(sprite_opts, radius)
    }
  end

  # @param [Hash] pbullet
  def ParametricBullet::tick_diff(pbullet)
    {
        age: pbullet[:age] + 1
    }
  end

  # @param [Hash] pbullet
  def ParametricBullet::pos(pbullet)
    ParametricBullet::FUNCTIONS[pbullet[:function]].call(pbullet[:age], pbullet[:range], pbullet[:offset_x], pbullet[:offset_y], pbullet[:func_params])
  end

  # @param [Hash] pbullet
  def ParametricBullet::renderables(pbullet)
    return [] unless ParametricBullet::renderable?(pbullet)
    pbullet[:sprite].update(pbullet)
  end
  # @param [Hash] pbullet
  def ParametricBullet::renderable?(pbullet)
    x, y = ParametricBullet::pos(pbullet)
    x.between?(-50, 1330) && y.between?(-50, 770) # Offscreen despawn
  end

  # @param [Hash] pbullet
  # @param [Hash] game
  def ParametricBullet::despawn?(pbullet, game)
    (pbullet[:age] > pbullet[:range]) # Range despawn

  end
end

# A necessary evil - Class sprites are much faster than hash sprites, and there can be a *lot* of bullets on screen.
class ParametricBulletSprite
  attr_sprite

  # @param [Hash] opts
  def initialize(opts, radius)
    @x = -50
    @y = -50
    @w              = radius * 2
    @h              = radius * 2
    @off_x = radius
    @off_y = radius
    @path           = opts[:path]
    @r = opts[:r] || 255
    @g = opts[:g] || 255
    @b = opts[:b] || 255
  end

  # @param [Hash] pbullet
  def update(pbullet)
    @x, @y     = ParametricBullet::pos(pbullet)
    @x -= @off_x
    @y -= @off_y
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
        r: r,
        g: g,
        b: b
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end
end