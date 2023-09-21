# frozen_string_literal: true

module MemberRoles
  class BaseService < ::BaseService
    include Gitlab::Allowable

    def initialize(group, current_user, params)
      @group = group
      @current_user = current_user
      @params = params
    end

    private

    attr_accessor :group, :current_user, :params

    def authorized_error
      ::ServiceResponse.error(message: _('Operation not allowed'), reason: :unauthorized)
    end

    def allowed?
      group.custom_roles_enabled? && can?(current_user, :admin_group, group)
    end
  end
end
