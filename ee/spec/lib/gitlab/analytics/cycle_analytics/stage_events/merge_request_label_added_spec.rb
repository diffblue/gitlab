# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded do
  it_behaves_like 'value stream analytics event' do
    let(:label_id) { 10 }
    let(:params) { { label: GroupLabel.new(id: label_id) } }
    let(:expected_hash_code) { Digest::SHA256.hexdigest("#{instance.class.identifier}-#{label_id}") }
  end
end
