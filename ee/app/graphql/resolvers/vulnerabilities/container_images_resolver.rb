# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class ContainerImagesResolver < VulnerabilitiesBaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::Vulnerabilities::ContainerImageType, null: true

      authorize :read_security_resource
      authorizes_object!

      def resolve(**args)
        return Vulerabilities::Read.none unless vulnerable

        authorize!
        vulnerable.vulnerability_reads.container_images
      end

      def authorize!
        Ability.allowed?(context[:current_user], :read_security_resource, vulnerable) ||
          raise_resource_not_available_error!
      end
    end
  end
end
