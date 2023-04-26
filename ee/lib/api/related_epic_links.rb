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
      authorize_epics_feature!
    end

    params do
      requires :id,
        type: String,
        desc: 'ID or URL-encoded path of the group',
        documentation: { example: '1' }
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        optional :updated_before,
          type: DateTime,
          desc: 'Return related epic links updated before the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        optional :updated_after,
          type: DateTime,
          desc: 'Return related epic links updated after the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        optional :created_before,
          type: DateTime,
          desc: 'Return related epic links created before the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        optional :created_after,
          type: DateTime,
          desc: 'Return related epic links created after the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        use :pagination
      end
      desc 'Get related epics within the group and hierarchy' do
        success Entities::RelatedEpic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        is_array true
      end
      get ':id/related_epic_links' do
        accessible_epics = EpicsFinder.new(current_user, group_id: user_group.id).execute
        related_epic_links = Epic::RelatedEpicLink.for_source_or_target(accessible_epics)

        related_epic_links = related_epic_links.updated_before(params[:updated_before]) if params[:updated_before]
        related_epic_links = related_epic_links.updated_after(params[:updated_after]) if params[:updated_after]
        related_epic_links = related_epic_links.created_before(params[:created_before]) if params[:created_before]
        related_epic_links = related_epic_links.created_after(params[:created_after]) if params[:created_after]

        related_epic_links = paginate(related_epic_links).with_api_entity_associations

        # EpicLinks can link to other Epics the user has no access to.
        # For these epics we need to check permissions.
        related_epic_links = related_epic_links.select do |related_epic_link|
          related_epic_link.source.readable_by?(current_user) && related_epic_link.target.readable_by?(current_user)
        end

        source_and_target_epics = related_epic_links.reduce(Set.new) { |acc, link| acc << link.source << link.target }

        epics_metadata = Gitlab::IssuableMetadata.new(current_user, source_and_target_epics).data
        present related_epic_links, issuable_metadata: epics_metadata, with: Entities::RelatedEpicLink
      end

      desc 'Get related epics' do
        success Entities::RelatedEpic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        is_array true
      end

      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of a group epic', documentation: { example: 1 }
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
        target_epic = find_permissioned_epic!(
          declared_params[:target_epic_iid],
          group_id: declared_params[:target_group_id],
          permission: :admin_epic_relation
        )

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
