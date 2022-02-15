# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project integrations', :js do
  include_context 'project integration activation'
  it_behaves_like 'integration settings form' do
    let(:integrations) { [Integrations::Github.new] }

    before do
      stub_licensed_features(github_project_service_integration: true)
    end

    def navigate_to_integration(integration)
      visit_project_integration(integration.title)
    end
  end
end
