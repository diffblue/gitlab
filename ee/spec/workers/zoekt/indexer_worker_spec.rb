# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::IndexerWorker, feature_category: :global_search do
  let_it_be(:project) { create(:project, :repository) }
  let(:use_zoekt) { true }

  subject { described_class.new }

  before do
    # Mocking Project.find simplifies the stubs on project.use_zoekt? and
    # project.repository
    allow(Project).to receive(:find).with(project.id).and_return(project)
    allow(project).to receive(:use_zoekt?).and_return(use_zoekt)
  end

  describe '#perform' do
    it 'sends the project to Zoekt for indexing' do
      expect(project.repository).to receive(:update_zoekt_index!)

      subject.perform(project.id)
    end

    context 'when index_code_with_zoekt is disabled' do
      before do
        stub_feature_flags(index_code_with_zoekt: false)
      end

      it 'does not send the project to Zoekt for indexing' do
        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end

    context 'when the zoekt_code_search licensed feature is disabled' do
      before do
        stub_licensed_features(zoekt_code_search: false)
      end

      it 'does nothing' do
        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end

    context 'when the project does not have zoekt enabled' do
      let(:use_zoekt) { false }

      it 'does not send the project to Zoekt for indexing' do
        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end

    context 'when the indexer is locked for the given project' do
      it 'does not run index' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("Zoekt::IndexerWorker/#{project.id}", ttl: (Zoekt::IndexerWorker::TIMEOUT + 1.minute), retries: 0)

        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end

    context 'when the project has no repository' do
      let(:project) { create(:project) }

      it 'does nothing' do
        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end

    context 'when the project has an empty repository' do
      let(:project) { create(:project_empty_repo) }

      it 'does nothing' do
        expect(project.repository).not_to receive(:update_zoekt_index!)

        subject.perform(project.id)
      end
    end
  end
end
