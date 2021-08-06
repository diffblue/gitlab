# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees Security Configuration table', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context 'with security_dashboard feature available' do
    before do
      stub_licensed_features(security_dashboard: true, sast: true, dast: true)
    end

    context 'with no SAST report' do
      it 'shows SAST is not enabled' do
        visit(project_security_configuration_path(project))

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
        visit(project_security_configuration_path(project))

        within_sast_card do
          expect(page).to have_text('SAST')
          expect(page).to have_text('Enabled')
          expect(page).to have_link('Configure SAST')
        end
      end
    end

    context 'with no DAST report' do
      it 'shows DAST is not enabled' do
        visit(project_security_configuration_path(project))

        within_dast_card do
          expect(page).to have_text('DAST')
          expect(page).to have_text('Not enabled')
          expect(page).to have_link('Enable DAST')
        end
      end
    end

    context 'with DAST report' do
      before do
        create(:ci_build, :dast, pipeline: pipeline, status: 'success')
      end

      it 'shows DAST is enabled' do
        visit(project_security_configuration_path(project))

        within_dast_card do
          expect(page).to have_text('DAST')
          expect(page).to have_text('Enabled')
          expect(page).to have_link('Configure DAST')
        end
      end
    end
  end

  def within_sast_card
    within '[data-testid="security-testing-card"]:nth-of-type(1)' do
      yield
    end
  end

  def within_dast_card
    within '[data-testid="security-testing-card"]:nth-of-type(2)' do
      yield
    end
  end
end
