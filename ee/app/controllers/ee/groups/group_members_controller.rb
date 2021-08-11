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
          super.concat(%i[update override])
        end
      end

      prepended do
        # This before_action needs to be redefined so we can use the new values
        # from `admin_not_required_endpoints`.
        before_action :authorize_admin_group_member!, except: admin_not_required_endpoints

        before_action :authorize_update_group_member!, only: [:update, :override]
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # rubocop: disable CodeReuse/ActiveRecord
      def override
        member = membershipable_members.find_by!(id: params[:id])

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

      protected

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
    end
  end
end
