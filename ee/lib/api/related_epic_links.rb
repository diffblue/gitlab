# frozen_string_literal: true

# These API endpoints are used to manage the relationship between one epic with other epic
# (similar to issue links).  Note that this relation is different from existing
# API::EpicLinks (which is used for parent-child epic hierarchy).

module API
  class RelatedEpicLinks < ::API::Base
    include PaginationParams

    feature_category :portfolio_management

    helpers do
      def find_permissioned_epic!(iid, group_id: nil, permission: :admin_epic_link_relation)
        group = group_id ? find_group!(group_id) : user_group
        epic = group.epics.find_by_iid!(iid)

        authorize!(permission, epic)

        epic
      end
    end

    helpers ::API::Helpers::EpicsHelpers

    before do
      authenticate_non_get!
      authorize_related_epics_feature!
    end

    params do
      requires :id,
        type: String,
        desc: 'ID or URL-encoded path of the group',
        documentation: { example: '1' }
      requires :epic_iid, type: Integer, desc: 'The internal ID of a group epic', documentation: { example: 1 }
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get related epics' do
        success Entities::RelatedEpic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        is_array true
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

      desc 'Relate epics' do
        success Entities::RelatedEpicLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable entity' }
        ]
      end
      params do
        requires :target_group_id,
          type: String,
          desc: 'ID or URL-encoded path of the target group',
          documentation: { example: '1' }
        requires :target_epic_iid,
          type: Integer,
          desc: "Internal ID of a target group's epic",
          documentation: { example: 1 }
        optional :link_type,
          type: String,
          values: ::Epic::RelatedEpicLink.link_types.keys,
          desc: 'The type of the relation',
          documentation: { example: 'relates_to' }
      end
      post ':id/epics/:epic_iid/related_epics' do
        source_epic = find_permissioned_epic!(params[:epic_iid])
        target_epic = find_permissioned_epic!(declared_params[:target_epic_iid],
                                              group_id: declared_params[:target_group_id],
                                              permission: :admin_epic_relation)

        create_params = { target_issuable: target_epic, link_type: declared_params[:link_type] }

        result = ::Epics::RelatedEpicLinks::CreateService
                   .new(source_epic, current_user, create_params)
                   .execute

        if result[:status] == :success
          # If status is success, there should be always a created link, so
          # we can rely on it.
          present result[:created_references].first, with: Entities::RelatedEpicLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Remove epics relation' do
        success Entities::RelatedEpicLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :related_epic_link_id,
          type: Integer,
          desc: 'Internal ID of a related epic link',
          documentation: { example: 1 }
      end
      delete ':id/epics/:epic_iid/related_epics/:related_epic_link_id' do
        epic = find_permissioned_epic!(params[:epic_iid])
        epic_link = ::Epic::RelatedEpicLink
          .for_source_or_target(epic)
          .find(declared_params[:related_epic_link_id])

        result = ::Epics::RelatedEpicLinks::DestroyService
          .new(epic_link, epic, current_user)
          .execute

        if result[:status] == :success
          present epic_link, with: Entities::RelatedEpicLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
