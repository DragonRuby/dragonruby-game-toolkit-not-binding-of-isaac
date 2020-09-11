# Why would a user press the `W` key?
# A: They want to tell the game they pressed the `W` key.
# B: They want to tell the game they pressed the key bound to `move up`.
# C: They want to tell the game to move their character up.
# D: They want their character to move up.
#
# A and B both assume that the player is actively thinking about the keyboard as an input device,
#   which shouldn't be the case if your controls are intuitive.
# A, B, and C all assume the player is actively aware of the fact that they don't directly control their character, and
#   that they want to tell the thing that does control their character what to do. Again, this shouldn't be the case.
# D is the correct answer in most cases. Players don't think about what they want to tell the game, they think about
#   what they intend for their character to do.
#
# Thus, viewing player input as a set of intentions, rather than as a set of key presses, reduces the disconnect
#   between how the player thinks about input and how the code "thinks" about input.

module Controller

  # @return [Hash] The controller key mapping. If you change the values, you change the controls.
  def Controller::keymap
    {
        move:  {
            up:    :w,
            down:  :s,
            left:  :a,
            right: :d
        },
        shoot: {
            up:    :up,
            down:  :down,
            left:  :left,
            right: :right
        }
    }
  end

  def Controller::initial_state
    {
        shoot: {
            vertical:   nil,
            horizontal: nil
        },
        move:  {
            vertical:   nil,
            horizontal: nil
        }
    }
  end

  # @param [GTK::Inputs] raw_inputs
  # @param [Symbol] key
  def Controller::get_key_down(raw_inputs, key)
    !!(raw_inputs.keyboard.key_down.send(key) || false)
  end

  # @param [GTK::Inputs] raw_inputs
  # @param [Symbol] key
  def Controller::get_key_held(raw_inputs, key)
    !!(raw_inputs.keyboard.key_held.send(key) || false)
  end

  # @param [GTK::Inputs] raw_inputs
  # @param [Symbol] key
  def Controller::get_key(raw_inputs, key)
    Controller::get_key_down(raw_inputs, key) || Controller::get_key_held(raw_inputs, key)
  end

  # @param [GTK::Inputs] raw_inputs
  # @param [Hash] keymap
  def Controller::get_player_inputs(raw_inputs, keymap)
    {
        move:       keymap[:move].map { |direction, key| [direction, Controller::get_key(raw_inputs, key)] }.to_h,
        shoot:      keymap[:shoot].map { |direction, key| [direction, Controller::get_key(raw_inputs, key)] }.to_h,
        init_shoot: keymap[:shoot].map { |direction, key| [direction, Controller::get_key_down(raw_inputs, key)] }.to_h,
    }
  end

  # @param [GTK::Inputs] raw_inputs
  # @param [Hash] game
  def Controller::get_player_intent(raw_inputs, game)
    inputs = Controller::get_player_inputs(raw_inputs, game[:keymap])
    {
        shoot: {
            vertical:   if inputs[:shoot][:up] != inputs[:shoot][:down] # If holding shoot up XOR holding shoot down
                          inputs[:shoot][:up] ? :up : :down # Shoot either up or down
                        elsif inputs[:init_shoot][:up] != inputs[:init_shoot][:down] # If just starting to shoot up XOR just starting to shoot down
                          inputs[:init_shoot][:up] ? :up : :down # Shoot either up or down
                        elsif inputs[:shoot][:up] || inputs[:shoot][:down]  # If the player is holding one of the vertical fire keys and we can't decide which way to shoot
                          game[:intent][:shoot][:vertical] # Fallback to the player's vertical shooting intention on the last frame.
                        else
                          nil
                        end,
            horizontal: if inputs[:shoot][:left] != inputs[:shoot][:right] # Same logic as above.
                          inputs[:shoot][:left] ? :left : :right
                        elsif inputs[:init_shoot][:left] != inputs[:init_shoot][:right]
                          inputs[:init_shoot][:left] ? :left : :right
                        elsif inputs[:shoot][:left] || inputs[:shoot][:right]
                          game[:intent][:shoot][:horizontal]
                        else
                          nil
                        end
        },
        move:  {
            vertical:   (inputs[:move][:up] == inputs[:move][:down]) ? nil : (inputs[:move][:up] ? :up : :down), # If moving up and down or neither, return nil. Else, return whether we want to move up or down.
            horizontal: (inputs[:move][:left] == inputs[:move][:right]) ? nil : (inputs[:move][:left] ? :left : :right) # Same logic as above.
        }
    }
  end
end