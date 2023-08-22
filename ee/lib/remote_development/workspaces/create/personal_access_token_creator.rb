# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class PersonalAccessTokenCreator
        include Messages

        # @param [Hash] value
        # @return [Result]
        def self.create(value)
          value => {
            current_user: User => user,
            workspace_name: String => workspace_name,
            params: Hash => params
          }
          params => {
            max_hours_before_termination: Integer => max_hours_before_termination,
          }

          # TODO: Use PAT service injection - https://gitlab.com/gitlab-org/gitlab/-/issues/423415
          personal_access_token = user.personal_access_tokens.build(
            name: workspace_name,
            impersonation: false,
            scopes: [:write_repository],
            # Since expires_at is a date, we need to set it to the round it off to the next day.
            # e.g. If the max_hours_before_termination of the workspace is 1 hour
            # and the workspace is created at 2023-08-20 05:30:00,
            # then the expires_at of the PAT would be 2023-08-21.
            expires_at: max_hours_before_termination.hours.from_now.to_date.next_day
          )
          personal_access_token.save

          if personal_access_token.errors.present?
            return Result.err(
              PersonalAccessTokenModelCreateFailed.new({ errors: personal_access_token.errors })
            )
          end

          Result.ok(
            value.merge({
              personal_access_token: personal_access_token
            })
          )
        end
      end
    end
  end
end
