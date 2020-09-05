require 'app/room.rb'
require 'lib/prng.rb'

# Creates the dungeon. I *could* call it LevelLayoutFactory, but where's the fun in that?
class DungeonMaster

  attr_accessor :layout

  # @param [String] hex_seed
  def initialize(hex_seed)
    # raise(ArgumentError, "Seed must have 8 alphanumeric [A-Z0-9] characters") unless hex_seed.match(/[a-zA-Z0-9]{8}/)
    @hex_seed = hex_seed
    @prng     = PRNG.new(hex_seed.split('').map { |ch| (ch.to_i(36) % 16).to_s(16) }.join('').to_i(16))
    @layout = {}
    @rooms = []
    trace! self
  end

  # @return [String]
  def hex_seed
    @hex_seed
  end

  # @param [Integer] x
  # @param [Integer] y
  def coord_neighbors(x, y)
    [[x + 1, y + 0], [x + 0, y + 1], [x - 1, y + 0], [x + 0, y - 1]]
  end

  # @param [Integer] x
  # @param [Integer] y
  def surrounded?(x, y)
    valid_children(x, y).empty?
  end

  # @param [Integer] x
  # @param [Integer] y
  def valid_children(x, y)
    # A CHILD COORD MUST BE UNOCCUPIED, AND HAVE ONLY ONE OCCUPIED NEIGHBOR
    coord_neighbors(x, y).find_all do |x2y2|
      (get_room(*x2y2) == nil) && (coord_neighbors(*x2y2).count { |x3y3| get_room(*x3y3) } == 1)
    end
  end

  # @param [Integer] x
  # @param [Integer] y
  # @param [Symbol] type
  # @param [Room] parent
  # @return [Room] child
  def add_room(x, y, type, parent)
    @layout[y] = {} unless @layout.has_key? y
    raise(ArgumentError, "COORD ALREADY OCCUPIED") if @layout[y][x]
    room = Room.new(type, parent, x, y)
    @rooms.push room
    @layout[y][x] = room
  end

  # @param [Integer] x
  # @param [Integer] y
  def get_room(x, y)
    return nil unless @layout.has_key? y
    @layout[y][x]
  end

  # @param [Integer] num_rooms
  def generate(num_rooms)
    room_counter = 0
    a = []
    a.push(add_room(0, 0, '0'.to_sym, nil))
    while room_counter < num_rooms && !a.empty?
      idx = @prng.int(0..(a.length - 1))
      parent = a[idx]
      puts pretty_str
      # puts "BUILDING FROM #{parent.x} #{parent.y} (#{parent.type.to_s})"
      valid_arr = valid_children(parent.x, parent.y)
      if valid_arr.empty?
        # puts "DISCARDING #{parent.x} #{parent.y}"
        a.delete_at idx
      else
        x, y = *(@prng.sample valid_arr)
        # puts "ADDING #{x} #{y}"
        room_counter+=1
        a.push(add_room(x, y, room_counter.to_s(16).to_sym, parent))
      end
    end
  end

  def pretty_str
    #@type [Hash]
    widest = (@layout.max { |a,b|  (a[1].keys.max - a[1].keys.min) <=> (b[1].keys.max - b[1].keys.min)})[1] || {}
    xs = (@rooms.map { |r| r.x}.min..@rooms.map { |r| r.y}.max)
    ys = (@rooms.map { |r| r.y}.min..@rooms.map { |r| r.y}.max)
    str = '+'+xs.map { |_| '-'}.join('')+"+\n"
    ys.each do |y|
      str+='|'
      xs.each do |x|
        room = get_room(x,y)
        str += (room != nil) ? "╬" : " "
      end
      str += "|\n"
    end
    str + '+' + xs.map { |_| '-' }.join('') + '+'
  end
end

class Dungeon
  attr_accessor :layout

  # @param [Hash{Pair => Room}] rooms
  def initialize rooms

  end
end