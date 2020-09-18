module Room
  def Room::initial_state
    {
        x:     0,
        y:     0,
        size: 1, #unit multiplier
        w: 1280*:size,
        h: 720*:size,
        type:  :spawn,
        stage: 1,
        sprites: {
          floor_tile: 'sprites/room/steel_diagonal_tile.png',
        }
    }
  end

  def Room::renderables(player, room)
    out = []
    if room[:size] == 1
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
    else
      #somehow keep the player in the middle of the screen while the floor sprites move around
      #when player is farther than 640 x and 480 y away from a wall
    end
    
  end
end
