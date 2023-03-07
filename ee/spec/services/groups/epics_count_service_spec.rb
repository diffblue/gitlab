# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicsCountService, :use_clean_rails_memory_store_caching,
  feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:epic) { create(:epic, group: group) }

  subject { described_class.new(group, user) }

  describe '#relation_for_count' do
    before do
      group.add_reporter(user)
      allow(EpicsFinder).to receive(:new).and_call_original
    end

    it 'uses the EpicsFinder to scope epics' do
      expect(EpicsFinder)
        .to receive(:new)
        .with(user, group_id: group.id, state: 'opened')

      subject.count
    end
  end

  it_behaves_like 'a counter caching service with threshold'
end
