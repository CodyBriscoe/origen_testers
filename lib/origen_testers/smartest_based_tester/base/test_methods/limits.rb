module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class Limits
          attr_reader :test_method
          attr_accessor :lo_limit, :hi_limit
          attr_accessor :unit

          def initialize(test_method)
            @test_method = test_method
          end

          def unit=(val)
            case val.to_s.downcase
            when 'v', 'volts'
              @unit = 'V'
            when 'a', 'amps'
              @unit = 'A'
            else
              fail "Limit unit of #{val} not implemented yet!"
            end
          end

          def to_s
            if !lo_limit && !hi_limit
              "\"#{test_name}\"" + ' = "":"NA":"":"NA":"":"":""'
            elsif !lo_limit
              "\"#{test_name}\"" + " = \"\":\"NA\":\"#{hi_limit}\":\"LE\":\"#{unit}\":\"\":\"0\""
            elsif !hi_limit
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"\":\"NA\":\"#{unit}\":\"\":\"0\""
            else
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"#{hi_limit}\":\"LE\":\"#{unit}\":\"\":\"0\""
            end
          end

          def set_lo_limit(val)
            self.lo_limit = val
          end

          def set_hi_limit(val)
            self.hi_limit = val
          end

          private

          def test_name
            name = test_method.test_name if test_method.respond_to?(:test_name)
            name || 'Functional'
          end
        end
      end
    end
  end
end
