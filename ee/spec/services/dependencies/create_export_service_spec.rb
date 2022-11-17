# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::CreateExportService, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }

  subject(:create_export) { described_class.new(project, user).execute }

  describe '#execute' do
    shared_examples 'invalid parameters' do
      it 'does not schedule a Dependencies::ExportWorker job' do
        expect(Dependencies::ExportWorker).not_to receive(:perform_async)

        create_export
      end

      it 'returns nil' do
        expect(create_export).to be_nil
      end
    end

    context 'when project is nil' do
      subject(:create_export) { described_class.new(nil, user).execute }

      include_examples 'invalid parameters'
    end

    it 'returns a new instance of dependency_list_export' do
      expect(create_export).to be_a(Dependencies::DependencyListExport)
    end

    it 'schedules a Dependencies::ExportWorker job' do
      expect(Dependencies::ExportWorker).to receive(:perform_async)

      create_export
    end
  end
end
