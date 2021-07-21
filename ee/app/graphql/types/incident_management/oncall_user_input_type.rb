# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallUserInputType < BaseInputObject
      graphql_name 'OncallUserInputType'
      description 'The rotation user and color palette'

      argument :username, GraphQL::Types::String,
                required: true,
                description: 'The username of the user to participate in the on-call rotation, such as `user_one`.'

      argument :color_palette, ::Types::DataVisualizationPalette::ColorEnum,
                required: false,
                description: 'A value of DataVisualizationColorEnum. The color from the palette to assign to the on-call user.'

      argument :color_weight, ::Types::DataVisualizationPalette::WeightEnum,
                required: false,
                description: 'A value of DataVisualizationWeightEnum. The color weight to assign to for the on-call user. Note: To view on-call schedules in GitLab, do not provide a value below 500. A value between 500 and 950 ensures sufficient contrast.'
    end
  end
end
