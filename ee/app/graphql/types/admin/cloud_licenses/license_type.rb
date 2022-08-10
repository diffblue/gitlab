# frozen_string_literal: true

module Types
  module Admin
    module CloudLicenses
      module LicenseType
        extend ActiveSupport::Concern

        included do
          field :id, GraphQL::Types::ID,
            null: false,
            description: 'ID of the license extracted from the license data.'

          field :type, GraphQL::Types::String,
            null: false, method: :license_type, description: 'Type of the license.'

          field :plan, GraphQL::Types::String,
            null: false, description: 'Name of the subscription plan.'

          field :name, GraphQL::Types::String,
            null: true, method: :licensee_name, description: 'Name of the licensee.'

          field :email, GraphQL::Types::String,
            null: true, method: :licensee_email, description: 'Email of the licensee.'

          field :company, GraphQL::Types::String,
            null: true, method: :licensee_company, description: 'Company of the licensee.'

          field :starts_at, ::Types::DateType,
            null: true, description: 'Date when the license started.'

          field :created_at, ::Types::DateType,
            null: true, description: 'Date when the license was added.'

          field :expires_at, ::Types::DateType,
            null: true, description: 'Date when the license expires.'

          field :block_changes_at, ::Types::DateType,
            null: true,
            description: 'Date, including grace period, when licensed features will be blocked.'

          field :activated_at, ::Types::DateType,
            null: true, description: 'Date when the license was activated.'

          field :users_in_license_count, GraphQL::Types::Int,
            null: true, method: :restricted_user_count,
            description: 'Number of paid users in the license.'

          def id
            ::Gitlab::GlobalId.build(object, model_name: object.class.to_s, id: object.license_id).to_s
          end
        end
      end
    end
  end
end
