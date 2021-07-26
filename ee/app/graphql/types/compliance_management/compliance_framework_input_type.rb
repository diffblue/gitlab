# frozen_string_literal: true

module Types
  module ComplianceManagement
    class ComplianceFrameworkInputType < BaseInputObject
      graphql_name 'ComplianceFrameworkInput'

      argument :name,
               GraphQL::Types::String,
               required: false,
               description: 'New name for the compliance framework.'

      argument :description,
               GraphQL::Types::String,
               required: false,
               description: 'New description for the compliance framework.'

      argument :color,
               GraphQL::Types::String,
               required: false,
               description: 'New color representation of the compliance framework in hex format. e.g. #FCA121.'

      argument :pipeline_configuration_full_path,
               GraphQL::Types::String,
               required: false,
               description: 'Full path of the compliance pipeline configuration stored in a project repository, such as `.gitlab/.compliance-gitlab-ci.yml@compliance/hipaa` **(ULTIMATE)**.'
    end
  end
end
