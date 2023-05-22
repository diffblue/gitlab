# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::CurrentNodeCheck, :geo, :silence_stdout, feature_category: :geo_replication do
  describe '#check?' do
    context 'when the current machine has a matching GeoNode' do
      it 'returns true' do
        create(:geo_node, :primary, name: GeoNode.current_node_name)

        expect(subject.check?).to be_truthy
      end
    end

    context 'when the current machine does not have a matching GeoNode' do
      it 'returns false' do
        expect(GeoNode).to receive(:current_node_name).and_return('Foo')

        expect(subject.check?).to be_falsey
      end
    end
  end

  describe '.check_pass' do
    it 'outputs additional helpful info', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/411332' do
      allow(GeoNode).to receive(:current_node_name).and_return('Foo')
      create(:geo_node, :primary, name: GeoNode.current_node_name)

      expect(described_class.check_pass).to eq('yes, found a primary node named "Foo"')
    end
  end
end
