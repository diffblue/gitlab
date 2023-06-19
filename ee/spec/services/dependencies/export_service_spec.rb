# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportService, feature_category: :dependency_management do
  describe '.execute' do
    let(:dependency_list_export) { instance_double(Dependencies::DependencyListExport) }

    subject(:execute) { described_class.execute(dependency_list_export) }

    it 'instantiates a service object and sends execute message to it' do
      expect_next_instance_of(described_class, dependency_list_export) do |service_object|
        expect(service_object).to receive(:execute)
      end

      execute
    end
  end

  describe '#execute' do
    let(:created_status) { 0 }
    let(:running_status) { 1 }
    let(:finished_status) { 2 }
    let(:service_class) { described_class.new(dependency_list_export) }

    shared_examples_for 'export service' do |serializer_service|
      subject(:export) { service_class.execute }

      context 'when the export is not in `created` status' do
        let(:status) { running_status }

        it 'does not run the logic' do
          expect { export }.not_to change { dependency_list_export.reload.file.file }.from(nil)
        end
      end

      context 'when the export is in `created` status' do
        let(:status) { created_status }

        before do
          allow(Dependencies::DestroyExportWorker).to receive(:perform_in)
        end

        context 'when the export fails' do
          before do
            allow(serializer_service).to receive(:execute).and_raise('Foo')
          end

          it 'propagates the error, resets the status of the export, and does not schedule deletion job' do
            expect { export }.to raise_error('Foo')
                             .and not_change { dependency_list_export.status }

            expect(Dependencies::DestroyExportWorker).not_to have_received(:perform_in)
          end
        end

        context 'when the export succeeds' do
          before do
            allow(serializer_service).to receive(:execute).with(dependency_list_export).and_return('Foo')
          end

          it 'marks the export as finished' do
            expect { export }.to change { dependency_list_export.status }.from(created_status).to(finished_status)
          end

          it 'attaches the file to export' do
            expect { export }.to change { dependency_list_export.file.read }.from(nil).to('"Foo"')
          end

          it 'schedules the export deletion job' do
            export

            expect(Dependencies::DestroyExportWorker)
              .to have_received(:perform_in).with(1.hour, dependency_list_export.id)
          end
        end
      end
    end

    context 'when the exportable is a project' do
      it_behaves_like 'export service', Dependencies::ExportSerializers::ProjectDependenciesService do
        let(:dependency_list_export) { create(:dependency_list_export, status: status) }
      end
    end

    context 'when the exportable is a group' do
      let_it_be(:group) { create(:group) }

      it_behaves_like 'export service', Dependencies::ExportSerializers::GroupDependenciesService do
        let(:dependency_list_export) { create(:dependency_list_export, exportable: group, status: status) }
      end
    end
  end
end
