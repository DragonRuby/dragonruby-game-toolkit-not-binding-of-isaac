# @type [Hash<Symbol, Symbol>]
REVERSE       = {
    N: :S,
    S: :N,
    E: :W,
    W: :E
}
OFFSET_TO_DIR = {
    1  => {
        0 => :E
    },
    0  => {
        1  => :N,
        -1 => :S
    },
    -1 => {
        0 => :W
    }
}

class Room
  # The type of room
  # @type [Symbol]
  attr_reader :type

  # The room's x coordinate
  # @type [Integer]
  attr_reader :x

  # The room's y coordinate
  # @type [Integer]
  attr_reader :y

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
  attr_reader :parent_direction

  # @param [Symbol] type
  # @param [Room] parent
  # @param [Integer] x
  # @param [Integer] y
  def initialize(type, parent, x, y)
    @type      = type
    @parent    = parent
    @x         = x
    @y         = y
    @depth     = parent == nil ? 0 : 1 + parent.depth
    @neighbors = {}
    if parent == nil
      @parent_direction = nil
    else
      @parent_direction = OFFSET_TO_DIR[parent.x - x][parent.y - y]
      add_neighbor(parent)
      parent.add_neighbor(self)
    end
  end

  # @param [Room] room
  def add_neighbor(room)
    puts "[#{room.x},#{room.y}],[#{x},#{y}] => [#{room.x - x},#{room.y - y}]" if OFFSET_TO_DIR[room.x - x][room.y - y] == nil
    neighbors[OFFSET_TO_DIR[room.x - x][room.y - y]] = room
  end

  def depth
    @depth
  end

  # @param [Room] room
  def dist_to(room)
    found = {}
    _dist_to(room, nil, found)
  end

  # @param [Room] room
  # @param [Room, nil] src
  # @param [Hash] found
  def _dist_to(room, src, found)
    if room == self
      found[:it] = true
      0
    elsif neighbors.length == 0 || found[:it]
      Integer(Float::INFINITY)
    else
      1 + neighbors.values.find_all { |n| n != src }.map { |n| n.dist_to(room, self) }.min
    end
  end

  def dead_end?
    @neighbors.values.count { |r| r.type != :secret } == 1
  end

  def serialize
    {
        type:      type,
        x:         x,
        y:         y,
        neighbors: Hash[neighbors.map { |k, v| [k, [v.x, v.y]] }]
    }
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

end