# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipelines Content Security', feature_category: :continuous_integration do
  include ContentSecurityPolicyHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, :with_job, project: project, ref: project.default_branch, sha: project.commit.id, user: user)
  end

  before do
    sign_in(user)

    project.add_developer(user)
  end

  subject { response_headers['Content-Security-Policy'] }

  context 'when there is no global config' do
    before do
      setup_csp_for_controller(::Projects::PipelinesController, ActionDispatch::ContentSecurityPolicy.new, times: 1)

      visit project_pipeline_path(project, pipeline)
    end

    it { is_expected.to be_blank }
  end

  context 'when a global CSP config exists' do
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.script_src :self, 'https://some-cdn.test'
      end

      setup_csp_for_controller(::Projects::PipelinesController, csp, times: 1)

      visit project_pipeline_path(project, pipeline)
    end

    it { is_expected.to include("script-src 'self' https://some-cdn.test") }
  end
end
