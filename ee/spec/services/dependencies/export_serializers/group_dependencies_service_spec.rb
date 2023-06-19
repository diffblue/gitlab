# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportSerializers::GroupDependenciesService, feature_category: :dependency_management do
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
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:dependency_list_export) { create(:dependency_list_export, group: group, project: nil) }

    let(:service_class) { described_class.new(dependency_list_export) }

    subject(:dependencies) { service_class.execute.as_json }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'when the group does not have dependencies' do
      it { is_expected.to be_empty }
    end

    context 'when the group has dependencies' do
      before do
        project = create(:project, :public, group: group)

        create(:sbom_occurrence, project: project)
      end

      it { is_expected.not_to be_empty }
    end
  end
end
