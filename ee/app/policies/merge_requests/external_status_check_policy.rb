# frozen_string_literal: true

module MergeRequests
  class ExternalStatusCheckPolicy < BasePolicy
    delegate { @subject.project }

    rule { can?(:admin_project) }.policy do
      enable :read_external_status_check
    end
  end
end
