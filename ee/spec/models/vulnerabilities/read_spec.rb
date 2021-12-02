# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Read, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
  end

  describe 'validations' do
    let!(:vulnerability_read) { create(:vulnerability_read) }

    it { is_expected.to validate_presence_of(:vulnerability_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:scanner_id) }
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_length_of(:location_image).is_at_most(2048) }

    it { is_expected.to validate_uniqueness_of(:vulnerability_id) }
    it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }

    it { is_expected.to allow_value(true).for(:has_issues) }
    it { is_expected.to allow_value(false).for(:has_issues) }
    it { is_expected.not_to allow_value(nil).for(:has_issues) }

    it { is_expected.to allow_value(true).for(:resolved_on_default_branch) }
    it { is_expected.to allow_value(false).for(:resolved_on_default_branch) }
    it { is_expected.not_to allow_value(nil).for(:resolved_on_default_branch) }
  end
end
