module DungeonMaster
  # @param [Hash] params
  def DungeonMaster::generate(params)
    initial_layout = DungeonMaster::add_room!({}, Room::initial_state)
    prng           = PRNG.new(params[:config][:seed])
    layout, _      = (1..params[:room_counts][:normal]).reduce([initial_layout, [[0, 0]]]) { |acc, _| DungeonMaster::add_normal_room!(acc[0], acc[1], 1, prng) }
    puts DungeonMaster::layout_str(layout)
  end

  def DungeonMaster::default_params
    {
        total_stages: 3,
        room_counts:  {
            normal: 100,
            boss:   1,
            item:   1,
            shop:   1
        },
        config:       {
            seed: 123456789
        }
    }
  end

  # @param [Integer] x
  # @param [Integer] y
  # @param [Symbol] type
  # @param [Integer] stage
  def DungeonMaster::init_room(x, y, type, stage, floor_tile)
    {
        x:     x,
        y:     y,
        type:  type,
        stage: stage,
        sprites: {
          floor_tile: floor_tile,
        }
    }
  end

  # @param [Hash] layout
  # @param [Integer] x
  # @param [Integer] y
  def DungeonMaster::get_room(layout, x, y)
    layout["#{(x >= 0 ? '+' : '')}#{x}#{(y >= 0 ? '+' : '')}#{y}".to_sym]
  end

  # @param [Hash] layout
  # @param [Hash] room
  # TODO: CURE SIDE EFFECT! Currently modifies layout parameter.
  def DungeonMaster::add_room!(layout, room)
    layout["#{(room[:x] >= 0 ? '+' : '')}#{room[:x]}#{(room[:y] >= 0 ? '+' : '')}#{room[:y]}".to_sym] = room
    layout
  end

  # @param [Hash] layout
  # @param [Integer] x
  # @param [Integer] y
  def DungeonMaster::neighbors(layout, x, y)
    [[1, 0], [-1, 0], [0, 1], [0, -1]].map { |offset| DungeonMaster::get_room(layout, x + offset[0], y + offset[1]) }.compact
  end

  # @param [Hash] layout
  # @param [Integer] x
  # @param [Integer] y
  def DungeonMaster::valid_children(layout, x, y)
    child_coords = [[1, 0], [-1, 0], [0, 1], [0, -1]].map { |xy| [xy[0] + x, xy[1] + y] }
    child_coords.find_all { |xy| DungeonMaster::neighbors(layout, *xy).length == 1 }
  end

  # @param [Hash] layout
  # @param [Array] working_set
  # @param [Integer] stage
  # @param [Hash] config
  # @param [PRNG] prng
  # Has side effects due to add_room!
  def DungeonMaster::add_normal_room!(layout, working_set, stage, prng)
    parent   = prng.sample working_set
    children = DungeonMaster::valid_children(layout, *parent)
    if children.empty?
      return DungeonMaster::add_normal_room!(layout, working_set - [parent], stage, prng)
    else
      child      = prng.sample children
      new_layout = DungeonMaster::add_room!(layout, DungeonMaster::init_room(*child, :normal, stage, 'sprites/room/steel_diagonal_tile.png'))
      return [new_layout, working_set + [child]]
    end
  end

  # @param [Hash] layout
  def DungeonMaster::layout_str(layout)
    min_x, max_x = *(layout.values.reduce([999999, -999999]) { |acc, val| [acc[0].lesser(val.x), acc[1].greater(val.x)] })
    min_y, max_y = *(layout.values.reduce([999999, -999999]) { |acc, val| [acc[0].lesser(val.y), acc[1].greater(val.y)] })
    char_arr     = (min_y..max_y).to_a.map { |_| (" " * (max_x + 1 - min_x)).chars }
    layout.each_value do |room|
      char_arr[room[:y] - min_y][room[:x] - min_x] = room[:type].to_s[0]
    end
    char_arr.map { |chs| chs.join('') }.join("\n")
  end

  def DungeonMaster::renderables(player)
    tile_sprite = [0,0,64,64,'sprites/rooms/steel_diagonal_tile.png']
    out = []
    i = 0
    j = 0
    height = 12 #the amount of sprites to be placed
    width = 20
    while i < width
      while j < height
        out.append([64*i,64*j,64,64,'sprites/rooms/steel_diagonal_tile.png'].sprite)
        j+=1
      end
      j = 0
      i+=1
    end
    return out
  end
end
