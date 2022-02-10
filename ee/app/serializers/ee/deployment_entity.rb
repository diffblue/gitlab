# frozen_string_literal: true

module EE
  module DeploymentEntity
    extend ActiveSupport::Concern

    prepended do
      expose :pending_approval_count
    end
  end
end
