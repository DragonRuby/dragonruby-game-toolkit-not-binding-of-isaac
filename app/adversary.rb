class Adversary
     attr_reader :sprite

     def initialize
          @sprite = Sprite.new(64,64)
          @pos = XYVector.new(1280/2 - @sprite.w/2,720/2  - @sprite.h/2)
          @sprite.path = 'sprites/placeholder/enemy.png'
          @sprite.x = @pos.x
          @sprite.y = @pos.y
          @sprite.angle = 0
          @living = true
          @speed=1.5
     end

     def update args

          if (@living)
               tempx = @pos.x+@sprite.w/2
               tempy = @pos.y+@sprite.h/2
               magnitude=((-$game.player.pos.x+tempx)**2+(-$game.player.pos.y+tempy)**2)**0.5
               @pos.x-=(tempx+-$game.player.pos.x)*(@speed/magnitude)
               @pos.y-=(tempy+-$game.player.pos.y)*(@speed/magnitude)

               for bullet in $game.bullets
                    if bullet.sprite.rect.intersect_rect?(@sprite.rect)
                         @living = false
                    end

               end



               @sprite.x = @pos.x
               @sprite.y = @pos.y
          end
     end

     def render args
          if (@living)
               args.outputs.sprites << @sprite
          end
     end

end
