# This target is used to run the legacy test patterns from RGen core
$dut    = Testers::Test::DUT2.new
$nvm    = Testers::Test::NVM.new    # Instantiate the NVM instance DUT2 uses
$tester = Testers::V93K.new

RGen.mode = :debug
