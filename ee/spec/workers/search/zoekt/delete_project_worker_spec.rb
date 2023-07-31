# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::DeleteProjectWorker, feature_category: :global_search do
  let(:root_namespace_id) { 10 }
  let(:project_id) { 128 }

  describe '#perform' do
    subject { described_class.new.perform(root_namespace_id, project_id) }

    it 'executes delete_zoekt_index!' do
      expect(::Gitlab::Search::Zoekt::Client).to receive(:delete)
                              .with(root_namespace_id: root_namespace_id, project_id: project_id)

      subject
    end

    context 'when zoekt indexing is disabled' do
      before do
        stub_feature_flags(index_code_with_zoekt: false)
      end

      it 'does nothing' do
        expect(::Gitlab::Search::Zoekt::Client).not_to receive(:delete)

        subject
      end
    end
  end
end
