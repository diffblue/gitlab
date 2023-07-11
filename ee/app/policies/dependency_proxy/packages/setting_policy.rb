# frozen_string_literal: true

module DependencyProxy
  module Packages
    class SettingPolicy < BasePolicy
      include CrudPolicyHelpers

      delegate(:project) { @subject.project }

      overrides(:read_package)

      rule { project.packages_disabled }.policy do
        prevent(:read_package)
      end

      rule { can?(:reporter_access) }.policy do
        enable :read_package
      end

      rule { can?(:public_access) }.policy do
        enable :read_package
      end

      rule { project.read_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { project.write_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { project.ip_enforcement_prevents_access & ~admin & ~auditor }.policy do
        prevent(*create_read_update_admin_destroy(:package))
      end
    end
  end
end
