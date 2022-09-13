# frozen_string_literal: true

module Gitlab
  module IpRestriction
    class Enforcer
      def initialize(group)
        @group = group
      end

      def logger
        @logger ||= Gitlab::AuthLogger.build
      end

      def allows_current_ip?
        return true unless group&.feature_available?(:group_ip_restriction) || ::GitlabSubscriptions::Features.usage_ping_feature?(:group_ip_restriction)

        current_ip_address = Gitlab::IpAddressState.current

        return true unless current_ip_address

        allows_address?(current_ip_address)
      end

      private

      attr_reader :group

      def allows_address?(address)
        root_ancestor_ip_restrictions = group.root_ancestor_ip_restrictions

        return true unless root_ancestor_ip_restrictions.present?

        allowed = root_ancestor_ip_restrictions.any? { |ip_restriction| ip_restriction.allows_address?(address) }

        # Check against configured internal ranges
        allowed ||= globally_configured_ip_ranges.match?(address)

        logger.info(
          message: 'Attempting to access IP restricted group',
          group_full_path: group.full_path,
          ip_address: address,
          allowed: allowed,
          globally_allowed: globally_configured_ip_ranges.present?
        )

        allowed
      end

      def globally_configured_ip_ranges
        ::Gitlab::CIDR.new(Gitlab::CurrentSettings.globally_allowed_ips)
      end
    end
  end
end
