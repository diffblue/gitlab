# frozen_string_literal: true

module EE
  module Groups
    module GroupMembersController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :admin_not_required_endpoints
        def admin_not_required_endpoints
          super.concat(%i[update override export_csv])
        end
      end

      prepended do
        # This before_action needs to be redefined so we can use the new values
        # from `admin_not_required_endpoints`.
        before_action :authorize_admin_group_member!, except: admin_not_required_endpoints
        before_action :authorize_update_group_member!, only: [:update, :override]

        before_action do
          push_frontend_feature_flag(:overage_members_modal, @group) if ::Gitlab::CurrentSettings.should_check_namespace_plan?
          push_frontend_feature_flag(:limit_unique_project_downloads_per_namespace_user, @group)
          push_frontend_feature_flag(:show_overage_on_role_promotion)
          push_licensed_feature(:unique_project_download_limit, @group)
        end
      end

      override :index
      def index
        super

        @banned = presented_banned_members # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # rubocop: disable CodeReuse/ActiveRecord
      def override
        member = membershipable_members.find(params[:id])

        result = ::Members::UpdateService.new(current_user, override_params).execute(member, permission: :override)

        respond_to do |format|
          format.js do
            if result[:status] == :success
              head :ok
            else
              render json: result[:message], status: :unprocessable_entity
            end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def export_csv
        return render_404 unless current_user.can?(:export_group_memberships, group)

        ::Groups::ExportMembershipsWorker.perform_async(group.id, current_user.id)

        redirect_to group_group_members_path(group), notice: _('CSV is being generated and will be emailed to you upon completion.')
      end

      def ban
        member = group_members.find(params[:id])

        result = ::Users::Abuse::NamespaceBans::CreateService.new(user: member.user, namespace: group).execute

        if result.success?
          redirect_to group_group_members_path, notice: _("User was successfully banned.")
        else
          redirect_to group_group_members_path, alert: result.message
        end
      end

      def unban
        member = banned_members.find(params[:id])
        ban = member.user.namespace_ban_for(group)

        result = ::Users::Abuse::NamespaceBans::DestroyService.new(ban, current_user).execute

        redirect_url = group_group_members_path(tab: 'banned')

        if result.success?
          redirect_to redirect_url, notice: _("User was successfully unbanned.")
        else
          redirect_to redirect_url, alert: result.message
        end
      end

      protected

      override :invited_members
      def invited_members
        super.or(group_members.awaiting.with_invited_user_state)
      end

      override :non_invited_members
      def non_invited_members
        members = super.non_awaiting

        if group.unique_project_download_limit_enabled?
          members.where.not(id: banned_members) # rubocop: disable CodeReuse/ActiveRecord
        else
          members
        end
      end

      def presented_banned_members
        return unless group.unique_project_download_limit_enabled?

        present_members(banned_members(params: filter_params))
      end

      def authorize_update_group_member!
        unless can?(current_user, :admin_group_member, group) || can?(current_user, :override_group_member, group)
          render_403
        end
      end

      def override_params
        params.require(:group_member).permit(:override)
      end

      override :membershipable_members
      def membershipable_members
        return super unless group.licensed_feature_available?(:minimal_access_role)

        group.all_group_members
      end

      override :filter_params
      def filter_params
        super.merge(params.permit(:enterprise))
      end

      private

      def banned_members(params: {})
        # User bans are enforced at the top-level group. Here, we return all
        # members of the group hierarchy that are banned from the top-level
        # group
        @banned_members ||= ::GroupMembersFinder # rubocop:disable Gitlab/ModuleWithInstanceVariables
          .new(group, current_user, params: params)
          .execute(include_relations: %i[direct descendants])
          .banned_from(group)
      end
    end
  end
end
