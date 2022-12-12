# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::DestroyExportWorker, type: :worker, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:dependency_list_export) { create(:dependency_list_export, project: project) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:destroy_export) { worker.perform(dependency_list_export.id) }

    it 'destroys the dependency list export' do
      expect { destroy_export }.to change {
                                     Dependencies::DependencyListExport.find_by_id(dependency_list_export.id)
                                   }.to(nil)
    end

    context 'when dependency list export does not exist' do
      subject(:destroy_export) { worker.perform(nil) }

      it 'does not raise exception' do
        expect { destroy_export }.not_to raise_error
      end

      it 'does not delete any dependency list export' do
        expect { destroy_export }.not_to change { Dependencies::DependencyListExport.count }
      end
    end
  end
end
