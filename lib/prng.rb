# A PRNG based on XORShift.
# Reason for existing: Need a serializable, deterministic, well-defined source of RNG.
class PRNG
  M = ((1 << 32) - 1)
  A = 13 & M
  B = 17 & M
  C = 5 & M
  F = (1.0).fdiv(M)

  # @param [Integer] seed The seed of the PRNG, between 1 and 2^32 - 1
  def initialize(seed)
    raise(ArgumentError, "Invalid seed value") unless seed.between?(1, M)
    @s = seed & M
  end

  # Advances the current state of the PRNG instance
  def next!
    @s ^= @s << A & M
    @s ^= @s >> B & M
    @s ^= @s << C & M
  end

  # @param [Range<Integer>] range, inclusive.
  def int(range)
    next! % (range.last.next - range.first) + range.first
  end

  # @param [Range<Integer>] range, theoretically inclusive.
  def float(range)
    next! * ((range.last.next - range.first) / M) + range.first
    #[next!].pack('L').unpack('f')[0] % (range.last - range.first) + range.first
  end

  # @return [TrueClass, FalseClass]
  def bool?
    next! & 0b1 == 1
  end

  # Shuffles an array in-place
  # @param [Array] array
  def shuffle!(array)
    (0..array.length-2).each do |i|
      j = int(i..array.length-1)
      array[i], array[j] = array[j], array[i]
    end
  end

  # @param [Array] array
  def sample(array)
    array[int(0..array.length-1)]
  end


  # @return [Hash{Symbol->Integer}]
  def serialize
    {s: @s};
  end

  # @return [String]
  def inspect
    serialize.to_s
  end

  # @return [String]
  def to_s
    serialize.to_s;
  end
end