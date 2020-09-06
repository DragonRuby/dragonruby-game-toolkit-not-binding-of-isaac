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

  def _coord_str
    "[#{@x},#{@y}]"
  end

  # @param [Room] room
  def dist_to(room)
    # puts "#{self._coord_str} => #{room._coord_str}"
    q = [self]
    v = [self]
    e = {}
    while q.any?
      n = q.shift
      break if n == room
      #noinspection RubyNilAnalysis
      n.neighbors.values.each do |m|
        next if v.include? m
        q << m
        v << m
        e[m._coord_str] = n
      end
    end
    raise RuntimeError "Disconnected dungeon!?" unless v.include? room
    d = 0
    n = room
    while n != self
      n = e[n._coord_str]
      d += 1
    end
    # puts "#{self._coord_str} => #{room._coord_str} = #{d}"
    d
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

  def ordered_neighbor_dirs
    neighbors.keys.sort_by{ |k| k.to_s}
  end

  def directional_char
    one_neigh = {
        E: '╞',
        N: '╨',
        S: '╥',
        W: '╡',
    }
    two_neigh = {
        E: {
            N: '╚',
            S: '╔',
            W: '═',
        },
        N: {
            S: '║',
            W: '╝',
        },
        S: {
            W: '╗'
        }
    }
    three_neigh = {
        E: '╣',
        N: '╦',
        S: '╩',
        W: '╠',
    }
    case neighbors.length
    when 0
      'O'
    when 1
      one_neigh[neighbors.keys[0]]
    when 2
      dirs = neighbors.keys.sort_by{ |k| k.to_s}
      two_neigh[dirs[0]][dirs[1]]
    when 3
      three_neigh[(%i[E N S W]-neighbors.keys)[0]]
    when 4
      '╬'
    else
      '?'
    end
  end

  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

end