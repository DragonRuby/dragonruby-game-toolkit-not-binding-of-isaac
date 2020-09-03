# RubyMine doesn't support CTAGS, this gets it to stop yelling at me for RubyResolve issues
unless respond_to?(:trace!)
  # mocks/dragon contains a copy of the files at https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/tree/master/dragon
  #   except index.rb has the paths changed to make RubyMine happy
  require 'mocks/dragon/index.rb'

  def attr_sprite; include AttrSprite end
end