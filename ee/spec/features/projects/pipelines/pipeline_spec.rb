# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline', :js, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }

  before do
    sign_in(user)

    project.add_developer(user)
  end

  describe 'GET /:project/-/pipelines/:id' do
    let(:pipeline) { create(:ci_pipeline, :with_job, project: project, ref: 'master', sha: project.commit.id, user: user) }

    subject { visit project_pipeline_path(project, pipeline) }

    context 'triggered and triggered by pipelines' do
      let(:upstream_pipeline) { create(:ci_pipeline, :with_job) }
      let(:downstream_pipeline) { create(:ci_pipeline, :with_job) }

      before do
        upstream_pipeline.project.add_developer(user)
        downstream_pipeline.project.add_developer(user)

        create_link(upstream_pipeline, pipeline)
        create_link(pipeline, downstream_pipeline)
      end

      context 'expands the upstream pipeline on click' do
        it 'renders upstream pipeline' do
          subject

          expect(page).to have_content(upstream_pipeline.id)
          expect(page).to have_content(upstream_pipeline.project.name)
        end

        it 'expands the upstream on click' do
          subject

          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click
          wait_for_requests
          expect(page).to have_selector("#pipeline-links-container-#{upstream_pipeline.id}")
        end

        it 'closes the expanded upstream on click' do
          subject

          # open
          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click
          wait_for_requests

          # close
          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click

          expect(page).not_to have_selector("#pipeline-links-container-#{upstream_pipeline.id}")
        end
      end

      it 'renders downstream pipeline' do
        subject

        expect(page).to have_content(downstream_pipeline.id)
        expect(page).to have_content(downstream_pipeline.project.name)
      end

      context 'expands the downstream pipeline on click' do
        it 'expands the downstream on click' do
          subject

          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click
          wait_for_requests
          expect(page).to have_selector("#pipeline-links-container-#{downstream_pipeline.id}")
        end

        it 'closes the expanded downstream on click' do
          subject

          # open
          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click
          wait_for_requests

          # close
          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click

          expect(page).not_to have_selector("#pipeline-links-container-#{downstream_pipeline.id}")
        end
      end
    end

    context 'when :ci_require_credit_card_on_free_plan flag is on' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        create(:gitlab_subscription, namespace: namespace, hosted_plan: create(:free_plan))

        stub_feature_flags(ci_require_credit_card_on_free_plan: true)
      end

      context 'on free plan' do
        it 'does not show an alert to verify an account with a credit card' do
          subject

          expect(page).not_to have_selector('[data-testid="creditCardValidationRequiredAlert"]')
        end

        context 'when failed' do
          let!(:pipeline) do
            create(
              :ci_empty_pipeline,
              project: project,
              ref: 'master',
              status: 'failed',
              failure_reason: 'user_not_verified',
              sha: project.commit.id,
              user: user
            )
          end

          it 'shows an alert to verify an account with a credit card' do
            subject

            expect(page).to have_selector('[data-testid="creditCardValidationRequiredAlert"]')
          end
        end
      end
    end

    describe 'pipeline stats text' do
      let_it_be_with_reload(:finished_pipeline) do
        create(:ci_pipeline, :success, project: project,
          ref: 'master', sha: project.commit.id, user: user)
      end

      before do
        finished_pipeline.update!(started_at: "2023-01-01 01:01:05", created_at: "2023-01-01 01:01:01",
          finished_at: "2023-01-01 01:01:10", duration: 9)
      end

      context 'pipeline has finished' do
        it 'shows pipeline stats with flag on' do
          visit project_pipeline_path(project, finished_pipeline)

          within '.pipeline-info' do
            expect(page).to have_content("in #{finished_pipeline.duration} seconds, " \
                                         "using #{finished_pipeline.total_ci_minutes_consumed} compute credits, " \
                                         "and was queued for #{finished_pipeline.queued_duration} seconds")
          end
        end
      end

      context 'pipeline has not finished' do
        it 'does not show pipeline stats' do
          subject

          within '.pipeline-info' do
            expect(page).not_to have_selector('[data-testid="pipeline-stats-text"]')
          end
        end
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/security' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      stub_licensed_features(sast: true, security_dashboard: true)
      stub_feature_flags(pipeline_security_dashboard_graphql: false)
    end

    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'shows security tab pane as active' do
        expect(page).to have_content('Security')
        expect(page).to have_selector('[data-testid="security-tab"]')
      end

      it 'shows security dashboard' do
        expect(page).to have_css('.js-security-dashboard-table')
      end
    end

    context 'without sast artifact' do
      before do
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(page).to have_current_path(pipeline_path(pipeline), ignore_query: true)
        expect(page).not_to have_selector('[data-testid="security-tab"]')
        expect(page).to have_selector('.js-pipeline-graph')
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/licenses' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'with License Compliance and CycloneDX artifacts' do
      before do
        create(:ee_ci_build, :license_scanning, pipeline: pipeline)
        create(:ee_ci_build, :cyclonedx, pipeline: pipeline)

        visit licenses_project_pipeline_path(project, pipeline)
      end

      context 'when the license_scanning_sbom_scanner feature flag is false' do
        before_all do
          stub_feature_flags(license_scanning_sbom_scanner: false)
        end

        it 'shows license tab pane as active' do
          expect(page).to have_content('Licenses')
          expect(page).to have_selector('[data-testid="license-tab"]')
          expect(find('[data-testid="license-tab"]')).to have_content('4')
        end

        it 'shows security report section', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/375026' do
          expect(page).to have_content('Loading License Compliance report')
        end
      end

      context 'when the license_scanning_sbom_scanner feature flag is true' do
        before do
          create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem",
            version: "5.1.4", license_name: "MIT")
          create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus",
            purl_type: "golang", version: "v1.4.2", license_name: "MIT")
          create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus",
            purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause")
          create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api",
            purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
          create(:pm_package_version_license, :with_all_relations, name: "yargs", purl_type: "npm", version: "11.1.0",
            license_name: "unknown")

          visit licenses_project_pipeline_path(project, pipeline)
        end

        it 'shows license tab pane as active' do
          expect(page).to have_content('Licenses')
          expect(page).to have_selector('[data-testid="license-tab"]')
          expect(find('[data-testid="license-tab"]')).to have_content('4')
        end

        it 'shows security report section', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/375026' do
          expect(page).to have_content('Loading License Compliance report')
        end
      end
    end

    context 'without License Compliance or CycloneDX artifacts' do
      before do
        visit licenses_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(page).to have_current_path(pipeline_path(pipeline), ignore_query: true)
        expect(page).not_to have_content('Licenses')
        expect(page).to have_selector('.js-pipeline-graph')
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/codequality_report', :aggregate_failures do
    shared_examples_for 'full codequality report' do
      context 'when licensed' do
        before do
          stub_licensed_features(full_codequality_report: true)
        end

        context 'with code quality artifact' do
          before do
            create(:ee_ci_build, :codequality, pipeline: pipeline)
          end

          context 'when navigating directly to the code quality tab' do
            before do
              visit codequality_report_project_pipeline_path(project, pipeline)
            end

            it_behaves_like 'an active code quality tab'
          end

          context 'when starting from the pipeline tab' do
            before do
              visit project_pipeline_path(project, pipeline)
            end

            it 'shows the code quality tab as inactive' do
              expect(page).to have_content('Code Quality')
              expect(page).not_to have_css('#js-tab-codequality')
            end

            context 'when the code quality tab is clicked' do
              before do
                click_link 'Code Quality'
              end

              it_behaves_like 'an active code quality tab'
            end
          end
        end

        context 'with no code quality artifact' do
          before do
            create(:ee_ci_build, pipeline: pipeline)
            visit project_pipeline_path(project, pipeline)
          end

          it 'does not show code quality tab' do
            expect(page).not_to have_content('Code Quality')
            expect(page).not_to have_css('#js-tab-codequality')
          end
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(full_codequality_report: false)

          create(:ee_ci_build, :codequality, pipeline: pipeline)
          visit project_pipeline_path(project, pipeline)
        end

        it 'does not show code quality tab' do
          expect(page).not_to have_content('Code Quality')
          expect(page).not_to have_css('#js-tab-codequality')
        end
      end
    end

    shared_examples_for 'an active code quality tab' do
      it 'shows code quality tab pane as active, quality issue with link to file, and events for data tracking' do
        expect(page).to have_content('Code Quality')

        expect(page).to have_content('Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.')
        expect(find_link('foo.rb:10')[:href]).to end_with(project_blob_path(project, File.join(pipeline.commit.id, 'foo.rb')) + '#L10')

        expect(page).to have_selector('[data-track-action="click_button"]')
        expect(page).to have_selector('[data-track-label="get_codequality_report"]')
      end
    end

    context 'for a branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

      it_behaves_like 'full codequality report'
    end

    context 'for a merge request pipeline' do
      let(:merge_request) do
        create(:merge_request,
          :with_merge_request_pipeline,
          source_project: project,
          target_project: project,
          merge_sha: project.commit.id)
      end

      let(:pipeline) do
        merge_request.all_pipelines.last
      end

      it_behaves_like 'full codequality report'
    end
  end

  describe 'GET /:project/-/pipelines/:id/validate_account' do
    let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: user, failure_reason: 'user_not_verified') }
    let(:ultimate_plan) { create(:ultimate_plan) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      create(:gitlab_subscription, :active_trial, namespace: namespace, hosted_plan: ultimate_plan)
    end

    context 'with payment validation via CustomersDot api' do
      before do
        subscription_portal_url = ::Gitlab::Routing.url_helpers.subscription_portal_url

        stub_request(:get, "#{subscription_portal_url}/payment_forms/payment_method_validation")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/json',
              'User-Agent' => 'Ruby',
              'X-Admin-Email' => 'gl_com_api@gitlab.com',
              'X-Admin-Token' => 'customer_admin_token'
            })
          .to_return(status: 200, body: "", headers: {})
      end

      it 'redirects to pipeline page with account validation modal opened' do
        visit project_pipeline_validate_account_path(project, pipeline)

        expect(page).to have_current_path(pipeline_path(pipeline))

        expect(page).to have_content('User validation required')

        expect(page).to have_selector("#credit-card-verification-modal")

        # ensure account validation modal is only opened when redirected from /validate_account
        visit current_path
        expect(page).not_to have_selector("#credit-card-verification-modal")
      end
    end
  end

  private

  def create_link(source_pipeline, pipeline)
    source_pipeline.sourced_pipelines.create!(
      source_job: source_pipeline.builds.all.sample,
      source_project: source_pipeline.project,
      project: pipeline.project,
      pipeline: pipeline
    )
  end
end
