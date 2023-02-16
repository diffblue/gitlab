# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::DeployKeysRestorer, feature_category: :source_code_management do
  random_boolean = -> { [true, false].sample }

  let_it_be(:user) { create(:admin) }
  let_it_be(:source_project) { create(:project) }
  let_it_be(:source_project_keys) do
    Array.new(4).map do |_|
      create(
        :deploy_keys_project,
        project: source_project,
        can_push: random_boolean.call
      )
    end
  end

  let_it_be(:importable) { create(:project) }

  subject do
    described_class.new(
      project: importable,
      shared: importable.import_export_shared,
      user: user,
      source_project: source_project
    )
  end

  context 'when project deploy keys are present in source project' do
    before do
      allow(user).to receive(:can_admin_all_resources?).and_return(true)
    end

    it 'has the same amount of project deploy keys as the source' do
      subject.restore
      importable_deploy_keys = importable.deploy_keys_projects

      expect(importable_deploy_keys.count).to eq(source_project_keys.count)
      expect(importable_deploy_keys.all?(&:persisted?)).to eq(true)
    end

    it 'has the same deploy_keys_id values and write access compared to source' do
      subject.restore
      importable_project_keys = importable.deploy_keys_projects.map { |dk| [dk.deploy_key_id, dk.can_push] }
      source_project_keys = source_project.deploy_keys_projects.map { |dk| [dk.deploy_key_id, dk.can_push] }

      expect(importable_project_keys).to match_array(source_project_keys)
    end
  end

  context 'when the user is unauthorized' do
    let(:user) { create(:user) }

    it 'raises an error and logs user' do
      expect { subject.restore }.to raise_exception(StandardError, 'Unauthorized service')
    end

    it 'logs the unauthorized user' do
      expect(::Gitlab::Import::Logger).to receive(:warn).once.with(
        message: "User tried to access unauthorized service",
        username: user.username,
        user_id: user.id,
        service: described_class.name,
        error: 'Unauthorized service'
      )
      expect { subject.restore }.to raise_exception(StandardError)
    end
  end

  context 'when all hooks are not duplicated' do
    before do
      allow(user).to receive(:can_admin_all_resources?).and_return(true)
      allow(subject).to receive(:duplicate_project_keys).and_return(false)
    end

    it 'reports the failure' do
      subject.restore
      excepted_msg = 'Could not duplicate all deploy keys projects from custom template Project'

      expect(importable.import_failures.last.exception_message).to eq(excepted_msg)
      expect(subject.restore).to eq(true)
    end

    it 'returns true' do
      expect(subject.restore).to eq(true)
    end
  end
end
