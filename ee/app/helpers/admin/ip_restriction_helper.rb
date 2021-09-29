# frozen_string_literal: true

module Admin
  module IpRestrictionHelper
    def ip_restriction_feature_available?(group)
      group.licensed_feature_available?(:group_ip_restriction) || License.features_with_usage_ping.include?(:group_ip_restriction)
    end
  end
end
