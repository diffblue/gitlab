# frozen_string_literal: true

# VulnerabilitiesBaseResolver is an abstract class that is inherited by
# vulnerability related resolvers. It contains the somewhat obtuse logic related
# to finding the object to get vulnerabilities from so that developers writing
# new resolvers don't have to repeat it.

# rubocop: disable Graphql/ResolverType
module Resolvers
  class VulnerabilitiesBaseResolver < BaseResolver
    include Gitlab::Utils::StrongMemoize

    protected

    # `vulnerable` will be a Project, Group, or InstanceSecurityDashboard
    def vulnerable
      # A project or group could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project or group to query for vulnerabilities, so
      # make sure it's loaded and not `nil` before continuing.

      strong_memoize(:vulnerable) do
        if resolve_vulnerabilities_for_instance_security_dashboard?
          ::InstanceSecurityDashboard.new(current_user)
        elsif object.respond_to?(:sync)
          object.sync
        else
          object
        end
      end
    end

    def resolve_vulnerabilities_for_instance_security_dashboard?
      # object will be nil when we're fetching vulnerabilities from QueryType,
      # which is the source of vulnerability data for the instance security
      # dashboard
      object.nil? && current_user.present?
    end

    def resolve_gids(gids, gid_class)
      gids.map(&:model_id)
    end
  end
end
