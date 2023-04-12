# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees Security Configuration table', :js, feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  context 'with security_dashboard feature available' do
    before do
      stub_licensed_features(security_dashboard: true, sast: true, sast_iac: true, dast: true,
                             dependency_scanning: true, container_scanning: true, coverage_fuzzing: true,
                             api_fuzzing: true, security_configuration_in_ui: true)
    end

    context 'with no SAST report' do
      it 'shows SAST is not enabled' do
        visit_configuration_page

        within_sast_card do
          expect(page).to have_text('SAST')
          expect(page).to have_text('Not enabled')
          expect(page).to have_link('Enable SAST')
        end
      end
    end

    context 'with SAST report' do
      before do
        create(:ci_build, :sast, pipeline: pipeline, status: 'success')
      end

      it 'shows SAST is enabled' do
        visit_configuration_page

        within_sast_card do
          expect(page).to have_text('SAST')
          expect(page).to have_text('Enabled')
          expect(page).to have_link('Configure SAST')
        end
      end
    end

    context 'enabling SAST IaC' do
      it 'redirects to new MR page' do
        visit_configuration_page

        within_sast_iac_card do
          expect(page).to have_text('Infrastructure as Code (IaC) Scanning')
          expect(page).not_to have_text('Not enabled')
          expect(page).not_to have_button('Configure with a merge request')
        end
      end
    end

    context 'with no DAST report' do
      it 'shows DAST is not enabled' do
        visit_configuration_page

        within_dast_card do
          expect(page).to have_text('DAST')
          expect(page).to have_text('Not enabled')
          expect(page).to have_link('Enable DAST')
          expect(page).to have_link('Manage profiles')
        end
      end
    end

    context 'with DAST report' do
      before do
        create(:ci_build, :dast, pipeline: pipeline, status: 'success')
      end

      it 'shows DAST is enabled' do
        visit_configuration_page

        within_dast_card do
          expect(page).to have_text('DAST')
          expect(page).to have_text('Enabled')
          expect(page).to have_link('Configure DAST')
          expect(page).to have_link('Manage profiles')
        end
      end
    end

    context 'with no Dependency Scanning report' do
      it 'shows Dependency Scanning is disabled' do
        visit_configuration_page

        within_dependency_scanning_card do
          expect(page).to have_text('Dependency Scanning')
          expect(page).to have_text('Not enabled')
          expect(page).to have_button('Configure with a merge request')
        end
      end
    end

    context 'with Dependency Scanning report' do
      before do
        create(:ci_build, :dependency_scanning, pipeline: pipeline, status: 'success')
      end

      it 'shows Dependency Scanning is enabled' do
        visit_configuration_page

        within_dependency_scanning_card do
          expect(page).to have_text('Dependency Scanning')
          expect(page).to have_text('Enabled')
          expect(page).to have_link('Configuration guide')
        end
      end
    end

    context 'with no Container Scanning report' do
      it 'shows Container Scanning is disabled' do
        visit_configuration_page

        within_container_scanning_card do
          expect(page).to have_text('Container Scanning')
          expect(page).to have_text('Not enabled')
          expect(page).to have_button('Configure with a merge request')
        end
      end
    end

    context 'with no Secret Detection report' do
      it 'shows Secret Detection is disabled' do
        visit_configuration_page

        within_secret_detection_card do
          expect(page).to have_text('Secret Detection')
          expect(page).to have_text('Not enabled')
          expect(page).to have_button('Configure with a merge request')
        end
      end
    end

    context 'with no API Fuzzing report' do
      it 'shows API Fuzzing is disabled' do
        visit_configuration_page

        within_api_fuzzing_card do
          expect(page).to have_text('API Fuzzing')
          expect(page).to have_text('Not enabled')
          expect(page).to have_link('Enable API Fuzzing')
        end
      end
    end

    context 'with no Coverage Fuzzing' do
      it 'shows Coverage Fuzzing is disabled' do
        visit_configuration_page

        within_coverage_fuzzing_card do
          expect(page).to have_text('Coverage Fuzzing')
          expect(page).to have_text('Not enabled')
          expect(page).to have_link('Configuration guide')
        end
      end
    end
  end

  def visit_configuration_page
    visit(project_security_configuration_path(project))
  end

  def within_sast_card
    within '[data-testid="security-testing-card"]:nth-of-type(1)' do
      yield
    end
  end

  def within_sast_iac_card
    within '[data-testid="security-testing-card"]:nth-of-type(2)' do
      yield
    end
  end

  def within_dast_card
    within '[data-testid="security-testing-card"]:nth-of-type(3)' do
      yield
    end
  end

  def within_dependency_scanning_card
    within '[data-testid="security-testing-card"]:nth-of-type(4)' do
      yield
    end
  end

  def within_container_scanning_card
    within '[data-testid="security-testing-card"]:nth-of-type(5)' do
      yield
    end
  end

  def within_secret_detection_card
    within '[data-testid="security-testing-card"]:nth-of-type(6)' do
      yield
    end
  end

  def within_api_fuzzing_card
    within '[data-testid="security-testing-card"]:nth-of-type(7)' do
      yield
    end
  end

  def within_coverage_fuzzing_card
    within '[data-testid="security-testing-card"]:nth-of-type(8)' do
      yield
    end
  end

  def within_breach_and_attack_simulation_card
    within '[data-testid="security-testing-card"]:nth-of-type(9)' do
      yield
    end
  end
end
