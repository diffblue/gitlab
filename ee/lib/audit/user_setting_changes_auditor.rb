# frozen_string_literal: true

module Audit
  class UserSettingChangesAuditor < BaseChangesAuditor
    def initialize(current_user)
      super(current_user, current_user)
    end

    def execute
      return if model.blank?

      audit_changes(
        :private_profile,
        as: 'user_profile_visiblity',
        entity: @current_user,
        model: model,
        event_type: 'user_profile_visiblity_updated'
      )
    end

    private

    def attributes_from_auditable_model(column)
      {
        from: model.previous_changes[column].first,
        to: model.previous_changes[column].last
      }
    end
  end
end
