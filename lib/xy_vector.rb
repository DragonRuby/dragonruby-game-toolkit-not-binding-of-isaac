module XYVector

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Hash{Symbol=>Float}] rhs
  # @return [Hash{Symbol=>Float}]
  def self.add(lhs, rhs)
    {x:lhs[:x]+rhs[:x], y:lhs[:y]+rhs[:y]}
  end

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Hash{Symbol=>Float}] rhs
  # @return [Hash{Symbol=>Float}]
  def self.sub(lhs, rhs)
    {x:lhs[:x]-rhs[:x], y:lhs[:y]-rhs[:y]}
  end

  # @param [Hash{Symbol=>Float}, Float] lhs
  # @param [Hash{Symbol=>Float}, Float] rhs
  # @return [Hash{Symbol=>Float}, Float] Returns scaled vector if lhs is a scalar, and dot product if lhs is a vector.
  def self.mul(lhs, rhs)
    if lhs.is_a? Float
      return {x:lhs*rhs[:x], y:lhs*rhs[:y]}
    elsif rhs.is_a? Float
      return {x:lhs[:x]*rhs, y:lhs[:y]*rhs}
    end # Scalar multiply
    lhs[:x]*rhs[:x] + lhs[:y]*rhs[:y] # Dot product
  end

  # @param [Hash{Symbol=>Float}, Float] lhs
  # @param [Float] rhs
  # @return [Hash{Symbol=>Float}]
  def self.div(lhs, rhs)
    {x:lhs[:x].fdiv(rhs), y:lhs[:y].fdiv(rhs)}
  end

  # @param [Hash{Symbol=>Float}] v
  # @return [Float]
  def self.abs(v)
    Math.sqrt(self.mul(v,v))
  end

  # @param [Hash{Symbol=>Float}] v
  # @return [Float]
  def theta(v)
    Math.atan2(v[:y], v[:x])
  end
end
