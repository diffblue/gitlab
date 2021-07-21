# frozen_string_literal: true

module EE
  module Types
    module NamespaceType
      extend ActiveSupport::Concern

      prepended do
        field :additional_purchased_storage_size,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Additional storage purchased for the root namespace in bytes.'

        field :total_repository_size_excess,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Total excess repository size of all projects in the root namespace in bytes.'

        field :total_repository_size,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Total repository size of all projects in the root namespace in bytes.'

        field :contains_locked_projects,
              GraphQL::Types::Boolean,
              null: false,
              description: 'Includes at least one project where the repository size exceeds the limit.',
              method: :contains_locked_projects?

        field :repository_size_excess_project_count,
              GraphQL::Types::Int,
              null: false,
              description: 'Number of projects in the root namespace where the repository size exceeds the limit.'

        field :actual_repository_size_limit,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Size limit for repositories in the namespace in bytes.',
              method: :actual_size_limit

        field :storage_size_limit,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Total storage limit of the root namespace in bytes.'

        field :is_temporary_storage_increase_enabled,
              GraphQL::Types::Boolean,
              null: false,
              description: 'Status of the temporary storage increase.',
              method: :temporary_storage_increase_enabled?

        field :temporary_storage_increase_ends_on,
              ::Types::TimeType,
              null: true,
              description: 'Date until the temporary storage increase is active.'

        field :compliance_frameworks,
              ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
              null: true,
              description: 'Compliance frameworks available to projects in this namespace.',
              resolver: ::Resolvers::ComplianceManagement::FrameworkResolver

        def additional_purchased_storage_size
          object.additional_purchased_storage_size.megabytes
        end

        def storage_size_limit
          object.root_storage_size.limit
        end
      end
    end
  end
end
