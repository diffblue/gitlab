# frozen_string_literal: true

module Gitlab
  module AlertManagement
    class AlertPayloadFieldExtractor
      def initialize(project)
        @project = project
      end

      def extract(payload)
        deep_traverse(payload.deep_stringify_keys)
          .map { |path, value| field(path, value) }
          .compact
      end

      private

      attr_reader :project

      def field(path, value)
        type = type_of(value)
        return unless type

        ::AlertManagement::AlertPayloadField.new(
          project: project,
          path: path,
          label: label_for(path),
          type: type
        )
      end

      # Code duplication with Gitlab::InlineHash#merge_keys ahead!
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/299856
      #
      # Determines the keys and indicies needed to identify a value
      # in a hash with nested values.
      #
      # Example:
      # {
      #   apple: [:a, :b],
      #   pickle: {
      #     dill: true
      #   },
      #   pear: [{ bosc: 5, bartlett: [1, [2]] }]
      # }
      #
      # Becomes:
      # [
      #   [[:apple], [:a, :b]],
      #   [[:apple, 0], :a],
      #   [[:apple, 1], :b],
      #   [[:pickle, :dill], true],
      #   [[:pear, 0, :bosc], 5]
      #   [[:pear], [{:bosc=>5, :bartlett=>[1, [2]]}]],
      #   [[:pear, 0, :bartlett], [1, [2]]],
      #   [[:pear, 0, :bartlett, 0], 1],
      #   [[:pear, 0, :bartlett, 1], [2]],
      #   [[:pear, 0, :bartlett, 1, 0], 2],
      # ]
      #
      # @return Enumerator
      def deep_traverse(hash)
        return to_enum(__method__, hash) unless block_given?

        pairs = hash.map { |k, v| [[k], v] }

        until pairs.empty?
          key, value = pairs.shift

          case value
          when Hash
            value.each { |k, v| pairs.unshift [key + [k], v] }
          when Array
            yield key, value

            value.each.with_index do |element, index|
              pairs.unshift [key + [index], element]
            end
          else
            yield key, value
          end
        end
      end

      def type_of(value)
        case value
        when Array
          ::AlertManagement::AlertPayloadField::ARRAY_TYPE
        when /^\d{4}/ # assume it's a datetime
          ::AlertManagement::AlertPayloadField::DATETIME_TYPE
        when String
          ::AlertManagement::AlertPayloadField::STRING_TYPE
        end
      end

      # EX) ['first', 'second'] => 'first/second'
      # EX) ['first', 'second', 0, 1, 'third'] => 'first/second[0][1]/third'
      #
      # Assumes first element in path is a string (as we only
      # expect a Hash as payload input)
      def label_for(path)
        path.reduce do |label, element|
          next "#{label}[#{element}]" if element.is_a?(Integer)

          "#{label}/#{element}"
        end
      end
    end
  end
end
