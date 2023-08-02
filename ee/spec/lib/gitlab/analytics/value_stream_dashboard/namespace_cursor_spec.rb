# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::ValueStreamDashboard::NamespaceCursor, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup1) { create(:group, parent: group) }
  let_it_be(:subgroup2) { create(:group, parent: group) }
  let_it_be(:subsubgroup) { create(:group, parent: subgroup1) }

  let(:cursor_data) { { top_level_namespace_id: group.id } }

  let(:cursor) do
    described_class.new(
      namespace_class: Group,
      inner_namespace_query: ->(namespaces) { namespaces.select('id AS custom_column') },
      cursor_data: cursor_data
    )
  end

  subject(:namespace_ids) do
    [].tap do |namespaces|
      while namespace = cursor.next # rubocop: disable Lint/AssignmentInCondition
        namespaces << namespace
      end
    end.pluck(:custom_column)
  end

  it 'iterates over a namespace and transforms the yielded namespace relation' do
    expect(namespace_ids).to eq([group.id, subgroup1.id, subgroup2.id, subsubgroup.id])
  end

  context 'when continuing the iteration from a certain namespace id' do
    before do
      cursor_data[:namespace_id] = subgroup2.id
    end

    it 'selects the correct namespaces' do
      expect(namespace_ids).to eq([subgroup2.id, subsubgroup.id])
    end
  end

  context 'when top_level_namespace_id is missing' do
    let(:cursor_data) { {} }

    it 'raises error on initialize' do
      expect { cursor }.to raise_error(KeyError)
    end
  end
end
