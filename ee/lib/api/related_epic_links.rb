# frozen_string_literal: true

# These API endpoints are used to manage the relationship between one epic with other epic
# (similar to issue links).  Note that this relation is different from existing
# API::EpicLinks (which is used for parent-child epic hierarchy).

module API
  class RelatedEpicLinks < ::API::Base
    include PaginationParams

    feature_category :portfolio_management

    helpers do
      def authorize_related_epics_feature_flag!
        not_found! unless Feature.enabled?(:related_epics_widget, user_group, default_enabled: :yaml)
      end
    end

    helpers ::API::Helpers::EpicsHelpers

    before do
      authenticate_non_get!
      authorize_related_epics_feature_flag!
      authorize_related_epics_feature!
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
      requires :epic_iid, type: Integer, desc: 'The internal ID of a group epic'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get related epics' do
        success Entities::RelatedEpic
      end
      get ':id/epics/:epic_iid/related_epics' do
        authorize_can_read!

        preload_for_collection = [group: [:saml_provider, :route]]
        related_epics = epic.related_epics(current_user, preload: preload_for_collection) do |epics|
          epics.with_api_entity_associations
        end

        epics_metadata = Gitlab::IssuableMetadata.new(current_user, related_epics).data
        presenter_options = epic_options(entity: Entities::RelatedEpic, issuable_metadata: epics_metadata)

        present related_epics, presenter_options
      end
    end
  end
end
