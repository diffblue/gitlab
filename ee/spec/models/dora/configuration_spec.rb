# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::Configuration, type: :model do
  subject { build :dora_configuration }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_uniqueness_of(:project_id) }
  it { is_expected.to allow_value([]).for(:branches_for_lead_time_for_changes) }
  it { is_expected.not_to allow_value(nil).for(:branches_for_lead_time_for_changes) }
end
