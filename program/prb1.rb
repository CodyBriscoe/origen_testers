# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface', flow_description: 'Probe1 Main' do

  self.resources_filename = 'prb1'

  import 'components/prb1_main'

end
