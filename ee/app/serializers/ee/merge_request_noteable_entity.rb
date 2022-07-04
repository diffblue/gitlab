# frozen_string_literal: true

module EE
  module MergeRequestNoteableEntity
    extend ActiveSupport::Concern

    prepended do
      expose :require_password_to_approve do |merge_request|
        merge_request.target_project.require_password_to_approve?
      end

      expose :current_user do
        expose :can_approve do |merge_request|
          merge_request.can_approve?(current_user)
        end
      end
    end
  end
end
