class XYVector
  attr_accessor :x
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

  def theta
    Math.atan2(@y, @x)
  end

  # @param [Float] theta_prime
  def theta=(theta_prime)
    @x, @y = *(XYVector.new(*theta_prime.vector) * self.len).serialize.values
  end

  def serialize
    {x: x, y: y};
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s;
  end
end