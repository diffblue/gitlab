# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Integrations::Test::ProjectService, feature_category: :integrations do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:user) { project.first_owner }
    let(:event) { nil }
    let(:sample_data) { { data: 'sample' } }
    let(:success_result) { { success: true, result: {} } }

    subject { described_class.new(integration, user, event).execute }

    context 'without event specified' do
      context 'GitHubService' do
        let(:integration) { create(:github_integration, project: project) }

        it_behaves_like 'tests for integration with pipeline data'
      end
    end
  end
end
