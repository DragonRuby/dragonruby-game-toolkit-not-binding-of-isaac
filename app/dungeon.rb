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
    generate_boss_rooms(room_counts[:boss] || 1)
    generate_super_secret_rooms(room_counts[:super_secret] || 1)
    # TODO: Maybe we want to add shops and item rooms shuffled together? So they aren't all on one side of the dungeon?
    generate_shop_rooms(room_counts[:shop] || 1)
    generate_item_rooms(room_counts[:item] || 1)
    generate_secret_rooms(room_counts[:secret] || 1)
    # TODO: Assign room variants
    Dungeon.new(@rooms, layout, @hex_seed)
  end

  # @param [Integer] count
  def generate_normal_rooms(count)
    room_counter = 0
    a            = []
    #noinspection RubyYardParamTypeMatch
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
      raise RuntimeError, "Found no valid dead ends! What!?"
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
    banned_types = {
        boss:         true,
        item:         true,
        super_secret: true,
        secret:       true,
    }

    cur_num = 0
    xs      = ((@rooms.map { |r| r.x }.min)..(@rooms.map { |r| r.x }.max))
    ys      = ((@rooms.map { |r| r.y }.min)..(@rooms.map { |r| r.y }.max))
    while cur_num < count
      cands  = xs.flat_map { |x| ys.map { |y| [x, y] } }.find_all do |xy|
        get_room(*xy) == nil && 1 <= coord_neighbors(*xy).count do |n|
          r = get_room(*n)
          !(r == nil || banned_types[r.type])
        end
      end
      tmp    = 0
      cands  = cands.sort_by do |cand|
        [
            coord_neighbors(*cand)
                .map { |c| get_room(*c) }          # Map each coordinate to its respective room, or nil if unoccupied.
                .find_all { |a| a != nil }         # Discard the unoccupied rooms.
                .combination(2)                    # Pair up the rooms.
                .map { |ab| ab[0].dist_to(ab[1]) } # Get the distance between the rooms in each pair.
                .max || 0,                         # Use the highest score if there was at least one pair of rooms, default to a score of 0.
            tmp += 1
        ]
      end
      coord  = cands[-1]
      neighs = coord_neighbors(*coord).find_all { |c| get_room(*c) != nil }.map { |c| get_room(*c) }
      raise(RuntimeError, "This should be impossible") if neighs.empty?
      #noinspection RubyYardParamTypeMatch
      room = add_room(coord[0], coord[1], :secret, neighs.pop)
      neighs.each do |neigh|
        room.add_neighbor neigh
        neigh.add_neighbor room
      end
      cur_num += 1
    end
    cur_num
  end


  def pretty_str
    char_map                = Hash.new('#')
    char_map[:spawn]        = '█'
    char_map[:normal]       = 'o'
    char_map[:boss]         = 'X'
    char_map[:item]         = 'I'
    char_map[:shop]         = '$'
    char_map[:super_secret] = '¿'
    char_map[:secret]       = '?'

    xs  = ((@rooms.map { |r| r.x }.min - 1)..(@rooms.map { |r| r.x }.max + 1))
    ys  = ((@rooms.map { |r| r.y }.min - 1)..(@rooms.map { |r| r.y }.max + 1))
    str = "\n╔" + xs.map { |_| '═' }.join('') + "╗\n"
    ys.to_a.reverse.each do |y|
      str += '║'
      xs.each do |x|
        room = get_room(x, y)
        #str  += (room != nil) ? char_map[room.type] : " "
        if room == nil
          str += " "
        elsif room.type == :normal
          str += room.directional_char
        else
          str += char_map[room.type]
        end
      end
      str += "║\n"
    end
    str + '╚' + xs.map { |_| '═' }.join('') + '╝'
  end
end

# TODO
class Dungeon
  attr_reader :layout
  attr_reader :rooms
  attr_reader :coord
  attr_reader :sprite
  attr_reader :whole_map_str
  attr_reader :room_map_str
  attr_reader :seed

  # @param [Array<Room>] rooms
  # @param [Hash] layout
  # @param [String] seed
  def initialize(rooms, layout, seed)
    @rooms  = rooms
    @layout = layout
    @coord  = [0, 0]
    @seed   = seed
    update_sprite
  end

  # @param [Integer] x
  # @param [Integer] y
  # @return [Room]
  def get_room(x, y)
    return nil unless @layout.has_key? y
    @layout[y][x]
  end

  def curr_room
    get_room(*coord)
  end

  # @param [TrueClass, FalseClass] curr_only
  def pretty_str(curr_only = false)
    char_map                = Hash.new('#')
    char_map[:spawn]        = '█'
    char_map[:normal]       = 'o'
    char_map[:boss]         = 'X'
    char_map[:item]         = 'I'
    char_map[:shop]         = '$'
    char_map[:super_secret] = '¿'
    char_map[:secret]       = '?'

    xs  = ((@rooms.map { |r| r.x }.min - 1)..(@rooms.map { |r| r.x }.max + 1))
    ys  = ((@rooms.map { |r| r.y }.min - 1)..(@rooms.map { |r| r.y }.max + 1))
    str = "\n╔" + xs.map { |_| '═' }.join('') + "╗\n"
    str = "\n " + xs.map { |_| ' ' }.join('') + " \n" if curr_only
    ys.to_a.reverse.each do |y|
      str += curr_only ? ' ' : '║'
      xs.each do |x|
        room = get_room(x, y)
        if !curr_only || room == curr_room
          if room == nil
            str += " "
          elsif room.type == :normal
            str += room.directional_char
          else
            str += char_map[room.type]
          end
        else
          str += " "
        end
      end
      str += curr_only ? " \n" : "║\n"
    end
    if curr_only
      str + ' ' + xs.map { |_| ' ' }.join('') + ' '
    else
      str + '╚' + xs.map { |_| '═' }.join('') + '╝'
    end
  end

  def update_sprite
    hash_walker = ROOM_SPRITES
    get_room(*coord)&.ordered_neighbor_dirs&.each { |d| hash_walker = hash_walker[d] }
    path = hash_walker[get_room(*coord)&.ordered_neighbor_dirs&.last]
    # puts path
    @sprite        = [0, 0, 1280, 720, path]
    @whole_map_str = pretty_str
    @room_map_str  = pretty_str(true)
  end

  # @param [Room] room
  def set_room(room)
    @coord = [room.x, room.y]
    update_sprite
  end
end
