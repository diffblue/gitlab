# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingLink, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').inverse_of(:finding_links) }
  end

  describe 'validations' do
    let_it_be(:link) { create(:finding_link) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_length_of(:url).is_at_most(2048) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:finding) }
  end
end
