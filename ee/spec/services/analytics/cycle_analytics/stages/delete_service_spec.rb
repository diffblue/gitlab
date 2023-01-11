# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stages::DeleteService do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:value_stream, refind: true) { create(:cycle_analytics_value_stream, namespace: group) }
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:stage, refind: true) { create(:cycle_analytics_stage, namespace: group, value_stream: value_stream) }

  let(:params) { { id: stage.id } }

  subject { described_class.new(parent: group, params: params, current_user: user).execute }

  before_all do
    group.add_member(user, :reporter)
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  it_behaves_like 'permission check for Value Stream Analytics Stage services', :cycle_analytics_for_groups

  context 'when persisted stage is given' do
    it { expect(subject).to be_success }

    it 'deletes the stage' do
      subject

      expect(group.cycle_analytics_stages.find_by(id: stage.id)).to be_nil
    end
  end

  context 'disallows deletion when default stage is given' do
    let_it_be(:stage, refind: true) { create(:cycle_analytics_stage, namespace: group, custom: false, value_stream: value_stream) }

    it { expect(subject).not_to be_success }
    it { expect(subject.http_status).to eq(:forbidden) }
  end
end
