# frozen_string_literal: true

module API
  module Analytics
    class GroupActivityAnalytics < ::API::Base
      DESCRIPTION_DETAIL =
        'This feature is gated by the `:group_activity_analytics`'\
        ' feature flag, introduced in GitLab 12.9.'

      feature_category :planning_analytics

      before do
        authenticate!
      end

      helpers do
        def group
          @group ||= find_group_by_full_path!(params[:group_path])
        end

        def calculator
          @calculator ||=
            ::Analytics::GroupActivityCalculator.new(group, current_user)
        end
      end

      resource :analytics do
        resource :group_activity do
          desc 'Get count of recently created issues for group' do
            detail DESCRIPTION_DETAIL
            success EE::API::Entities::Analytics::GroupActivity::IssuesCount
          end

          params do
            requires :group_path, type: String, desc: 'Group Path'
          end

          get 'issues_count' do
            authorize! :read_group_activity_analytics, group

            present(
              calculator,
              with: EE::API::Entities::Analytics::GroupActivity::IssuesCount
            )
          end

          desc 'Get count of recently created merge requests for group' do
            detail DESCRIPTION_DETAIL
            success EE::API::Entities::Analytics::GroupActivity::MergeRequestsCount
          end

          params do
            requires :group_path, type: String, desc: 'Group Path'
          end

          get 'merge_requests_count' do
            authorize! :read_group_activity_analytics, group

            present(
              calculator,
              with: EE::API::Entities::Analytics::GroupActivity::MergeRequestsCount
            )
          end

          desc 'Get count of recently created group members' do
            detail DESCRIPTION_DETAIL
            success EE::API::Entities::Analytics::GroupActivity::NewMembersCount
          end

          params do
            requires :group_path, type: String, desc: 'Group Path'
          end

          get 'new_members_count' do
            authorize! :read_group_activity_analytics, group

            present(
              calculator,
              with: EE::API::Entities::Analytics::GroupActivity::NewMembersCount
            )
          end
        end
      end
    end
  end
end
