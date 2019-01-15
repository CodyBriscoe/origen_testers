require 'pathname'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class VariablesFile
        include OrigenTesters::Generator

        attr_reader :flow_control_variables, :runtime_control_variables
        attr_accessor :filename, :id

        def initialize(options = {})
          @flow_control_variables = []
          @runtime_control_variables = []
        end

        def subdirectory
          'testflow/mfh.testflow.setup'
        end

        def add_flow_control_variables(*vars)
          @flow_control_variables += vars
        end

        def add_runtime_control_variables(*vars)
          @runtime_control_variables += vars
        end

        def clean_flow_control_variables
          flow_control_variables.uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        def clean_runtime_control_variables
          runtime_control_variables.uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        def to_be_written?
          tester.smt7?
        end
      end
    end
  end
end
