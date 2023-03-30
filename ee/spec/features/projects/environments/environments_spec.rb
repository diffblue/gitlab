# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments page', :js, feature_category: :environment_management do
  let(:project) { create(:project, :repository) }
  let!(:environment) { create(:environment, name: 'production', project: project) }
  let(:user) { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:protected_environments).and_return(true)
    project.add_maintainer(user)

    sign_in(user)
  end

  def action_link_selector
    '[data-testid="manual-action-link"]'
  end

  def actions_button_selector
    '[data-testid="environment-actions-button"]'
  end

  context 'when an environment is protected and user has access to it' do
    before do
      create(:protected_environment,
             project: project, name: 'production',
             authorize_user_to_deploy: user)
    end

    context 'when environment has manual actions' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               :success,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      let!(:action) do
        create(:ci_build, :manual,
               pipeline: pipeline, name: 'deploy to production',
               environment: 'production')
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'shows an enabled play button' do
        find(actions_button_selector).click

        expect(page).to have_selector(action_link_selector)
      end

      it 'shows a stop button' do
        stop_button_selector = %q{button[title="Stop environment"]}

        expect(page).to have_selector(stop_button_selector)
      end

      context 'with external_url' do
        let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }

        it 'shows an external link button' do
          expect(page).to have_link(nil, href: environment.external_url)
        end
      end

      context 'when terminal is available' do
        let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
        let(:project) { cluster.project }

        it 'shows a terminal button' do
          click_button(_('More actions'))
          expect(page).to have_link(_('Terminal'), href: terminal_project_environment_path(project, environment))
        end
      end
    end

    context 'when environment can be rollback' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:build) { create(:ci_build, :success, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               :success,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'shows re deploy button' do
        click_button(_('More actions'))
        expect(page).to have_button(s_('Environments|Re-deploy to environment'))
      end
    end
  end

  context 'when environment is protected and user does not have access to it' do
    before do
      create(:protected_environment,
             project: project, name: 'production',
             authorize_user_to_deploy: create(:user))
    end

    context 'when environment has manual actions' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               :success,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      let!(:action) do
        create(:ci_build, :manual,
               pipeline: pipeline, name: 'deploy to production',
               environment: 'production')
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'show a disabled play button' do
        find(actions_button_selector).click
        disabled_play_button = page.find('button[disabled="disabled"]')

        expect(disabled_play_button.text).to eq('deploy to production')
      end

      it 'does not show a stop button' do
        stop_button_selector = %q{button[title="Stop environment"]}

        expect(page).not_to have_selector(stop_button_selector)
      end

      context 'with external_url' do
        let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }

        it 'shows an external link button' do
          expect(page).to have_link(nil, href: environment.external_url)
        end
      end

      context 'when terminal is available' do
        let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
        let(:project) { cluster.project }

        it 'does not shows a terminal button' do
          expect(page).not_to have_button(_('More actions'))
          expect(page).not_to have_link(nil, href: terminal_project_environment_path(project, environment))
        end
      end
    end

    context 'when environment can be rollback' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:build) { create(:ci_build, :success, pipeline: pipeline, environment: 'production') }

      let!(:deployment) do
        create(:deployment,
               :success,
               environment: environment, deployable: build,
               sha: project.commit.id)
      end

      before do
        visit project_environments_path(project)
        wait_for_requests
      end

      it 'does not show a re deploy button' do
        redeploy_button_selector = %q{button[title="Re-deploy to environment"]}

        expect(page).not_to have_button(_('More actions'))
        expect(page).not_to have_selector(redeploy_button_selector)
      end
    end
  end

  context 'when environment has an open alert' do
    let!(:alert) do
      create(:alert_management_alert, :triggered, :prometheus,
        title: 'HTTP Error Rate', project: project,
        environment: environment, prometheus_alert: prometheus_alert)
    end

    let!(:prometheus_alert) do
      create(:prometheus_alert,
             project: project, environment: environment,
             prometheus_metric: prometheus_metric)
    end

    let!(:prometheus_metric) do
      create(:prometheus_metric, project: project, unit: '%')
    end

    before do
      stub_licensed_features(environment_alerts: true)
    end

    it 'shows the open alert for the environment row' do
      visit project_environments_path(project)

      page.click_button _('Expand')

      within(find('div[data-testid="alert"]')) do
        expect(page).to have_content('Critical')
        expect(page).to have_content('HTTP Error Rate exceeded 1.0%')
        expect(page).to have_link('View Details', href: alert.present.details_url)
      end

      # and it's not shown when the alert is resolved.
      alert.resolve!
      visit project_environments_path(project)

      expect(page).not_to have_css('div[data-testid="alert"]')
    end

    context 'when user does not have a license for the feature' do
      before do
        stub_licensed_features(environment_alerts: false)
      end

      it 'does not show the open alert for the environment row' do
        visit project_environments_path(project)

        expect(page).not_to have_css('div[data-testid="alert"]')
      end
    end
  end
end
