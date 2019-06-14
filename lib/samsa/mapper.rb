require "ramda"

module Samsa
  class Mapper
    def initialize(template, input)
      @template = template
      @input = input
    end

    def normalize
      @template.inject({}) do |memo, transform|
        Transform.build(transform).apply(@input, memo)
      end
    end

    class Transform
      def initialize(transform)
        @transform = transform
        @r = Ramda
      end

      def self.build(transform)
        case transform[:type]
        when :set then SetTransform.new(transform)
        when :map then MapTransform.new(transform)
        else raise InvalidTransformType
        end
      end

      protected

      attr_reader :r

      class SetTransform < Transform
        def apply(_input, output)
          to_lens = r.lens_path(@transform[:to])
          r.set(to_lens, @transform[:value], output)
        end
      end

      class MapTransform < Transform
        def apply(input, output)
          value = new_value(input).nil? ? @transform[:default] : new_value(input)
          return output if value.nil?

          to_lens = r.lens_path(@transform[:to])
          r.set(to_lens, value, output)
        end

        private

        def new_value(input)
          return @transform[:default] if @transform[:from].nil?
          from_lens = r.lens_path(@transform[:from])
          r.view(from_lens, input)
        end
      end
    end

    class InvalidTransformType < StandardError; end
  end
end
