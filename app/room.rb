# @type [Hash<Symbol, Symbol>]
REVERSE      = {
    N: :S,
    S: :N,
    E: :W,
    W: :E
}
OFFSET_TO_DIR = {
    1 => {
        0 => :E
    },
    0 => {
        1  => :N,
        -1 => :S
    },
    -1 => {
        1 => :W
    }
}

class Room
  # The type of room
  # @type [Symbol]
  attr_accessor :type

  # The room's x coordinate
  # @type [Integer]
  attr_accessor :x

  # The room's y coordinate
  # @type [Integer]
  attr_accessor :y

  # The specific variant of the room type
  # @type [Integer]
  attr_accessor :variant_id

  # The room's neighbors
  # @type [Hash<Symbol, Room>]
  attr_accessor :neighbors

  # The direction of the room's parent.
  # Is nil if this room is the seed room
  # neighbors[parent_direction] === the room that spawned this room
  # @type [Symbol]
  attr_accessor :parent_direction

  # @param [Symbol] type
  # @param [Room] parent
  # @param [Integer] x
  # @param [Integer] y
  def initialize(type, parent, x, y)
    @type   = type
    @parent = parent
    @x      = x
    @y      = y
  end

  # @param [Room] room
  def add_neighbor(room)

  end

  def dead_end?
    @neighbors.length < 2
  end

  def serialize
    {
        type: type,
        x:    x,
        y:    y,
        # variant_id:       variant_id,
        # neighbors:        neighbors,
        # parent_direction: parent_direction
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

end