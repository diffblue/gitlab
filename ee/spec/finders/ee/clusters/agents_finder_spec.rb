# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentsFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user, maintainer_projects: [project]) }
    let_it_be(:reporter) { create(:user) }

    let_it_be(:agent_without_vulnerabilities) { create(:cluster_agent, project: project, has_vulnerabilities: false) }
    let_it_be(:agent_with_vulnerabilities) { create(:cluster_agent, project: project, has_vulnerabilities: true) }
    let_it_be(:wrong_agent) { create(:cluster_agent) }

    let(:current_user) { user }

    subject { described_class.new(project, current_user).execute }

    context 'user does not have permission' do
      let(:current_user) { reporter }

      before do
        project.add_reporter(reporter)
      end

      it { is_expected.to be_empty }
    end

    context 'filtering by has_vulnerabilities' do
      let(:params) { { has_vulnerabilities: has_vulnerabilities } }

      subject { described_class.new(project, user, params: params).execute }

      context 'when params are not provided' do
        let(:params) { {} }

        it { is_expected.to contain_exactly(agent_without_vulnerabilities, agent_with_vulnerabilities) }
      end

      context 'when has_vulnerabilities is set to true' do
        let(:has_vulnerabilities) { true }

        it { is_expected.to contain_exactly(agent_with_vulnerabilities) }
      end

      context 'when has_vulnerabilities is set to false' do
        let(:has_vulnerabilities) { false }

        it { is_expected.to contain_exactly(agent_without_vulnerabilities) }
      end
    end
  end
end
