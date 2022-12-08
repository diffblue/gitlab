# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project active tab', feature_category: :projects do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  context 'on project Analytics/Insights' do
    before do
      stub_licensed_features(insights: true)

      visit project_insights_path(project)
    end

    it_behaves_like 'page has active tab', _('Analytics')
    it_behaves_like 'page has active sub tab', _('Insights')
  end

  context 'on project Analytics/Code Review' do
    before do
      stub_licensed_features(code_review_analytics: true)

      visit project_analytics_code_reviews_path(project)
    end

    it_behaves_like 'page has active tab', _('Analytics')
    it_behaves_like 'page has active sub tab', _('Code review')
  end

  context 'on project CI/CD' do
    context 'browsing Pipelines tabs' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      context 'Security tab' do
        before do
          visit security_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Licenses tab' do
        before do
          visit licenses_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Code Quality tab' do
        before do
          visit codequality_report_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end
    end
  end
end
