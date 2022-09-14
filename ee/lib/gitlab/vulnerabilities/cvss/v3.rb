# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    module Cvss
      class V3
        include Gitlab::Utils::StrongMemoize

        PARAMETER_SEPARATOR = '/'
        KEY_VALUE_SEPARATOR = ':'
        VERSION_KEY = 'CVSS'
        SUPPORTED_VERSIONS = %w[3.1].freeze
        BASE_METRICS = [
          {
            key: 'AV',
            valid_values: %w[N A L P]
          },
          {
            key: 'AC',
            valid_values: %w[L H]
          },
          {
            key: 'PR',
            valid_values: %w[N L H]
          },
          {
            key: 'UI',
            valid_values: %w[N R]
          },
          {
            key: 'S',
            valid_values: %w[U C]
          },
          {
            key: 'C',
            valid_values: %w[N L H]
          },
          {
            key: 'I',
            valid_values: %w[N L H]
          },
          {
            key: 'A',
            valid_values: %w[N L H]
          }
        ].freeze

        attr_reader :vector, :errors

        def initialize(vector)
          @vector = vector
          @parameters = ParameterSet.new(BASE_METRICS)
          @errors = []
        end

        def valid?
          strong_memoize(:valid) do
            parse!

            validate_base_metrics_present

            errors.empty?
          end
        end

        def invalid?
          !valid?
        end

        alias_method :validate, :valid?

        private

        attr_reader :parameters

        def parse!
          version, _, tail = vector.partition(PARAMETER_SEPARATOR)
          validate_version(version)
          pairs = parse_tail(tail)
          pairs.each do |key, value|
            err = parameters.set(key, value)

            errors.push(err) if err
          end
        end

        def parse_pair(token)
          key, _, value = token.partition(KEY_VALUE_SEPARATOR)

          [key, value]
        end

        def parse_tail(vector_tail)
          vector_tail.split(PARAMETER_SEPARATOR).each_with_object({}) do |token, memo|
            key, value = parse_pair(token)

            # Per the spec: A vector string must not include the same metric more than once.
            errors.push("vector contains multiple values for parameter `#{key}`") if memo.include?(key)

            memo[key] = value
          end
        end

        def validate_version(token)
          key, value = parse_pair(token)

          return errors.push("first parameter must be `#{VERSION_KEY}`") unless key == VERSION_KEY
          return if SUPPORTED_VERSIONS.include?(value)

          errors.push("version `#{value}` is not supported. Supported versions are: #{SUPPORTED_VERSIONS.join(', ')}")
        end

        def validate_base_metrics_present
          BASE_METRICS.each do |metric|
            key = metric[:key]

            next if parameters.present?(key)

            errors.push("`#{key}` parameter is required")
          end
        end
      end
    end
  end
end
