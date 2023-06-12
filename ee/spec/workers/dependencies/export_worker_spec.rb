# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportWorker, type: :worker, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:dependency_list_export) { create(:dependency_list_export) }

    subject(:export) { worker.perform(dependency_list_export.id) }

    before do
      allow(Dependencies::ExportService).to receive(:execute)
    end

    it 'delegates the execution to `Dependencies::ExportService`' do
      export

      expect(Dependencies::ExportService).to have_received(:execute).with(dependency_list_export)
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let_it_be(:dependency_list_export) { create(:dependency_list_export, project: project, author: user) }

    let(:job) { { 'args' => [dependency_list_export.id] } }

    subject(:sidekiq_retries_exhausted) { described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new) }

    it 'updates status to failed' do
      expect { sidekiq_retries_exhausted }.to change { dependency_list_export.reload.human_status_name }
      .from('created').to('failed')
    end
  end
end
