module OrigenTesters
  module Decompiler
    module BaseGrammar
      module VectorBased
        module Processors
          def self.select_processor(node, options = {})
            case node.type
              when :frontmatter
                OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Frontmatter
              when :pinlist
                OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Pinlist
              when :comment_block
                OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::CommentBlock
              when :vector
                OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Vector
              else
                Origen.app.fail! message: "Cannot match processor for node type: #{node.type}"
            end
          end

          class CommentBlock < Origen::AST::Processor::Base
            attr_reader :comments

            def run(node, options = {})
              @comments = []
              process(node)
              self
            end

            def on_comment(node)
              @comments << node.children.first
            end

            def execute?
              true
            end

            def execute!(context)
              comments.each do |c|
                cc(c)
              end
            end
          end

          class Frontmatter < Origen::AST::Processor::Base
            attr_reader :comments
            attr_reader :imports
            attr_reader :variable_assignments

            def run(node, options = {})
              @comments = []

              # Process the frontmatter
              process(node)

              if node.children.empty?
                @pattern_header = []
              else
                @pattern_header = node.children.first.type == :comment_block ? @comments.shift : []
              end
              self
            end

            def pattern_header
              @pattern_header
            end
            alias_method :header, :pattern_header
            alias_method :comment_header, :pattern_header

            def on_comment_block(node)
              @comments << node.children.select { |c| c.type == :comment }.map { |c| c.children.first }
            end

            def execute!(context)
              pattern_header.each do |c|
                cc(c)
              end

              comments.each do |c|
                cc(c)
              end
            end

            def execute?
              true
            end
          end

          # Special processor whose job is to only process the top-most child element.
          # @abstract This class is meant to be subclassed by the tester platform to
          #   further define what may appear in the vector body.
          class VectorBodyElement < Origen::AST::Processor::Base
            attr_reader :type

            def run(node, options = {})
              select_processor(node, options).new(node, options)
            end

            def execute?
              true
            end
          end

          class Vector < Origen::AST::Processor::Base
            def execute?
              true
            end

            def execute!(context)
              fail('Please override the #execute! method in the platform!')
            end
          end

          class Pinlist < Origen::AST::Processor::Base
            attr_reader :pins

            def run(node, options = {})
              @pins = []
              process(node)
              self
            end

            # Process the pin names.
            # @note Origen is used to seeing pin names as symbols, so return the names a symbols instead of as strings.
            def on_pin_name(node)
              @pins << node.children.first.to_sym
            end

            def execute?
              false
            end
          end
        end
      end
    end
  end
end
