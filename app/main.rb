require 'lib/zif/services/tick_trace_service.rb'
$trace_service = Zif::TickTraceService.new(0.03)

require 'lib/deepmerge.rb'
require 'lib/xy_vector.rb'
require 'lib/prng.rb'
require 'app/game.rb'
require 'app/player.rb'
require 'app/bullets.rb'
require 'app/bullet.rb'
require 'app/parametric_bullet.rb'
require 'app/dungeon_master.rb'
require 'app/controller.rb'
require 'app/boss.rb'
require 'app/upgrade.rb'

$moving_avg = [16666] * 120
$last_idx   = $moving_avg.length - 1
$last_time  = Time.now.usec

# @param [GTK::Args] args
def tick(args)
  #$trace_service.reset_tick
  #$trace_service.mark('tick')
  t                      = Time.now.usec
  dt                     = t - $last_time
  dt                     = $moving_avg[$last_idx] if dt < 0
  $last_idx              = ($last_idx + 1) % $moving_avg.length
  $moving_avg[$last_idx] = dt
  $last_time             = t
  args.state.tps         = ($moving_avg.length * 1000000) / $moving_avg.reduce(:plus)
  Game::tick args
  #$trace_service.mark('tock')
  #$trace_service.finish
end

def perf_test_soy
  def Bullets::spawn_new_parametric_bullets(game); return []; end
  $state.game[:player][:upgrades].push(Upgrade::RANGE_MULT)
  $state.game[:player][:upgrades].push(Upgrade::RANGE_MULT)
  $state.game[:player][:upgrades].push(Upgrade::DELAY_MULT)
  $state.game[:player][:upgrades].push(Upgrade::DELAY_MULT)
  $state.game[:player][:upgrades].push(Upgrade::DELAY_MULT)
  $state.game[:player][:upgrades].push(Upgrade::DELAY_MULT)
  # Now try moving and shooting. With a lot of bullets on screen, the game lags. Then you start moving super fast when you stop firing.
end
