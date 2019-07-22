require 'pathname'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class VariablesFile
        include OrigenTesters::Generator

        attr_reader :variables
        attr_accessor :filename, :id

        def initialize(options = {})
        end

        def subdirectory
          'testflow/mfh.testflow.setup'
        end

        def add_variables(vars)
          if @variables
            vars.each do |k, v|
              if k == :empty?
                @variables[:empty?] ||= v
              else
                v.each do |k2, v2|
                  unless v2.empty?
                    @variables[k][k2] |= v2
                  end
                end
              end
            end
          else
            @variables = vars
          end
        end

        # What SMT7 calls a flag
        def flags
          (variables[:all][:referenced_enables] + variables[:all][:set_enables]).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        # What SMT7 calls a declaration
        def declarations
          (variables[:all][:jobs] + variables[:all][:referenced_flags] + variables[:all][:set_flags]).uniq.sort do |x, y|
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
