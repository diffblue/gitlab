# frozen_string_literal: true

module Admin
  module IpRestrictionHelper
    def ip_restriction_feature_available?(group)
      group.licensed_feature_available?(:group_ip_restriction) || GitlabSubscriptions::Features.usage_ping_feature?(:group_ip_restriction)
    end
  end
end
