# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelogs::CreateService do
  let_it_be(:author) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:time_spent) { 3600 }
  let_it_be(:spent_at) { "2022-07-08" }
  let_it_be(:summary) { "Test summary" }

  let(:issuable) { nil }
  let(:users_container) { group }
  let(:service) { described_class.new(issuable, time_spent, spent_at, summary, user) }

  describe '#execute' do
    subject { service.execute }

    context 'when issuable is an Epic' do
      let_it_be(:issuable) { create(:epic, group: group) }

      it_behaves_like 'issuable does not support timelog creation service'
    end
  end
end
