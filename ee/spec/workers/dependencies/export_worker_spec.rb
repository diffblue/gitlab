# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportWorker, type: :worker, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:export) { worker.perform(dependency_list_export.id) }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'when dependency list export has not been started' do
      let_it_be(:dependency_list_export) { create(:dependency_list_export, project: project, author: user) }

      it 'generates a file related with empty dependency list export' do
        export

        latest_record = Dependencies::DependencyListExport.last

        expect(latest_record).to be_finished

        json_parsed = ::Gitlab::Json.parse(latest_record.file.read)
        expect(json_parsed["dependencies"]).to be_empty
      end

      it 'schedules Dependencies::DestroyExportWorker' do
        latest_record = Dependencies::DependencyListExport.last

        expect(Dependencies::DestroyExportWorker).to receive(:perform_in).with(1.hour, latest_record.id)

        export
      end

      context 'with existing report' do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

        it 'generates a file related with content related to dependency list export' do
          export

          latest_record = Dependencies::DependencyListExport.last

          expect(latest_record).to be_finished

          json_parsed = ::Gitlab::Json.parse(latest_record.file.read)

          expect(json_parsed["dependencies"]).to be_present
        end
      end
    end

    context 'when dependency list export has been already running' do
      let_it_be(:dependency_list_export) { create(:dependency_list_export, :running, project: project, author: user) }

      it 'does not generates a file' do
        export

        latest_record = Dependencies::DependencyListExport.last

        expect(latest_record).to be_running
        expect(latest_record.file.read).to be_nil
      end

      it 'does not schedule Dependencies::DestroyExportWorker' do
        expect(Dependencies::DestroyExportWorker).not_to receive(:perform_in)

        export
      end
    end

    context 'when dependency list export does not exist' do
      subject(:export) { worker.perform(nil) }

      it 'raises exception' do
        expect { export }.to raise_error(ActiveRecord::RecordNotFound)
      end
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
