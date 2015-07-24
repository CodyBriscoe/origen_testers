module Testers
  module IGXLBasedTester
    class UltraFLEX
      # Include this module in an interface class to make it an UltraFLEX interface and to give
      # access to the UltraFLEX program generator API
      module Generator
        extend ActiveSupport::Concern

        require_all "#{RGen.root!}/lib/testers/igxl_based_tester/ultraflex"
        require 'testers/igxl_based_tester/base/generator'

        included do
          include Base::Generator
          PLATFORM = UltraFLEX
        end
      end
    end
  end
end
