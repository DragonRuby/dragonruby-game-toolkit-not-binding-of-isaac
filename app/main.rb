class CameraMovement
  attr_accessor :state, :inputs, :outputs, :grid

  #===========================================================================================
  #Serialize
  def serialize
    {state: state, inputs: inputs, outputs: outputs, grid: grid }
  end
  
  def inspect
    serialize.to_s
  end

  def to_s
    serialize.to_s
  end

  #===========================================================================================
  #Tick
  def tick
    defaults
    calc
    render
    input
  end

  #===========================================================================================
  #Default functions
  def defaults
    outputs.background_color = [0,0,0]
    state.player ||= new_player
    state.camera ||= new_camera
    state.room ||= new_room
  end

  def default_player x, y, w, h, sprite_path
    state.new_entity(:player,
                     { x: x,
                       y: y,
                       dy: 0,
                       dx: 0,
                       w: w,
                       h: h,
                       damage: 0,
                       dead: false,
                       orientation: "down",
                       max_alpha: 255,
                       sprite_path: sprite_path})
  end

  def default_floor_tile x, y, w, h, sprite_path
    state.new_entity(:room,
                     { x: x,
                       y: y,
                       w: w,
                       h: h,
                       sprite_path: sprite_path})
  end

  def default_camera x, y, w, h
    state.new_entity(:camera,
                     { x: x,
                       y: y,
                       dx: 0,
                       dy: 0,
                       w: w,
                       h: h})
  end

  def new_player
    default_player(0, 0, 64, 64,
                   "sprites/player/player_#{state.player.orientation}_standing.png")
  end

  def new_camera
    default_camera(0,0,1280,720)
  end

  def new_room
    default_floor_tile(0,0,1024,1024,'sprites/rooms/camera_room.png')
  end

  #===========================================================================================
  #Calculation functions
  def calc
    calc_player
    calc_camera
  end

  def calc_player
    state.player.x += state.player.dx
    state.player.y += state.player.dy

    if state.player.x - 20 < state.room.x
      state.player.x = state.room.x + 20
    elsif state.player.x + 24 > state.room.w
      state.player.x = state.room.w - 24
    end
    if state.player.y < state.room.y
      state.player.y = state.room.y
    elsif state.player.y + 64 > state.room.h
      state.player.y = state.room.h - 64
    end
  end

  def calc_camera
    timeScale = 1
    targetX = state.player.x - state.camera.w/2
    targetY = state.player.y - state.camera.h/2
    state.camera.x += (targetX - state.camera.x) * 0.1 * timeScale
    state.camera.y += (targetY - state.camera.y) * 0.1 * timeScale
  end

  #===========================================================================================
  #Render Functions
  def render
    render_floor
    render_player
  end

  def render_player
    screenX = state.player.x - state.camera.x
    screenY = state.player.y - state.camera.y
    
    outputs.sprites << [screenX-32, screenY,
                        state.player.w, state.player.h,
                        "sprites/player/player_#{state.player.orientation}_standing.png"]
  end

  def render_floor
    screenX = state.room.x - state.camera.x
    screenY = state.room.y - state.camera.y

    outputs.sprites << [screenX, screenY, state.room.w, state.room.h, state.room.sprite_path]
  end

  #===========================================================================================
  #Input functions
  def input
    input_move
  end

  def input_move
    if inputs.keyboard.key_held.w
      state.player.dy = 5
      state.player.orientation = "up"
    elsif inputs.keyboard.key_held.s
      state.player.dy = -5
      state.player.orientation = "down"
    else
      state.player.dy *= 0.8
    end
    if inputs.keyboard.key_held.a
      state.player.dx = -5
      state.player.orientation = "left"
    elsif inputs.keyboard.key_held.d
      state.player.dx = 5
      state.player.orientation = "right"
    else
      state.player.dx *= 0.8
    end

    outputs.labels << [128,512,"#{state.player.x.round()}",8,2,255,255,255,255]
    outputs.labels << [128,480,"#{state.player.y.round()}",8,2,255,255,255,255]
  end
end

$camera_movement = CameraMovement.new

def tick args
  $camera_movement.inputs  = args.inputs
  $camera_movement.outputs = args.outputs
  $camera_movement.state   = args.state
  $camera_movement.grid    = args.grid
  $camera_movement.tick
end
