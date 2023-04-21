# frozen_string_literal: true

module EE
  module API
    module Members
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The ID of a group'
        end
        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Overrides the access level of an LDAP group member.' do
            success ::API::Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          post ":id/members/:user_id/override", feature_category: :user_management do
            member = find_member(params)

            result = ::Members::UpdateService
              .new(current_user, { override: true })
              .execute(member, permission: :override)

            updated_member = result[:members].first

            if result[:status] == :success
              present_member(updated_member)
            else
              render_validation_error!(updated_member)
            end
          end

          desc 'Remove an LDAP group member access level override.' do
            success ::API::Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          delete ":id/members/:user_id/override", feature_category: :user_management do
            member = find_member(params)

            result = ::Members::UpdateService
              .new(current_user, { override: false })
              .execute(member, permission: :override)

            updated_member = result[:members].first

            if result[:status] == :success
              present_member(updated_member)
            else
              render_validation_error!(updated_member)
            end
          end

          desc 'Approves a pending member'
          params do
            requires :member_id, type: Integer, desc: 'The ID of the member requiring approval'
          end
          put ':id/members/:member_id/approve', feature_category: :subgroups do
            group = find_group!(params[:id])
            member = ::Member.find_by_id(params[:member_id])

            not_found! unless member
            bad_request! unless group.root?
            bad_request! unless can?(current_user, :admin_group_member, group)

            result =
              if member.invite?
                ::Members::ActivateService.for_invite(group, invite_email: member.invite_email).execute(current_user: current_user)
              else
                ::Members::ActivateService.for_users(group, users: [member.user]).execute(current_user: current_user)
              end

            if result[:status] == :success
              no_content!
            else
              bad_request!(result[:message])
            end
          end

          desc 'Approves all pending members'
          post ':id/members/approve_all', feature_category: :subgroups do
            group = find_group!(params[:id])

            bad_request! unless group.root?
            bad_request! unless can?(current_user, :admin_group_member, group)

            result = ::Members::ActivateService.for_group(group).execute(current_user: current_user)

            if result[:status] == :success
              no_content!
            else
              bad_request!(result[:message])
            end
          end

          desc 'Lists all pending members for a group including invited users'
          params do
            use :pagination
          end
          get ":id/pending_members", feature_category: :subgroups do
            group = find_group!(params[:id])

            bad_request! unless group.root?
            bad_request! unless can?(current_user, :admin_group_member, group)

            members = ::Member.distinct_awaiting_or_invited_for_group(group)

            present paginate(members), with: ::API::Entities::PendingMember
          end

          desc 'Gets a list of billable users of root group.' do
            success ::API::Entities::Member
          end
          params do
            use :pagination
            optional :search, type: String, desc: 'The exact name of the subscribed member'
            optional :sort, type: String, desc: 'The sorting option', values: Helpers::MembersHelpers.member_sort_options
          end
          get ":id/billable_members", feature_category: :seat_cost_management do
            group = find_group!(params[:id])

            bad_request!(nil) if group.subgroup?
            bad_request!(nil) unless ::Ability.allowed?(current_user, :read_billable_member, group)

            sorting = params[:sort] || 'id_asc'

            result = BilledUsersFinder.new(group, search_term: params[:search], order_by: sorting).execute

            present paginate(result[:users]),
              with: ::EE::API::Entities::BillableMember,
              current_user: current_user,
              group: group,
              group_member_user_ids: result[:group_member_user_ids],
              project_member_user_ids: result[:project_member_user_ids],
              shared_group_user_ids: result[:shared_group_user_ids],
              shared_project_user_ids: result[:shared_project_user_ids]
          end

          desc 'Changes the state of the memberships of a user in the group'
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the user'
            requires :state, type: String, values: %w(awaiting active), desc: 'The new state for the memberships of the user'
          end
          put ":id/members/:user_id/state", feature_category: :user_management do
            user = find_user(params[:user_id])
            not_found!('User') unless user

            group = find_group(params[:id])
            not_found!('Group') unless group
            bad_request! unless group.root?
            bad_request! unless can?(current_user, :admin_group_member, group)

            result =
              if params[:state] == 'active'
                ::Members::ActivateService.for_users(group, users: [user]).execute(current_user: current_user)
              else
                ::Members::AwaitService.new(group, user: user, current_user: current_user).execute
              end

            if result[:status] == :success
              { success: true }
            else
              unprocessable_entity!(result[:message])
            end
          end

          desc 'Get the memberships of a billable user of a root group.' do
            success ::EE::API::Entities::BillableMembership
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
            use :pagination
          end
          get ":id/billable_members/:user_id/memberships", feature_category: :seat_cost_management do
            group = find_group!(params[:id])

            bad_request! unless can?(current_user, :admin_group_member, group)
            bad_request! if group.subgroup?

            user = ::User.find(params[:user_id])

            not_found!('User') unless billable_member?(group, user)

            memberships = user.members.in_hierarchy(group).including_source

            present paginate(memberships), with: ::EE::API::Entities::BillableMembership
          end

          desc 'Removes a billable member from a group or project.'
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          delete ":id/billable_members/:user_id", feature_category: :seat_cost_management do
            group = find_group!(params[:id])

            result = ::BillableMembers::DestroyService.new(group, user_id: params[:user_id], current_user: current_user).execute

            if result[:status] == :success
              no_content!
            else
              bad_request!(result[:message])
            end
          end
        end
      end
    end
  end
end
