# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelogs::CreateService, feature_category: :team_planning do
  let_it_be(:author) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:issuable) { nil }
  let(:users_container) { group }

  describe '#execute' do
    subject { service.execute }

    context 'when issuable is an Epic' do
      let_it_be(:issuable) { create(:epic, group: group) }

      it_behaves_like 'issuable does not support timelog creation service'
    end
  end
end
