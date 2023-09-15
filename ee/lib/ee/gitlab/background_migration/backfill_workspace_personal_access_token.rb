# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # This class is responsible for backfilling personal access tokens for workspaces without one.
      module BackfillWorkspacePersonalAccessToken
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          operation_name :backfill
          scope_to ->(relation) {
            relation.where(personal_access_token_id: nil)
          }
          feature_category :remote_development
        end

        class PersonalAccessToken < ::ApplicationRecord
          self.table_name = 'personal_access_tokens'
        end

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            sub_batch.each do |workspace|
              expires_at = calculate_expires_at(workspace.created_at, workspace.max_hours_before_termination)
              revoked = calculate_revoked(expires_at, workspace.desired_state)
              ApplicationRecord.transaction do
                pat = PersonalAccessToken.create!(
                  name: workspace.name,
                  user_id: workspace.user_id,
                  impersonation: false,
                  scopes: [:write_repository],
                  expires_at: expires_at,
                  revoked: revoked
                )

                workspace.update! personal_access_token_id: pat.id
              end
            end
          end
        end

        def calculate_expires_at(created_at, max_hours_before_termination)
          (created_at + max_hours_before_termination.hour).to_date.next_day
        end

        def calculate_revoked(expires_at, desired_state)
          expires_at <= Date.today || desired_state == ::RemoteDevelopment::Workspaces::States::TERMINATED
        end
      end
    end
  end
end
