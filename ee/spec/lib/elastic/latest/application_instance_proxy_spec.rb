# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ApplicationInstanceProxy, feature_category: :global_search do
  let_it_be(:project) { create(:project, :in_subgroup) }
  let(:group) { project.group }
  let(:target) { project.repository }
  let(:included_class) { Elasticsearch::Model::Proxy::InstanceMethodsProxy }

  subject { included_class.new(target) }

  describe '#index_name' do
    subject { described_class.new(target, use_separate_indices: true) }

    let_it_be(:target) { create(:note) }
    let(:search_index) do
      # rubocop:disable RSpec/VerifiedDoubles
      double(:search_index, present?: search_index_present, paused?: search_index_paused, alias_name: 'alias-name')
      # rubocop:enable RSpec/VerifiedDoubles
    end

    let(:search_index_present) { true }
    let(:search_index_paused) { false }

    before do
      stub_const("Search::NoteIndex", :note_index) # https://gitlab.com/gitlab-org/gitlab/-/issues/393184
      allow(target).to receive(:search_index).and_return(search_index)
    end

    context 'when search index is valid' do
      it 'returns search index alias name' do
        expect(subject.index_name).to eq(search_index.alias_name)
      end
    end

    context 'when search index is missing' do
      let(:search_index_present) { false }

      it 'raises an error' do
        expect { subject.index_name }.to raise_error ArgumentError, /index assignment was missing/i
      end
    end

    context 'when search index is paused' do
      let(:search_index_paused) { true }

      it 'raises an error' do
        expect { subject.index_name }.to raise_error ArgumentError, /cannot write to paused index/i
      end
    end

    context 'when :search_index_partitioning_notes is disabled' do
      before do
        stub_feature_flags(search_index_partitioning_notes: false)
      end

      it 'returns config index_name' do
        expect(subject.index_name).to eq(Elastic::Latest::NoteConfig.index_name)
      end
    end
  end

  describe '#es_parent' do
    let(:target) { create(:merge_request) }

    it 'includes project id' do
      expect(subject.es_parent).to eq("project_#{target.project.id}")
    end

    context 'when target type is in routing excluded list' do
      let(:target) { project }

      it 'is nil' do
        expect(subject.es_parent).to be_nil
      end
    end
  end

  describe '#namespace_ancestry' do
    it 'returns the full ancestry' do
      expect(subject.namespace_ancestry).to eq("#{group.parent.id}-#{group.id}-")
    end
  end
end
