require 'app/dungeon.rb'

#@formatter:off
def make_rubymine_happy;def xrepl;end;def repl;end;end;xrepl do;make_rubymine_happy;end
#@formatter:on

repl do
  require 'app/dungeon.rb'
  dm = DungeonMaster.new("DEADBEEF") if true
  dm.generate(2)
  puts dm.to_s
end