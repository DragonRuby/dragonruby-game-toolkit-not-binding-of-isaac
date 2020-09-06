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
    @layout   = {}
    #@type [Array<Room>]
    @rooms = []
    # trace! self
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
  # @param [Integer] max_neighbors
  # @param [Integer] min_neighbors
  def valid_children(x, y, min_neighbors = 1, max_neighbors = 1)
    # A CHILD COORD MUST BE UNOCCUPIED, AND HAVE ONLY ONE OCCUPIED NEIGHBOR
    coord_neighbors(x, y).find_all do |x2y2|
      if get_room(*x2y2) == nil
        occupied_neighbors = coord_neighbors(*x2y2).count { |x3y3| get_room(*x3y3) }
        ((min_neighbors <= occupied_neighbors) && (occupied_neighbors <= max_neighbors))
      else
        false
      end
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

  # @param [Hash{Symbol=>Integer}] room_counts The number of standard rooms to generate
  def generate(room_counts)
    generate_normal_rooms(room_counts[:normal] || 10)
    puts pretty_str
    generate_boss_rooms(room_counts[:boss] || 1)
    puts pretty_str
    generate_super_secret_rooms(room_counts[:super_secret] || 1)
    puts pretty_str
    generate_shop_rooms(room_counts[:shop] || 1)
    puts pretty_str
    generate_item_rooms(room_counts[:item] || 1)
    puts pretty_str
    trace! self
    generate_secret_rooms(room_counts[:secret] || 1)
    puts pretty_str
  end

  # @param [Integer] count
  def generate_normal_rooms(count)
    room_counter = 0
    a            = []
    a.push(add_room(0, 0, :spawn, nil))
    while (room_counter < count) && !(a.empty?)
      idx       = @prng.int(0..(a.length - 1))
      parent    = a[idx]
      valid_arr = valid_children(parent.x, parent.y)
      if valid_arr.empty?
        a.delete_at idx
      else
        x, y         = *(@prng.sample valid_arr)
        room_counter += 1
        a.push(add_room(x, y, :normal, parent))
      end
    end
  end

  # @return [Room] The furthest normal room with a dead end
  def get_longest_dead_end
    tmp = 0
    # RubyMine thinks this may return nil, but it won't.
    #noinspection RubyYardReturnMatch
    out = @rooms.find_all { |r|
      (r.type == :normal) &&
          r.dead_end? &&
          !(valid_children(r.x, r.y).empty?)
    }.sort_by { |r| [r.depth, tmp += 1] }.last
    if out == nil
      puts '~~~~~~~~~'
      puts @rooms.find_all { |r| (r.type == :normal) }
      puts @rooms.find_all { |r| (r.type == :normal) && r.dead_end? }
      raise RuntimeError, "The universe just LOVES proving me wrong, doesn't it? (Found no valid dead ends)"
    end
    out
  end

  # Generates a chain of boss rooms (Beat boss 1 to access boss 2, boss 2 to access boss 3, etc.)
  # @param [Integer] count The maximum number of boss rooms to generate. If greater than zero, at least one will always generate.
  def generate_boss_rooms(count)
    return if count <= 0
    penultimate = get_longest_dead_end
    boss_xy     = @prng.sample valid_children(penultimate.x, penultimate.y)
    boss        = add_room(boss_xy[0], boss_xy[1], :boss, penultimate)
    boss_count  = 1
    while boss_count < count
      penultimate = boss
      boss_xy     = @prng.sample valid_children(penultimate.x, penultimate.y)
      break if boss_xy == nil
      boss       = add_room(boss_xy[0], boss_xy[1], :boss, penultimate)
      boss_count += 1
    end
    boss_count
  end

  # @param [Integer] count The number of rooms to generate
  # @param [Symbol] type The type of room to generate
  # @return [Integer] The number of rooms actually generated
  def generate_generic_deadend_room(count, type)
    curr_count = 0
    while curr_count < count
      parent = get_longest_dead_end
      xy     = @prng.sample valid_children(parent.x, parent.y)
      return curr_count if xy == nil
      x, y = *xy
      add_room(x, y, type, parent)
      curr_count += 1
    end
    curr_count
  end

  # @param [Integer] count The number of super secret rooms to generate
  def generate_super_secret_rooms(count)
    generate_generic_deadend_room(count, :super_secret)
  end

  # @param [Integer] count The number of shop rooms to generate
  def generate_shop_rooms(count)
    generate_generic_deadend_room(count, :shop)
  end

  # @param [Integer] count The number of item rooms to generate
  def generate_item_rooms(count)
    generate_generic_deadend_room(count, :item)
  end

  # @param [Integer] count The number of secret rooms to generate
  def generate_secret_rooms(count)
    # TODO: Despaghettify this whole method.
    # I am writing this comment immediately after writing the method, and I still don't know what exactly it does.

    # Used for scoring candidate coordinate.
    # @param [Array<Integer>] c The candidate coordinate
    score_func = lambda do |c|
      neigh  = coord_neighbors(*c)
      scores = neigh.map do |n|
        nr = get_room *n
        (nr == nil) ? 0 : nr.depth
      end
      [scores.count { |s| s != 0 }, scores.reduce(:+)]
    end

    curr_count = 0
    while curr_count < count
      parent     = get_longest_dead_end
      candidates = valid_children(parent.x, parent.y, 2, 4)
      candidates = candidates.find_all do |c|
        neigh = coord_neighbors(*c)
        0 != neigh.count do |n|
          nr = get_room(*n)
          nr != nil && nr.type != :boss && nr.type != :super_secret
        end
      end
      tmp        = 0
      candidates = candidates.sort_by { |c| [*(score_func.call(c)), tmp += 1] }.reverse
      max_score  = score_func.call(candidates.last)
      candidates = candidates.find_all do |c|
        score = score_func.call(c)
        score[0] == max_score[0] && score[1] == max_score[1]
      end
      xy         = @prng.sample candidates
      return curr_count if xy == nil
      x, y = *xy
      add_room(x, y, type, parent)
      curr_count += 1
    end
    curr_count
  end


  def pretty_str
    char_map                = Hash.new('#')
    char_map[:spawn]        = 'O'
    char_map[:normal]       = 'o'
    char_map[:boss]         = 'X'
    char_map[:item]         = 'I'
    char_map[:shop]         = '$'
    char_map[:super_secret] = '¿'
    char_map[:secret]       = '?'

    xs  = ((@rooms.map { |r| r.x }.min - 1)..(@rooms.map { |r| r.x }.max + 1))
    ys  = ((@rooms.map { |r| r.y }.min - 1)..(@rooms.map { |r| r.y }.max + 1))
    str = '╔' + xs.map { |_| '═' }.join('') + "╗\n"
    ys.to_a.reverse.each do |y|
      str += '║'
      xs.each do |x|
        room = get_room(x, y)
        str  += (room != nil) ? char_map[room.type] : " "
      end
      str += "║\n"
    end
    str + '╚' + xs.map { |_| '═' }.join('') + '╝'
  end
end

class Dungeon
  attr_accessor :layout

  # @param [Hash{Pair => Room}] rooms
  def initialize rooms

  end
end