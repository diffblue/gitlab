# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::Approval do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:deployment) }
  end

  describe 'validations' do
    subject { create(:deployment_approval) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:deployment_id) }
    it { is_expected.to validate_presence_of(:deployment) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_length_of(:comment).is_at_most(255) }
  end
end
