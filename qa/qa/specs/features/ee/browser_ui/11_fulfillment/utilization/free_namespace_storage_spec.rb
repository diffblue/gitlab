# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin,
                                only: { subdomain: :staging },
                                feature_flag: { name: 'namespace_storage_limit', scope: :group },
                                product_group: :utilization do
    describe 'Utilization', quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/377442',
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

        Runtime::Feature.enable(:namespace_storage_limit, group: free_plan_group)
        Runtime::Feature.enable(:enforce_storage_limit_for_free, group: free_plan_group)
        Runtime::Feature.enable(:namespace_storage_limit_bypass_date_check, group: free_plan_group)

        free_plan_group.visit!
        Page::Group::Menu.perform(&:go_to_usage_quotas)
      end

      after do
        owner_user.remove_via_api!
        free_plan_group.remove_via_api!
      end

      context 'in usage quotas storage tab for free plan without any projects' do
        it(
          'shows correct storage data for namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375058'
        ) do
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            usage_quota.storage_tab
            # Message is loaded in 2 parts and feature flag might not be reflected instantly
            Support::Waiter.wait_until(max_duration: 60, reload_page: page, message: "Storage message not found") do
              Support::Waiter.wait_until(max_duration: 3, raise_on_failure: false) do
                usage_quota.used_storage_message.include?("storage")
              end
            end

            aggregate_failures do
              expect(usage_quota.used_storage_message).to match(/You used: Not applicable. out of \d+\.\d+MiB/i)
              expect(usage_quota.dependency_proxy_size).to match(/0 Bytes/i)
              expect(usage_quota.group_usage_message).to match(/fulfillment-free-plan-group-#{hash} group/i)
            end
          end
        end
      end

      context 'in usage quotas storage tab for free plan with a project' do
        before do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'free-project'
            project.group = free_plan_group
            project.initialize_with_readme = true
            project.api_client = owner_api_client
          end
        end

        it(
          'shows correct used up storage for namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375059'
        ) do
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            usage_quota.storage_tab
            Support::Waiter.wait_until(max_duration: 60, reload_page: page, message: "Storage data not updated") do
              usage_quota.project_storage_data_available? && usage_quota.used_storage_message.include?("storage")
            end

            aggregate_failures do
              expect(usage_quota.used_storage_message).to match(/You used: \d+\.\d+ KiB out of \d+\.\d+MiB/i)
              expect(usage_quota.dependency_proxy_size).to match(/0 Bytes/i)
              expect(usage_quota.container_registry_size).to match(/0 Bytes/i)
              expect(usage_quota.project).to match(%r{fulfillment-free-plan-group-#{hash} / free-project}i)
              expect(usage_quota.project_storage_used).to match(/\d+\.\d+ KiB/i)
              expect(usage_quota.group_usage_message).to match(/fulfillment-free-plan-group-#{hash} group/i)
            end
          end
        end
      end
    end
  end
end
