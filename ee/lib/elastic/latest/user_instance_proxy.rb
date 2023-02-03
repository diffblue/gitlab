# frozen_string_literal: true

module Elastic
  module Latest
    class UserInstanceProxy < ApplicationInstanceProxy
      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab/issues/349

        # NOTE: Remember to update ELASTICSEARCH_TRACKED_FIELDS in ee/app/models/ee/user.rb
        # for fields that need to be updated in Elasticsearch.
        data = {}

        [
          :id,
          :username,
          :email,
          :public_email,
          :name,
          :created_at,
          :updated_at,
          :admin,
          :state,
          :organization,
          :timezone,
          :external
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data['in_forbidden_state'] = in_forbidden_state?(target)
        data['status'] = target.status&.message
        data['status_emoji'] = target.status&.emoji
        data['busy'] = target.status&.busy? || false
        data['namespace_ancestry_ids'] = target.search_membership_ancestry

        # Schema version. The format is Date.today.strftime('%y_%m')
        # Please update if you're changing the schema of the document
        data['schema_version'] = 22_10

        data.merge(generic_attributes)
      end

      def generic_attributes
        { 'type' => es_type }
      end

      def es_parent
        nil
      end

      private

      def in_forbidden_state?(user)
        User::FORBIDDEN_SEARCH_STATES.any?(user.state)
      end
    end
  end
end
