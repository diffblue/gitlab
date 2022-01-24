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
          find_epics(finder_params: { group_id: user_group.id })
            .find_by_id(declared_params[:child_epic_id])
        end
      end

      def child_epics
        EpicsFinder.new(current_user, {
          parent_id: epic.id,
          group_id: user_group.id,
          sort: 'relative_position'
        }).execute
      end

      params :child_epic_id do
        # Unique ID should be used because epics from other groups can be assigned as child.
        requires :child_epic_id, type: Integer, desc: 'The global ID of the epic that will be assigned as child'
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
      requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get related epics' do
        success EE::API::Entities::Epic
      end
      get ':id/(-/)epics/:epic_iid/epics' do
        authorize_epics_feature!
        authorize_can_read!

        present child_epics, with: EE::API::Entities::Epic
      end

      desc 'Relate epics' do
        success EE::API::Entities::Epic
      end
      params do
        use :child_epic_id
      end
      post ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_subepics_feature!
        authorize_can_admin_epic_link!

        create_params = { target_issuable: child_epic }

        result = ::EpicLinks::CreateService.new(epic, current_user, create_params).execute

        if result[:status] == :success
          present child_epic, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Create and relate epic to a parent' do
        success EE::API::Entities::Epic
      end
      params do
        requires :title, type: String, desc: 'The title of a child epic'
        optional :confidential, type: Boolean, desc: 'Indicates if the epic is confidential. Will be ignored if `confidential_epics` feature flag is disabled'
      end
      post ':id/(-/)epics/:epic_iid/epics' do
        authorize_subepics_feature!
        authorize_can_admin_epic_link!

        confidential = params[:confidential].nil? ? epic.confidential : params[:confidential]
        create_params = { parent_id: epic.id, title: params[:title], confidential: confidential }

        child_epic = ::Epics::CreateService.new(group: user_group, current_user: current_user, params: create_params).execute

        if child_epic.valid?
          present child_epic, with: EE::API::Entities::LinkedEpic, user: current_user
        else
          render_validation_error!(child_epic)
        end
      end

      desc 'Remove epics relation'
      params do
        use :child_epic_id
      end
      delete ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_can_destroy_epic_link!

        updated_epic = ::Epics::UpdateService.new(group: user_group, current_user: current_user, params: { parent: nil }).execute(child_epic)

        present updated_epic, with: EE::API::Entities::Epic
      end

      desc 'Reorder child epics'
      params do
        use :child_epic_id
        optional :move_before_id, type: Integer, desc: 'The ID of the epic that should be positioned before the child epic'
        optional :move_after_id, type: Integer, desc: 'The ID of the epic that should be positioned after the child epic'
      end
      put ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_subepics_feature!
        authorize_can_admin_epic_link!

        update_params = params.slice(:move_before_id, :move_after_id)

        result = ::EpicLinks::UpdateService.new(child_epic, current_user, update_params).execute

        if result[:status] == :success
          present child_epics, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
