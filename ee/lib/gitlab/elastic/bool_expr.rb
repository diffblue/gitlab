# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Gitlab
  module Elastic
    BoolExpr = Struct.new(:must, :must_not, :should, :filter) do # rubocop:disable Lint/StructNewOverride
      def initialize
        super
        reset!
      end

      def reset!
        self.must     = []
        self.must_not = []
        self.should   = []
        self.filter   = []
      end

      def to_h
        super.reject { |_, value| value.blank? }
      end

      def eql?(other)
        to_h.eql?(other.to_h)
      end
    end
  end
end

# rubocop:enable Naming/FileName
