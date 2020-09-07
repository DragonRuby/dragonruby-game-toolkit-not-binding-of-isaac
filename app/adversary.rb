class Adversary
     attr_reader :sprite

     def initialize
          @sprite = Sprite.new(50,50)
          @pos = XYVector.new(1280/2 - @sprite.w/2,720/2  - @sprite.h/2)
          @sprite.path = 'sprites/placeholder/square.png'
          @sprite.x = @pos.x
          @sprite.y = @pos.y
          @sprite.angle = 0
          @living = true
     end

     def update args
          if (@living)
               d=1
               tempx = @pos.x+@sprite.w/2
               tempy = @pos.y+@sprite.h/2
               magnitude=((-$game.player.pos.x+tempx)**2+(-$game.player.pos.y+tempy)**2)**0.5
               @pos.x-=(tempx+-$game.player.pos.x)*(d/magnitude)
               @pos.y-=(tempy+-$game.player.pos.y)*(d/magnitude)




               @sprite.x = @pos.x
               @sprite.y = @pos.y
          end
     end

     def render args
          args.outputs.sprites << @sprite
     end

end
