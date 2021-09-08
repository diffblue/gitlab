# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallUserInputType < BaseInputObject
      graphql_name 'OncallUserInputType'
      description 'The rotation user and color palette'

      argument :username, GraphQL::Types::String,
                required: true,
                description: 'Username of the user to participate in the on-call rotation. For example, `"user_one"`.'

      argument :color_palette, ::Types::DataVisualizationPalette::ColorEnum,
                required: false,
                description: 'Value of DataVisualizationColorEnum. The color from the palette to assign to the on-call user.'

      argument :color_weight, ::Types::DataVisualizationPalette::WeightEnum,
                required: false,
                description: 'Color weight to assign to for the on-call user. To view on-call schedules in GitLab, do not provide a value below 500. A value between 500 and 950 ensures sufficient contrast.'
    end
  end
end
