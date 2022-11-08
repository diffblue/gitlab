# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipelines Content Security' do
  include ContentSecurityPolicyHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:zuora_url) { 'https://*.zuora.com' }
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
      setup_csp_for_controller(::Projects::PipelinesController)

      visit project_pipeline_path(project, pipeline)
    end

    it { is_expected.to be_blank }
  end

  context 'when a global CSP config exists' do
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.script_src :self, 'https://some-cdn.test'
      end

      setup_csp_for_controller(::Projects::PipelinesController, csp)

      visit project_pipeline_path(project, pipeline)
    end

    it { is_expected.to include("script-src 'self' https://some-cdn.test 'unsafe-eval' #{zuora_url}") }
    it { is_expected.to include("frame-src 'self' #{zuora_url}") }
    it { is_expected.to include("child-src 'self' #{zuora_url}") }
  end
end
