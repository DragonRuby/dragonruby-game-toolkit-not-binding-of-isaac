class Adversary
     attr_reader :sprite

     def initialize
          @sprite = Sprite.new(50,50)
          @sprite.path = 'sprites/placeholder/square.png'
          @sprite.x = 1280/2 - @sprite.w/2
          @sprite.y = 720/2  - @sprite.h/2
          @sprite.angle = 0
          @living = true
     end

     def update args
          if (@living)
               @sprite.x+=5
          end
     end

     def render args
          args.outputs.sprites << @sprite
     end

end
