# Pattern generator tests

# Legacy tests
ARGV = %w(j750.list -t debug_j750_dut2.rb -r approved/j750)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(v93k_workout -t v93k_legacy.rb -r approved/v93k)
load "#{Origen.top}/lib/origen/commands/generate.rb"

# Common tests
ARGV = %w(regression.list -t debug_j750.rb -r approved/j750)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t debug_j750_hpt.rb -r approved/j750_hpt)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t debug_ultraflex.rb -r approved/ultraflex)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t debug_v93k.rb -r approved/v93k)
load "#{Origen.top}/lib/origen/commands/generate.rb"
