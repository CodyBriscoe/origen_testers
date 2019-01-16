require 'origen_testers/smartest_based_tester/base/processors/extract_flow_vars'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        attr_accessor :test_suites, :test_methods, :lines, :stack, :var_filename
        # Returns an array containing all runtime variables which get set by the flow
        attr_reader :set_runtime_variables

        attr_accessor :add_flow_enable, :flow_name

        def self.generate_flag_name(flag)
          case flag[0]
          when '$'
            flag[1..-1]
          else
            flag.upcase
          end
        end

        def smt8?
          tester.smt8?
        end

        def var_filename
          @var_filename || 'global'
        end

        def subdirectory
          if smt8?
            "#{tester.package_namespace}/flows"
          else
            'testflow/mfh.testflow.group'
          end
        end

        def filename
          base = super.gsub('_flow', '')
          if smt8?
            flow_name(base) + '.flow'
          else
            base
          end
        end

        def flow_enable_var_name
          var = filename.sub(/\..*/, '').upcase
          generate_flag_name("#{var}_ENABLE")
        end

        def flow_name(filename = nil)
          flow_name ||= (filename || self.filename).sub(/\..*/, '').upcase
          if smt8?
            flow_name.gsub(' ', '_')
          else
            flow_name
          end
        end

        def hardware_bin_descriptions
          @hardware_bin_descriptions ||= {}
        end

        def flow_variables
          @flow_variables ||= begin
            vars = Processors::ExtractFlowVars.new.run(ast)
            unless smt8?
              if add_flow_enable
                if add_flow_enable == :enabled
                  vars[:all][:referenced_enables] << [flow_enable_var_name, 1]
                  vars[:this_flow][:referenced_enables] << [flow_enable_var_name, 1]
                else
                  vars[:all][:referenced_enables] << [flow_enable_var_name, 0]
                  vars[:this_flow][:referenced_enables] << [flow_enable_var_name, 0]
                end
              end
            end
            vars
          end
        end

        def at_flow_start
          model # Call to ensure the signature gets populated
        end

        def on_top_level_set
          if top_level?
            if smt8?
              @limits_file = platform::LimitsFile.new(self, manually_register: true, filename: filename.sub(/\..*/, ''), test_modes: @test_modes)
            else
              @limits_file = platform::LimitsFile.new(self, manually_register: true, filename: "#{name}_limits", test_modes: @test_modes)
            end
          else
            @limits_file = top_level.limits_file
          end
        end

        def limits_file
          @limits_file
        end

        def at_flow_end
          # Take whatever the test modes are set to at the end of the flow as what we go with
          @test_modes = tester.limitfile_test_modes
        end

        def ast
          @ast = nil unless @finalized
          @ast ||= begin
            unique_id = smt8? ? nil : sig
            atp.ast(unique_id: unique_id, optimization: :smt,
                  implement_continue: !tester.force_pass_on_continue,
                  optimize_flags_when_continue: !tester.force_pass_on_continue
                   )
          end
        end

        def finalize(options = {})
          super
          @finalized = true
          if smt8?
            @indent = 2
          else
            @indent = add_flow_enable ? 2 : 1
          end
          @lines = []
          @open_test_methods = []
          @stack = { on_fail: [], on_pass: [] }
          @set_runtime_variables = ast.excluding_sub_flows.set_flags
          process(ast)
          unless smt8?
            unless flow_variables[:empty?]
              Origen.interface.variables_file(self).add_variables(flow_variables)
            end
          end
          test_suites.finalize
          test_methods.finalize
          if tester.create_limits_file && !Origen.interface.generating_sub_program?
            render_limits_file
          end
        end

        def render_limits_file
          if limits_file
            limits_file.test_modes = @test_modes
            limits_file.generate(ast)
            limits_file.write_to_file
          end
        end

        def line(str)
          @tab ||= smt8? ? '    ' : '  '
          @lines << (@tab * @indent) + str
        end

        # def on_flow(node)
        #  line '{'
        #  @indent += 1
        #  process_all(node.children)
        #  @indent -= 1
        #  line "}, open,\"#{unique_group_name(node.find(:name).value)}\", \"\""
        # end

        def on_test(node)
          test_suite = node.find(:object).to_a[0]
          if test_suite.is_a?(String)
            name = test_suite
          else
            name = test_suite.name
            test_method = test_suite.test_method
            if test_method.respond_to?(:test_name) && test_method.test_name == '' &&
               n = node.find(:name)
              test_method.test_name = n.value
            end
          end

          if node.children.any? { |n| t = n.try(:type); t == :on_fail || t == :on_pass } ||
             !stack[:on_pass].empty? || !stack[:on_fail].empty?
            if smt8?
              line "#{name}.execute();"
            else
              line "run_and_branch(#{name})"
            end
            process_all(node.to_a.reject { |n| t = n.try(:type); t == :on_fail || t == :on_pass })
            on_pass = node.find(:on_pass)
            on_fail = node.find(:on_fail)

            if on_fail && on_fail.find(:continue) && tester.force_pass_on_continue
              if test_method.respond_to?(:force_pass)
                test_method.force_pass = 1
              else
                Origen.log.error 'Force pass on continue has been enabled, but the test method does not have a force_pass attribute!'
                Origen.log.error "  #{node.source}"
                exit 1
              end
              @open_test_methods << test_method
            else
              if test_method.respond_to?(:force_pass)
                test_method.force_pass = 0
              end
              @open_test_methods << nil
            end

            if smt8?
              line "if (#{name}.pass) {"
            else
              line 'then'
              line '{'
            end
            @indent += 1
            pass_branch do
              process_all(on_pass) if on_pass
              stack[:on_pass].each { |n| process_all(n) }
            end
            @indent -= 1
            if smt8?
              line '} else {'
            else
              line '}'
              line 'else'
              line '{'
            end
            @indent += 1
            fail_branch do
              process_all(on_fail) if on_fail
              stack[:on_fail].each { |n| process_all(n) }
            end
            @indent -= 1
            line '}'

            @open_test_methods.pop
          else
            if smt8?
              line "#{name}.execute();"
            else
              line "run(#{name});"
            end
          end
        end

        def on_render(node)
          node.to_a[0].split("\n").each do |l|
            line(l)
          end
        end

        def on_if_job(node)
          jobs, *nodes = *node
          jobs = clean_job(jobs)
          state = node.type == :if_job
          if smt8?
            if jobs.size == 1
              condition = jobs.first
            else
              condition = jobs.map { |j| "(#{j})" }.join(' || ')
            end
            line "if (#{condition}) {"
          else
            condition = jobs.join(' or ')
            line "if #{condition} then"
            line '{'
          end
          @indent += 1
          process_all(node) if state
          @indent -= 1
          if smt8?
            line '} else {'
          else
            line '}'
            line 'else'
            line '{'
          end
          @indent += 1
          process_all(node) unless state
          @indent -= 1
          line '}'
        end
        alias_method :on_unless_job, :on_if_job

        def on_condition_flag(node, state)
          flag, *nodes = *node
          else_node = node.find(:else)
          if smt8?
            if flag.is_a?(Array)
              condition = flag.map { |f| "(#{generate_flag_name(f)} == 1)" }.join(' || ')
            else
              condition = "#{generate_flag_name(flag)} == 1"
            end
            line "if (#{condition}) {"
          else
            if flag.is_a?(Array)
              condition = flag.map { |f| "@#{generate_flag_name(f)} == 1" }.join(' or ')
            else
              condition = "@#{generate_flag_name(flag)} == 1"
            end
            line "if #{condition} then"
            line '{'
          end
          @indent += 1
          if state
            process_all(node.children - [else_node])
          else
            process(else_node) if else_node
          end
          @indent -= 1
          if smt8?
            line '} else {'
          else
            line '}'
            line 'else'
            line '{'
          end
          @indent += 1
          if state
            process(else_node) if else_node
          else
            process_all(node.children - [else_node])
          end
          @indent -= 1
          line '}'
        end

        def on_if_enabled(node)
          flag, *nodes = *node
          state = node.type == :if_enabled
          on_condition_flag(node, state)
        end
        alias_method :on_unless_enabled, :on_if_enabled

        def on_if_flag(node)
          flag, *nodes = *node
          state = node.type == :if_flag
          on_condition_flag(node, state)
        end
        alias_method :on_unless_flag, :on_if_flag

        def on_enable(node)
          flag = node.value.upcase
          if smt8?
            line "#{flag} = 1;"
          else
            line "@#{flag} = 1;"
          end
        end

        def on_disable(node)
          flag = node.value.upcase
          if smt8?
            line "#{flag} = 0;"
          else
            line "@#{flag} = 0;"
          end
        end

        def on_set_flag(node)
          flag = generate_flag_name(node.value)
          if @open_test_methods.last
            if pass_branch?
              if @open_test_methods.last.respond_to?(:on_pass_flag)
                if @open_test_methods.last.on_pass_flag == ''
                  @open_test_methods.last.on_pass_flag = flag
                else
                  Origen.log.error "The test method cannot set #{flag} on passing, because it already sets: #{@open_test_methods.last.on_pass_flag}"
                  Origen.log.error "  #{node.source}"
                  exit 1
                end
              else
                Origen.log.error 'Force pass on continue has been requested, but the test method does not have an :on_pass_flag attribute:'
                Origen.log.error "  #{node.source}"
                exit 1
              end
            else
              if @open_test_methods.last.respond_to?(:on_fail_flag)
                if @open_test_methods.last.on_fail_flag == ''
                  @open_test_methods.last.on_fail_flag = flag
                else
                  Origen.log.error "The test method cannot set #{flag} on failing, because it already sets: #{@open_test_methods.last.on_fail_flag}"
                  Origen.log.error "  #{node.source}"
                  exit 1
                end
              else
                Origen.log.error 'Force pass on continue has been requested, but the test method does not have an :on_fail_flag attribute:'
                Origen.log.error "  #{node.source}"
                exit 1
              end
            end
          else
            if smt8?
              line "#{flag} = 1;"
            else
              line "@#{flag} = 1;"
            end
          end
        end

        def on_group(node)
          on_fail = node.children.find { |n| n.try(:type) == :on_fail }
          on_pass = node.children.find { |n| n.try(:type) == :on_pass }
          group_name = unique_group_name(node.find(:name).value)
          if smt8?
            line '// *******************************************************'
            line "// GROUP - #{group_name}"
            line '// *******************************************************'
          else
            line '{'
          end
          @indent += 1
          stack[:on_fail] << on_fail if on_fail
          stack[:on_pass] << on_pass if on_pass
          process_all(node.children - [on_fail, on_pass])
          stack[:on_fail].pop if on_fail
          stack[:on_pass].pop if on_pass
          @indent -= 1
          if smt8?
            line '// *******************************************************'
            line "// /GROUP - #{group_name}"
            line '// *******************************************************'
          else
            line "}, open,\"#{group_name}\", \"\""
          end
        end

        def on_set_result(node)
          bin = node.find(:bin).try(:value)
          desc = node.find(:bin).to_a[1]
          sbin = node.find(:softbin).try(:value)
          sdesc = node.find(:softbin).to_a[1] || 'fail'
          if bin && desc
            hardware_bin_descriptions[bin] ||= desc
          end

          if smt8?
            line "addBin(#{sbin || bin});"
          else
            if node.to_a[0] == 'pass'
              line "stop_bin \"#{sbin}\", \"\", , good, noreprobe, green, #{bin}, over_on;"
            else
              if tester.create_limits_file
                line 'multi_bin;'
              else
                line "stop_bin \"#{sbin}\", \"#{sdesc}\", , bad, noreprobe, red, #{bin}, over_on;"
              end
            end
          end
        end

        def on_log(node)
          if smt8?
            line "println(\"#{node.to_a[0]}\");"
          else
            line "print_dl(\"#{node.to_a[0]}\");"
          end
        end

        def unique_group_name(name)
          @group_names ||= {}
          if @group_names[name]
            @group_names[name] += 1
            "#{name}_#{@group_names[name]}"
          else
            @group_names[name] = 1
            name
          end
        end

        def clean_job(job)
          var = smt8? ? 'JOB' : '@JOB'
          [job].flatten.map { |j| "#{var} == \"#{j.to_s.upcase}\"" }
        end

        private

        def pass_branch
          open_branch_types << :pass
          yield
          open_branch_types.pop
        end

        def fail_branch
          open_branch_types << :fail
          yield
          open_branch_types.pop
        end

        def pass_branch?
          open_branch_types.last == :pass
        end

        def fail_branch?
          open_branch_types.last == :fail
        end

        def open_branch_types
          @open_branch_types ||= []
        end

        def generate_flag_name(flag)
          self.class.generate_flag_name(flag)
        end
      end
    end
  end
end
