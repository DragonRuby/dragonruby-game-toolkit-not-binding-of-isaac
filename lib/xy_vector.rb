module XYVector

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Hash{Symbol=>Float}] rhs
  # @return [Hash{Symbol=>Float}]
  def XYVector::add(lhs, rhs)
    {x: lhs[:x] + rhs[:x], y: lhs[:y] + rhs[:y]}
  end

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Hash{Symbol=>Float}] rhs
  # @return [Hash{Symbol=>Float}]
  def XYVector::sub(lhs, rhs)
    {x: lhs[:x] - rhs[:x], y: lhs[:y] - rhs[:y]}
  end

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Float] rhs
  # @return [Hash{Symbol=>Float}]
  def XYVector::scale(lhs, rhs)
    {x: lhs[:x] * rhs, y: lhs[:y] * rhs}
  end

  # @param [Hash{Symbol=>Float}] lhs
  # @param [Hash{Symbol=>Float}] rhs
  def XYVector::dot(lhs, rhs)
    lhs[:x] * rhs[:x] + lhs[:y] * rhs[:y] # Dot product
  end

  # @param [Hash{Symbol=>Float}, Float] lhs
  # @param [Float] rhs
  # @return [Hash{Symbol=>Float}]
  def XYVector::div(lhs, rhs)
    {x: lhs[:x].fdiv(rhs), y: lhs[:y].fdiv(rhs)}
  end

  # @param [Hash{Symbol=>Float}] v
  # @return [Float]
  def XYVector::abs(v)
    Math.sqrt(XYVector::dot(v, v))
  end

  # @param [Hash{Symbol=>Float}] v
  # @return [Float]
  def XYVector::theta(v)
    Math.atan2(v[:y], v[:x])
  end
end
