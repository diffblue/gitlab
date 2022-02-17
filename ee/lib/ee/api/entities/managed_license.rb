# frozen_string_literal: true

module EE
  module API
    module Entities
      class ManagedLicense < Grape::Entity
        expose :id, :name
        expose :legacy_approval_status, as: :approval_status
      end
    end
  end
end
