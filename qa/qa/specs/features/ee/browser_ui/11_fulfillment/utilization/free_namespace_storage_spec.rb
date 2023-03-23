# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin,
                 only: { subdomain: :staging },
                 feature_flag: { name: 'namespace_storage_limit', scope: :group },
                 product_group: :utilization do
    describe 'Utilization', quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/398115',
      type: :investigating
    } do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner_user) }
      let(:hash) { SecureRandom.hex(8) }

      let(:owner_user) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:free_plan_group) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "fulfillment-free-plan-group-#{hash}"
          sandbox.api_client = owner_api_client
        end
      end

      before do
        Flow::Login.sign_in(as: owner_user)

        Resource::Project.fabricate_via_api! do |project|
          project.name = "free-project-#{hash}"
          project.group = free_plan_group
          project.initialize_with_readme = true
          project.api_client = owner_api_client
        end

        free_plan_group.visit!

        # Runtime::Feature.enable(:namespace_storage_limit, group: free_plan_group)
        Runtime::Feature.enable(:enforce_storage_limit_for_free, group: free_plan_group)
        Runtime::Feature.enable(:namespace_storage_limit_bypass_date_check, group: free_plan_group)

        Page::Group::Menu.perform(&:go_to_usage_quotas)
      end

      after do
        owner_user.remove_via_api!
      end

      context 'in usage quotas storage tab for free plan with a project' do
        it(
          'shows correct used up storage for namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375059'
        ) do
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            usage_quota.storage_tab

            aggregate_failures do
              expect(usage_quota.namespace_usage_total.squish).to match(/\d+\.\d+ Ki?B Namespace storage used/i)
              expect(usage_quota.purchased_usage_total.squish).to match(/\d+ Gi?B \D+ Purchased storage/i)
              expect(usage_quota.dependency_proxy_size).to match(/0 bytes/i)
              expect(usage_quota.container_registry_size).to match(/0 bytes/i)
              expect(usage_quota.group_usage_message)
                .to match(/Usage of group resources across the projects in the #{free_plan_group.path} group/i)
            end
          end
        end
      end
    end
  end
end
