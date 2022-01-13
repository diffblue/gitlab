# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Training do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:provider).required }
  end

  describe 'validations' do
    describe 'one primary per project' do
      context 'when the training is primary' do
        subject { create(:security_training, :primary) }

        it { is_expected.to validate_uniqueness_of(:project_id) }
      end

      context 'when the training is not primary' do
        subject { create(:security_training) }

        it { is_expected.not_to validate_uniqueness_of(:project_id) }
      end
    end
  end
end
