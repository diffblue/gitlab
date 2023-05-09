# frozen_string_literal: true

module API
  class EpicLinks < ::API::Base
    include ::Gitlab::Utils::StrongMemoize

    feature_category :portfolio_management
    urgency :low

    before do
      authenticate!
    end

    helpers ::API::Helpers::EpicsHelpers

    helpers do
      def child_epic
        strong_memoize(:child_epic) do
          find_epics(finder_params: { parent: epic }, children_only: true)
            .find_by_id(declared_params[:child_epic_id])
        end
      end

      def child_epics
        ::Epics::CrossHierarchyChildrenFinder.new(current_user, { parent: epic, sort: 'relative_position' })
          .execute(preload: true)
          .with_api_entity_associations
      end

      params :child_epic_id do
        # Unique ID should be used because epics from other groups can be assigned as child.
        requires :child_epic_id,
          type: Integer,
          desc: "The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups.",
          documentation: { example: 1 }
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group', documentation: { example: '1' }
      requires :epic_iid, type: Integer, desc: 'The internal ID of an epic', documentation: { example: 1 }
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get related epics' do
        success EE::API::Entities::Epic
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      get ':id/(-/)epics/:epic_iid/epics' do
        authorize_epics_feature!
        authorize_can_read!

        present child_epics, with: EE::API::Entities::Epic
      end

      desc 'Relate epics' do
        success EE::API::Entities::Epic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' }
        ]
      end
      params do
        use :child_epic_id
      end
      post ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_admin_epic_tree_relation!

        target_child_epic = Epic.find_by_id(declared_params[:child_epic_id])

        create_params = { target_issuable: target_child_epic }

        result = ::Epics::EpicLinks::CreateService.new(epic, current_user, create_params).execute

        if result[:status] == :success
          present child_epic, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Create and relate epic to a parent' do
        success EE::API::Entities::Epic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' }
        ]
      end
      params do
        requires :title, type: String, desc: 'The title of a child epic', documentation: { example: "Epic title" }
        optional :confidential,
          type: Boolean,
          desc: "Whether the epic should be confidential. Parameter is ignored if `confidential_epics`` feature flag is disabled. Defaults to the confidentiality state of the parent epic.",
          documentation: { example: true }
      end
      post ':id/(-/)epics/:epic_iid/epics' do
        authorize_admin_epic_tree_relation!

        confidential = params[:confidential].nil? ? epic.confidential : params[:confidential]
        create_params = { parent_id: epic.id, title: params[:title], confidential: confidential }

        child_epic = ::Epics::CreateService.new(group: user_group, current_user: current_user, params: create_params).execute

        if child_epic.valid?
          present child_epic, with: EE::API::Entities::LinkedEpic, user: current_user
        else
          render_validation_error!(child_epic)
        end
      end

      desc 'Remove epics relation' do
        success EE::API::Entities::Epic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        use :child_epic_id
      end
      delete ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize!(:admin_epic_relation, epic)

        result = ::Epics::EpicLinks::DestroyService.new(child_epic, current_user).execute

        if result[:status] == :success
          present child_epic, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Reorder child epics' do
        success EE::API::Entities::Epic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        use :child_epic_id
        optional :move_before_id,
          type: Integer,
          desc: 'The ID of the epic that should be positioned before the child epic',
          documentation: { example: 1 }
        optional :move_after_id,
          type: Integer,
          desc: 'The ID of the epic that should be positioned after the child epic',
          documentation: { example: 1 }
      end
      put ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_admin_epic_tree_relation!

        update_params = params.slice(:move_before_id, :move_after_id)

        result = ::Epics::EpicLinks::UpdateService.new(child_epic, current_user, update_params).execute

        if result[:status] == :success
          present child_epics, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
