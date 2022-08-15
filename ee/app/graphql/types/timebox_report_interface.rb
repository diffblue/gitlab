# frozen_string_literal: true

module Types
  module TimeboxReportInterface
    include BaseInterface

    field :report, Types::TimeboxReportType,
      null: true, resolver: ::Resolvers::TimeboxReportResolver, complexity: 175,
      description: 'Historically accurate report about the timebox.'
  end
end
