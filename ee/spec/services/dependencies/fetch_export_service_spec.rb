# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::FetchExportService, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:dependency_list_export) { create(:dependency_list_export, project: project) }

  subject(:fetch_export) { described_class.new(dependency_list_export.id).execute }

  describe '#execute' do
    context 'when record does not exist' do
      subject(:fetch_export) { described_class.new('invalid').execute }

      it 'returns nil' do
        expect(fetch_export).to be_nil
      end
    end

    it 'returns a dependency_list_export' do
      expect(fetch_export).to be_a(Dependencies::DependencyListExport)
    end
  end
end
