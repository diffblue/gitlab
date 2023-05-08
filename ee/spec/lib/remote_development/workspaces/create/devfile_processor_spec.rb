# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Create::DevfileProcessor, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: "test-group") }
  let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:workspace) { create(:workspace, agent: agent, user: user) }
  let_it_be(:project) { create(:project, :public, :in_group, :repository, path: "test-project", namespace: group) }

  let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }
  let(:workspace_root) { "/projects" }

  # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409781
  #       Add more test coverage for conditionals, using different example processed devfile fixtures.
  describe '#process' do
    let(:expected_devfile) { YAML.safe_load(example_processed_devfile) }

    subject do
      described_class.new
    end

    it 'returns expected processed devfile yaml' do
      # noinspection RubyResolve
      processed_devfile_yaml = subject.process(
        devfile: workspace.devfile,
        editor: workspace.editor,
        project: project,
        workspace_root: workspace_root
      )
      processed_devfile = YAML.safe_load(processed_devfile_yaml)

      # Perform individual expectations to make it easier to debug failures
      expect(processed_devfile.fetch('components')).to eq(expected_devfile.fetch('components'))
      expect(processed_devfile).to eq(expected_devfile)
    end
  end
end
