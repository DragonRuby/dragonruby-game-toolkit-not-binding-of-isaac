module Tests
  def self.test_dungeon_generation n
    iters = 10
    srand n**2
    $gtk.reset n**2
    seed  = "0123456789qwertyuiopasdfghjklzxcvbnm".split('').shuffle.first(8).join('')
    pp    = nil
    time  = 0.0
    count = 0
    (1..iters).each do |m|
      srand m + n**2
      $gtk.reset m + n**2
      dm   = DungeonMaster.new(seed)
      time += profile('dungeon generation', false) {
        dm.generate(
            {
                normal:       40,
                boss:         2,
                super_secret: 1,
                shop:         2,
                item:         2,
                secret:       5
            }
        )
      }[1]
      pp   ||= dm.pretty_str
      raise(RuntimeError, "Non deterministic dungeon generation detected!") if pp != dm.pretty_str
    end
    puts "average time to generate: #{(time.fdiv iters)} seconds"
    puts "seed: " + seed + pp

  end

  def self.test_dungeon_secret
    GTK::Trace::IGNORED_METHODS << :get_room
    GTK::Trace::IGNORED_METHODS << :x
    GTK::Trace::IGNORED_METHODS << :y
    GTK::Trace::IGNORED_METHODS << :coord_neighbors
    seed = "106dqjno"
    dm   = DungeonMaster.new(seed)
    dm.generate({
                    normal:       40,
                    boss:         2,
                    super_secret: 1,
                    shop:         2,
                    item:         2,
                    secret:       5
                })
    puts "seed: " + seed + dm.pretty_str

  end
end