# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }

  before do
    sign_in(user)

    project.add_developer(user)

    stub_feature_flags(pipeline_tabs_vue: false)
  end

  describe 'GET /:project/-/pipelines/:id' do
    let(:pipeline) do
      create(
        :ci_pipeline,
        :with_job,
        project: project,
        ref: 'master',
        sha: project.commit.id,
        user: user
      )
    end

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

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Security')
        expect(page).to have_css('#js-tab-security')
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
        expect(page).not_to have_css('#js-tab-security')
        expect(page).to have_selector('.js-pipeline-graph')
      end
    end
  end

  describe 'GET /:project/-/pipelines/:id/licenses' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'with a License Compliance artifact' do
      before do
        create(:ee_ci_build, :license_scanning, pipeline: pipeline)

        visit licenses_project_pipeline_path(project, pipeline)
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Licenses')
        expect(page).to have_css('#js-tab-licenses')
        expect(find('.js-licenses-counter')).to have_content('4')
      end

      it 'shows security report section' do
        expect(page).to have_content('Loading License Compliance report')
      end
    end

    context 'without License Compliance artifact' do
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

  describe 'GET /:project/-/pipelines/:id/validate_account' do
    let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: user, failure_reason: 'user_not_verified') }
    let(:ultimate_plan) { create(:ultimate_plan) }

    before do
      allow(Gitlab).to receive(:com?) { true }
      stub_feature_flags(use_api_for_payment_validation: false)
      create(:gitlab_subscription, :active_trial, namespace: namespace, hosted_plan: ultimate_plan)
    end

    it 'redirects to pipeline page with account validation modal opened' do
      visit project_pipeline_validate_account_path(project, pipeline)

      expect(page).to have_current_path(pipeline_path(pipeline))

      account_validation_alert_content = 'User validation required'
      expect(page).to have_content(account_validation_alert_content)

      expect(page).to have_selector("#credit-card-verification-modal")

      # ensure account validation modal is only opened when redirected from /validate_account
      visit current_path
      expect(page).not_to have_selector("#credit-card-verification-modal")
    end

    context 'with payment validation via api feature flag' do
      it 'pushes use_api_for_payment_validation feature flag' do
        visit project_pipeline_validate_account_path(project, pipeline)

        expect(page).to have_pushed_frontend_feature_flags(useApiForPaymentValidation: false)
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
