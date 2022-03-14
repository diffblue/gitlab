# frozen_string_literal: true

module API
  class GroupHooks < ::API::Base
    include ::API::PaginationParams

    feature_category :integrations

    before { authenticate! }
    before { authorize! :admin_group, user_group }

    helpers do
      params :group_hook_properties do
        requires :url, type: String, desc: "The URL to send the request to"
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :push_events_branch_filter, type: String, desc: "Respond to push events only on branches that match this filter"
        optional :issues_events, type: Boolean, desc: "Trigger hook on issues events"
        optional :confidential_issues_events, type: Boolean, desc: "Trigger hook on confidential issues events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on merge request events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :note_events, type: Boolean, desc: "Trigger hook on note(comment) events"
        optional :confidential_note_events, type: Boolean, desc: "Trigger hook on confidential note(comment) events"
        optional :job_events, type: Boolean, desc: "Trigger hook on job events"
        optional :pipeline_events, type: Boolean, desc: "Trigger hook on pipeline events"
        optional :wiki_page_events, type: Boolean, desc: "Trigger hook on wiki events"
        optional :deployment_events, type: Boolean, desc: "Trigger hook on deployment events"
        optional :releases_events, type: Boolean, desc: "Trigger hook on release events"
        optional :subgroup_events, type: Boolean, desc: "Trigger hook on subgroup events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get group hooks' do
        success EE::API::Entities::GroupHook
      end
      params do
        use :pagination
      end
      get ":id/hooks" do
        present paginate(user_group.hooks), with: EE::API::Entities::GroupHook
      end

      desc 'Get a group hook' do
        success EE::API::Entities::GroupHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of a group hook'
      end
      get ":id/hooks/:hook_id" do
        hook = user_group.hooks.find(params[:hook_id])
        present hook, with: EE::API::Entities::GroupHook
      end

      desc 'Add hook to group' do
        success EE::API::Entities::GroupHook
      end
      params do
        use :group_hook_properties
      end
      post ":id/hooks" do
        hook_params = declared_params(include_missing: false)

        hook = user_group.hooks.new(hook_params)

        if hook.save
          present hook, with: EE::API::Entities::GroupHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?

          render_api_error!("Group hook #{hook.errors.messages}", 422)
        end
      end

      desc 'Update an existing group hook' do
        success EE::API::Entities::GroupHook
      end
      params do
        requires :hook_id, type: Integer, desc: "The ID of the hook to update"
        use :group_hook_properties
      end
      put ":id/hooks/:hook_id" do
        hook = user_group.hooks.find(params.delete(:hook_id))

        update_params = declared_params(include_missing: false)

        if hook.update(update_params)
          present hook, with: EE::API::Entities::GroupHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?

          render_api_error!("Group hook #{hook.errors.messages}", 422)
        end
      end

      desc 'Deletes group hook' do
        success EE::API::Entities::GroupHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to delete'
      end
      delete ":id/hooks/:hook_id" do
        hook = user_group.hooks.find(params.delete(:hook_id))

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
    end
  end
end
