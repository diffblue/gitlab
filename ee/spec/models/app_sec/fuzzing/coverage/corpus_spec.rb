# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::Corpus, type: :model do
  let(:corpus) { create(:corpus) }

  subject { corpus }

  describe 'associations' do
    it { is_expected.to belong_to(:package).class_name('Packages::Package') }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:project) }
  end
end
