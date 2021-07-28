# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSetting do
  it { is_expected.to belong_to(:push_rule) }

  describe '.has_vulnerabilities' do
    let_it_be(:setting_1) { create(:project_setting, :has_vulnerabilities) }
    let_it_be(:setting_2) { create(:project_setting) }

    subject { described_class.has_vulnerabilities }

    it { is_expected.to contain_exactly(setting_1) }
  end
end
