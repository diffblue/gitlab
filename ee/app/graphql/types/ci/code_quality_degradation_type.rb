# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class CodeQualityDegradationType < BaseObject
      graphql_name 'CodeQualityDegradation'
      description 'Represents a code quality degradation on the pipeline.'

      connection_type_class Types::CountableConnectionType

      alias_method :degradation, :object

      field :description, GraphQL::Types::String,
        null: false,
        description: "Description of the code quality degradation."

      field :fingerprint, GraphQL::Types::String,
        null: false,
        description: 'Unique fingerprint to identify the code quality degradation. For example, an MD5 hash.'

      field :severity, Types::Ci::CodeQualityDegradationSeverityEnum,
        null: false,
        description: "Status of the degradation (#{::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.keys.map(&:upcase).join(', ')})."

      field :path, GraphQL::Types::String,
        null: false,
        description: 'Relative path to the file containing the code quality degradation.'

      field :line, GraphQL::Types::Int,
        null: false,
        description: 'Line on which the code quality degradation occurred.'

      field :web_url, GraphQL::Types::String,
        null: true,
        description: 'URL to the file along with line number.'

      field :engine_name, GraphQL::Types::String,
        null: false,
        description: 'Code Quality plugin that reported the finding.'

      def path
        degradation.dig(:location, :path)
      end

      def line
        degradation.dig(:location, :lines, :begin) || degradation.dig(:location, :positions, :begin, :line)
      end
    end
  end
end
