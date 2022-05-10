# frozen_string_literal: true

module Resolvers
  module ComplianceManagement
    class FrameworkResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_compliance_framework

      type ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type, null: true

      argument :id, ::Types::GlobalIDType[::ComplianceManagement::Framework],
               description: 'Global ID of a specific compliance framework to return.',
               required: false

      def resolve(id: nil)
        BatchLoader::GraphQL
          .for([object.id, id&.model_id])
          .batch(default_value: []) do |keys, loader|
          namespace_ids = keys.map(&:first).uniq
          by_namespace_id = keys.group_by(&:first).transform_values { |k| k.map(&:second) }

          evaluate(namespace_ids, by_namespace_id, loader)
        end
      end

      private

      def evaluate(namespace_ids, by_namespace_id, loader)
        frameworks(namespace_ids).group_by(&:namespace_id).each do |ns_id, group|
          by_namespace_id[ns_id].each do |fw_id|
            group.each do |fw|
              next unless fw_id.nil? || fw_id.to_i == fw.id

              loader.call([ns_id, fw_id]) { |array| array << fw }
            end
          end
        end
      end

      def frameworks(namespace_ids)
        ::ComplianceManagement::Framework.with_namespaces(namespace_ids)
      end
    end
  end
end
