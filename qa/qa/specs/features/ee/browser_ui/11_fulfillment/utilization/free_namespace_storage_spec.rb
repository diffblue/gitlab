# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :runner, :requires_admin,
    only: { subdomain: :staging },
    feature_flag: { name: 'namespace_storage_limit', scope: :group },
    product_group: :utilization do
    describe 'Utilization' do
      include Runtime::Fixtures

      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner_user) }
      let(:hash) { SecureRandom.hex(8) }
      let(:content) { Faker::Lorem.paragraph(sentence_count: 1000) }

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

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "free-project-#{hash}"
          project.template_name = 'express'
          project.group = free_plan_group
          project.api_client = owner_api_client
        end
      end

      before do
        Flow::Login.sign_in(as: owner_user)

        Runtime::Feature.enable(:reduce_aggregation_schedule_lease, group: free_plan_group)

        endpoint = QA::Runtime::API::Request.new(admin_api_client, '/application/settings').url
        put endpoint, { namespace_aggregation_schedule_lease_duration_in_seconds: 120 }

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.api_client = owner_api_client
          commit.project = project
          commit.commit_message = 'Add large file'
          commit.add_files([{ file_path: 'test.rb', content: SecureRandom.hex(10000) }]) # 10.2 KiB
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.api_client = owner_api_client
          commit.project = project
          commit.commit_message = 'Add CI config file'
          commit.add_files([{
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              container-registry:
                image: docker:24.0.1
                services:
                  - docker:24.0.1-dind
                variables:
                  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
                  DOCKER_HOST: tcp://docker:2376
                  DOCKER_TLS_CERTDIR: "/certs"
                  DOCKER_TLS_VERIFY: 1
                  DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
                before_script:
                  - |
                    echo "Waiting for docker to start..."
                    for i in $(seq 1 30); do
                      docker info && break
                      sleep 1s
                    done
                script:
                  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
                  - docker build -t $IMAGE_TAG .
                  - docker push $IMAGE_TAG
            YAML
          }])
        end

        Resource::Wiki::ProjectPage.fabricate_via_api! do |wiki|
          wiki.api_client = owner_api_client
          wiki.project = project
          wiki.title = 'Wiki'
          wiki.content = content # 10.2 KiB
        end

        Resource::ProjectSnippet.fabricate_via_api! do |snippet|
          snippet.api_client = admin_api_client
          snippet.project = project
          snippet.title = 'Snippet to move storage of'
          snippet.file_name = 'original_file'
          snippet.file_content = content
        end
      end

      after do
        owner_user.remove_via_api!

        endpoint = QA::Runtime::API::Request.new(admin_api_client, '/application/settings').url

        put endpoint, { namespace_aggregation_schedule_lease_duration_in_seconds: 300 }
      end

      def convert_to_mib(size)
        unit = 'KiB'
        amount = size.split(' ')[0].to_f

        if size.include? unit
          amount / 1024
        else
          amount
        end
      end

      context 'in usage quotas storage tab for free plan with a project' do
        it(
          'shows correct used up storage for namespace',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375059'
        ) do
          Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
            project.visit!
            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('container-registry')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end

            free_plan_group.visit!

            Runtime::Feature.enable(:namespace_storage_limit, group: free_plan_group)

            Page::Group::Menu.perform(&:go_to_usage_quotas)
            usage_quota.storage_tab

            aggregate_failures do
              expect(usage_quota.project_repository_size).to match(%r{\d+\.?\d+ [KMG]?i?B})
              expect(usage_quota.project_snippets_size).to match(%r{\d+\.?\d+ [KMG]?i?B})
              expect(usage_quota.project_wiki_size).to match(%r{\d+\.?\d+ [KMG]?i?B})
              expect(usage_quota.project_containers_registry_size).to match(%r{\d+\.?\d+ [KMG]?i?B})

              repository_size = convert_to_mib(usage_quota.project_repository_size) # 41.0 KiB
              snippets_size = convert_to_mib(usage_quota.project_snippets_size) # 10.2 KiB
              wiki_size = convert_to_mib(usage_quota.project_wiki_size) # 10.2 KiB
              containers_registry_size = convert_to_mib(usage_quota.project_containers_registry_size) # 48.2 MiB
              total_size = ((repository_size + snippets_size + wiki_size + containers_registry_size) * 10).to_i / 10.0

              expect do
                ::QA::Support::WaitForRequests.wait_for_requests # Handle element loading text
                usage_quota.namespace_usage_total.squish
              end
                .to eventually_match(%r{Namespace storage used #{total_size} [KMG]i?B.+}i)
                      .within(max_attempts: 10, reload_page: page, sleep_interval: 1)

              expect(usage_quota.dependency_proxy_size).to match(%r{0 B}i)
              expect(usage_quota.group_usage_message)
                .to match(%r{Usage of group resources across the projects in the #{free_plan_group.path} group}i)
            end
          end
        end
      end
    end
  end
end
