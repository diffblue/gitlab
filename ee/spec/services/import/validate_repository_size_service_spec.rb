# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ValidateRepositorySizeService, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:above_size_limit) { true }

  subject(:service) { described_class.new(project) }

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::RepositorySizeChecker) do |checker|
        allow(checker).to receive(:above_size_limit?).and_return(above_size_limit)
      end
    end

    context 'when repository size is over the limit' do
      let(:above_size_limit) { true }

      it 'schedules worker to destroy repository and raises error' do
        expect(::Projects::RepositoryDestroyWorker).to receive(:perform_async).with(project.id)

        expect { service.execute }
          .to raise_error(::Projects::ImportService::Error, 'Repository above permitted size limit.')
      end
    end

    context 'when repository size is not over the limit' do
      let(:above_size_limit) { false }

      it 'does nothing' do
        expect(::Projects::RepositoryDestroyWorker).not_to receive(:perform_async)

        expect(service.execute).to eq(nil)
      end
    end
  end
end
