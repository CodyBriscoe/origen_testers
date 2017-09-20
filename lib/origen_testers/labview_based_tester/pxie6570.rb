module OrigenTesters
  module LabVIEWBasedTester
    class Pxie6570
      include OrigenTesters::VectorBasedTester

      def initialize
        @pat_extension = 'digipatsrc'
        @capture_started = {}
        @source_started = {}
        @global_label_export = []
      end

      # Internal method called by Origen
      def pattern_header(options = {})
        microcode 'file_format_version 1.0;'
        @global_label_export.each { |label| microcode "export #{label};" }
        called_timesets.each do |timeset|
          microcode "timeset #{timeset.name};"
        end
        pin_list = ordered_pins.map(&:name).join(',')
        microcode "pattern #{options[:pattern]} (#{pin_list})"
        microcode '{'
      end

      # Internal method called by Origen
      def pattern_footer(options = {})
        # add capture/source stop to the end of the pattern
        cycle microcode: 'capture_stop' if @capture_started[:default]
        cycle microcode: 'halt'
        microcode '}'
      end

      # Internal method called by Origen
      def format_vector(vec)
        timeset = vec.timeset ? " #{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals} ;" : ''
        microcode = vec.microcode ? vec.microcode : ''
        if vec.repeat > 1
          microcode = "repeat (#{vec.repeat})"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end
        if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
          comment = " // #{vec.number}:#{vec.cycle} #{vec.inline_comment}"
        else
          comment = vec.inline_comment.empty? ? '' : " // #{vec.inline_comment}"
        end

        "#{microcode.ljust(65)}#{timeset.ljust(31)}#{pin_vals}#{comment}"
      end

      def call_subroutine(name, options = {})
        # not yet implemented
      end

      # store/capture the state of the provided pins
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0 }.merge(options)
        pins = pins.flatten.compact

        fail 'For the PXIE6570 you must supply the pins to store/capture' if pins.empty?
        unless @capture_started[:default]
          # add the capture start opcode to the top of the pattern
          stage.insert_from_start 'capture_start(default_capture_waveform)', 0
          @capture_started[:default] = true
        end

        pins.each do |pin|
          pin.restore_state do
            pin.capture
            update_vector_pin_val pin, offset: options[:offset]
            last_vector(options[:offset]).dont_compress = true
          end
        end

        update_vector microcode: 'capture', offset: options[:offset]
      end
      alias_method :to_hram, :store
      alias_method :capture, :store

      def cycle(options = {})
        # handle overlay if requested
        overlay_options = options.key?(:overlay) ? options.delete(:overlay) : {}
        cur_pin_state = nil
        if overlay_options.key?(:pins)
          overlay_options = { change_data: true }.merge(overlay_options)
          unless @source_started[:default]
            # add the source start opcode to the top of the pattern
            i = 0
            i += 1 until stage.bank[i].is_a?(OrigenTesters::Vector)
            first_vector = stage.bank[i]

            if first_vector.has_microcode? || first_vector.repeat > 1
              v = OrigenTesters::Vector.new
              v.pin_vals = first_vector.pin_vals
              v.timeset = first_vector.timeset
              v.inline_comment = 'added for source start opcode'
              v.dont_compress = true
              v.microcode = 'source_start(default_source_waveform)'
              stage.insert_from_start v, i

              # decrement repeat count of previous first vector if > 1
              first_vector.repeat -= 1 if first_vector.repeat > 1
            else
              first_vector.microcode = 'source_start(default_source_waveform)'
            end if

            @source_started[:default] = true
          end

          # ensure no unwanted repeats on the source line
          options[:dont_compress] = true

          if overlay_options[:change_data]
            if options[:microcode].nil?
              options[:microcode] = 'source'
            else
              options[:microcode] = options[:microcode] + ', source'
            end
            options[:microcode] = options[:microcode] + ", repeat (#{options[:repeat]})" unless options[:repeat].nil?
            options.delete(:repeat)
          end

          # set pins to drive data
          cur_pin_state = overlay_options[:pins].state.to_sym
          overlay_options[:pins].drive_mem
        end
        super(options)
        overlay_options[:pins].state = cur_pin_state if overlay_options.key?(:pins)
      end

      # store/capture the provided pins on the next cycle
      def store_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0 }.merge(options)
        pins = pins.flatten.compact

        fail 'For the PXIE6570 you must supply the pins to store/capture' if pins.empty?
        unless @capture_started[:default]
          # add the capture start opcode to the top of the pattern
          stage.insert_from_start 'capture_start(default_capture_waveform)', 0
          @capture_started[:default] = true
        end

        pins.each { |pin| pin.save; pin.capture }
        preset_next_vector(microcode: 'capture') do
          pins.each(&:restore)
        end
      end
      alias_method :store!, :store_next_cycle

      # add a label to the output pattern
      def label(name, global = false)
        microcode name + ':'
        @global_label_export << name if global
      end

      # change the capture state character
      def format_pin_state(pin)
        response = super(pin)
        response.sub('C', 'V')
      end
    end
  end
  Pxie6570 = LabVIEWBasedTester::Pxie6570
end
