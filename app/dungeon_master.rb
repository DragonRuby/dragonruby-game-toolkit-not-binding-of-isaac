module DungeonMaster
  # @param [Hash] params
  def DungeonMaster::generate(params)
    initial_layout = DungeonMaster::add_room!({}, DungeonMaster::init_room(0, 0, :spawn, 1))
    prng           = PRNG.new(params[:config][:seed])
    layout         = (1..params[:room_counts][:normal]).reduce(initial_layout) { |acc, _| DungeonMaster::add_normal_room!(acc, 1, prng) }
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
  def DungeonMaster::init_room(x, y, type, stage)
    {
        x:     x,
        y:     y,
        type:  type,
        stage: stage
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
  def DungeonMaster::forms_2x2?(layout, x, y)
    north = DungeonMaster::get_room(layout, x, y + 1) != nil
    south = DungeonMaster::get_room(layout, x, y - 1) != nil
    east  = DungeonMaster::get_room(layout, x + 1, y) != nil
    west  = DungeonMaster::get_room(layout, x - 1, y) != nil

    (((DungeonMaster::get_room(layout, x + 1, y + 1) != nil) && north && east) ||
        ((DungeonMaster::get_room(layout, x - 1, y + 1) != nil) && north && west) ||
        ((DungeonMaster::get_room(layout, x + 1, y - 1) != nil) && south && east) ||
        ((DungeonMaster::get_room(layout, x - 1, y - 1) != nil) && south && west))
  end

  # @param [Hash] layout
  # @param [Integer] stage
  # @param [Hash] config
  # @param [PRNG] prng
  def DungeonMaster::add_normal_room!(layout, stage, prng)
    min_x, max_x = *(layout.values.reduce([999999, -999999]) { |acc, val| val[:stage] == stage ? [acc[0].lesser(val.x), acc[1].greater(val.x)] : acc })
    min_y, max_y = *(layout.values.reduce([999999, -999999]) { |acc, val| val[:stage] == stage ? [acc[0].lesser(val.y), acc[1].greater(val.y)] : acc })
    valid_coords = (min_x - 1..max_x + 1).to_a.product((min_y - 1..max_y + 1).to_a).find_all do |xy|
      if DungeonMaster::get_room(layout, *xy) != nil || DungeonMaster::forms_2x2?(layout, *xy)
        false
      else
        neighbor_list = DungeonMaster::neighbors(layout, *xy)
        (!neighbor_list.empty?) && neighbor_list.all? do |room|
          ([:normal, :spawn].include?(room[:type]) && room[:stage] == stage) || (room[:type] == :boss && room[:stage] == stage - 1)
        end
      end
    end
    room_coords  = prng.sample(valid_coords)
    add_room!(layout, DungeonMaster::init_room(*room_coords, :normal, stage))
    layout
  end

  # @param [Hash] layout
  def DungeonMaster::layout_str(layout)
    min_x, max_x = *(layout.values.reduce([999999, -999999]) { |acc, val| [acc[0].lesser(val.x), acc[1].greater(val.x)] })
    min_y, max_y = *(layout.values.reduce([999999, -999999]) { |acc, val| [acc[0].lesser(val.y), acc[1].greater(val.y)] })
    char_arr     = (min_y..max_y + 1).to_a.map { |_| (" " * (max_x + 1 - min_x)).chars }
    layout.values.each do |room|
      char_arr[room[:y] - min_y][room[:x] - min_x] = room[:type].to_s[0]
    end
    char_arr.map { |chs| chs.join('') }.join("\n")
  end
end