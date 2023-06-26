# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TierBadgeExperiment, :experiment, feature_category: :experimentation_conversion do
  subject { described_class.new(namespace: group) }

  let!(:group) { create(:group) }

  it 'excludes groups that are not created 14 days ago at the time of evaluation' do
    expect(subject).to exclude(namesapce: group)
  end

  it 'does not exclude groups that are created 14 days ago at the time of evaluation' do
    travel_to(14.days.from_now) do
      expect(subject).not_to exclude(namesapce: group)
    end
  end
end
