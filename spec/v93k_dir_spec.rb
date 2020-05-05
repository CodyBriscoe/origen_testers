require 'spec_helper'

describe 'V93K unique test name generation' do
  before :each do
    # Create a dummy file for the V93K interface to use. Doesn't need to exists, it won't actually be used, just needs to be set.
    # Origen.interface.try(:reset_globals)
    Origen.instance_variable_set('@interface', nil)
  end

  after :all do
    Origen.instance_variable_set('@interface', nil)
  end

  class MyDUT
    include Origen::TopLevel
  end

  class MyInterface
    include OrigenTesters::ProgramGenerators
  end

  it 'Defaults to using v93k standard subdir if flow_subdir is not set' do
    Origen.target.temporary = lambda do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
    Origen.load_target
    Flow.create interface: 'MyInterface' do
    end
    Origen.interface.sheet_generators.first.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/testflow/mfh.testflow.group/temp.tf'
  end

  it 'Uses specified flow_subdirectory from interface in output_file' do
    Origen.target.temporary = lambda do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
    Origen.load_target
    Flow.create interface: 'MyInterface' do
      Origen.interface.set_flow_subdirectory('')
    end
    Origen.interface.sheet_generators.first.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/temp.tf'
  end
end
