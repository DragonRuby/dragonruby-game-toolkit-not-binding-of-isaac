# Maps GTK::Inputs to actionable facts.
module InputMapper
  def self.controls
    {
        walk:  {
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

  # @param [GTK::Inputs] inputs
  # @param [Symbol] key
  def self.get_key(inputs, key)
    inputs.keyboard.key_held.send(key) || inputs.keyboard.key_down.send(key) || false
  end

  # @param [GTK::Inputs] inputs
  def self.process(inputs)
    {
        walk:  InputMapper.controls[:walk].map { |direction, key| [direction, InputMapper.get_key(inputs, key)] }.to_h,
        shoot: InputMapper.controls[:shoot].map { |direction, key| [direction, InputMapper.get_key(inputs, key)] }.to_h,
    }
  end
end