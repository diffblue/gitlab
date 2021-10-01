# frozen_string_literal: true

module Licenses
  class DestroyService < ::Licenses::BaseService
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      raise ActiveRecord::RecordNotFound unless license
      raise Gitlab::Access::AccessDeniedError unless can?(user, :destroy_licenses)

      license.destroy
    end
  end
end
