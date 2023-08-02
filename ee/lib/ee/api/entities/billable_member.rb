# frozen_string_literal: true

module EE
  module API
    module Entities
      class BillableMember < ::API::Entities::UserBasic
        expose :public_email, as: :email
        expose :last_activity_on
        expose :membership_type
        expose :removable
        expose :created_at
        expose :last_owner?, as: :is_last_owner
        expose :current_sign_in_at, as: :last_login_at

        expose :email do |instance, options|
          if options[:current_user]&.can_admin_all_resources? || instance.managed_by?(options[:current_user])
            instance.email
          elsif instance.public_email.present?
            instance.public_email
          end
        end

        private

        def membership_type
          return 'group_member'   if user_in_array?(:group_member_user_ids)
          return 'project_member' if user_in_array?(:project_member_user_ids)
          return 'group_invite'   if user_in_array?(:shared_group_user_ids)
          return 'project_invite' if user_in_array?(:shared_project_user_ids)
        end

        def last_owner?
          options[:group].last_owner?(object)
        end

        def removable
          user_in_array?(:group_member_user_ids) || user_in_array?(:project_member_user_ids)
        end

        def user_in_array?(name)
          options.fetch(name, []).include?(object.id)
        end
      end
    end
  end
end
