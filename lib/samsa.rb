require "samsa/version"
require "samsa/mapper"

module Samsa
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      class_attribute :_definitions
    end
  end

  module ClassMethods
    def transforms(&definitions)
      self._definitions = definitions
    end

    def transform(input)
      t = Transforms.new
      t.instance_eval(&_definitions)
      t.run_lazy(input)

      Samsa::Mapper.new(t.transforms, input)
        .normalize
        .with_indifferent_access
    end
  end

  class Transforms
    def initialize
      @transforms = []
      @lazy_transforms = []
    end

    attr_reader :transforms

    def run_lazy(input)
      @lazy_transforms.each { |t| t.call(input) }
    end

    def map(from:, to:, default: nil)
      transform = { type: :map, from: extract_path(from), to: extract_path(to) }
      transform[:default] = default unless default.nil?
      @transforms << transform
    end

    def set(value, to:)
      @transforms << { type: :set, value: value, to: extract_path(to) }
    end

    def conditional(inputs)
      @lazy_transforms << lambda do |input|
        yield(*Array[*inputs].map { |i| input.dig(*extract_path(i)) })
      end
    end

    def extract_path(path_str)
      path = path_str.split(".").map { |s| s.to_i.to_s == s ? s.to_i : s.to_sym }
      Array[*path]
    end
  end
end
