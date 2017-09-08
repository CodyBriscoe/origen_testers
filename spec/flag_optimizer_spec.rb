require 'spec_helper'
require 'origen_testers/smartest_based_tester/base/processors'

describe 'The V93K flah optimizer' do

  Processors = OrigenTesters::SmartestBasedTester::Base::Processors

  def process(ast)
    Processors::FlagOptimizer.new.process(ast)
  end

  it "works at the top-level" do
    ast1 = 
      s(:flow,
        s(:name, "prb1"),
        s(:test,
          s(:name, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:set_run_flag, "t1_FAILED", "auto_generated"),
            s(:continue))),
        s(:run_flag, "t1_FAILED", true,
          s(:test,
            s(:name, "test2"))))

    ast2 = 
      s(:flow,
        s(:name, "prb1"),
        s(:test,
          s(:name, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:test,
              s(:name, "test2")))))

    process(ast1).should == ast2
  end

  it "doesn't eliminate flags with later references" do
    ast1 = 
      s(:flow,
        s(:name, "prb1"),
        s(:test,
          s(:name, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:set_run_flag, "t1_FAILED", "auto_generated"),
            s(:test,
              s(:name, "test2")))),
        s(:test,
          s(:name, "test3")),
        s(:run_flag, "t1_FAILED", true,
          s(:test,
            s(:name, "test4"))))

    process(ast1).should == ast1
  end

  it "applies the optimization within nested groups" do
    ast1 = 
      s(:flow,
        s(:name, "prb1"),
        s(:group,
          s(:name, "group1"),
          s(:test,
            s(:name, "test1"),
            s(:id, "t1"),
            s(:on_fail,
              s(:set_run_flag, "t1_FAILED", "auto_generated"),
              s(:continue))),
          s(:run_flag, "t1_FAILED", true,
            s(:test,
              s(:name, "test2")))))

    ast2 = 
      s(:flow,
        s(:name, "prb1"),
        s(:group,
          s(:name, "group1"),
          s(:test,
            s(:name, "test1"),
            s(:id, "t1"),
            s(:on_fail,
              s(:test,
                s(:name, "test2"))))))

    process(ast1).should == ast2
  end

end
