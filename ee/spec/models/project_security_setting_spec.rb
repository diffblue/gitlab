# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSecuritySetting, feature_category: :software_composition_analysis do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    subject { create(:project).security_setting }

    it { is_expected.to belong_to(:project) }
  end

  describe '#auto_fix_enabled?' do
    subject { setting.auto_fix_enabled? }

    let(:setting) { build(:project_security_setting) }

    where(:license, :feature_flag, :auto_fix_container_scanning, :auto_fix_dependency_scanning, :auto_fix_sast, :auto_fix_enabled?) do
      true   | true  | true  | true  | true  | true
      false  | true  | true  | true  | true  | false
      true   | false | true  | true  | true  | false
      true   | true  | false | true  | true  | true
      true   | true  | true  | false | true  | true
      true   | true  | false | false | true  | false
      true   | true  | true  | true  | false | true
    end

    with_them do
      before do
        stub_licensed_features(vulnerability_auto_fix: license)
        stub_feature_flags(security_auto_fix: feature_flag)

        setting.auto_fix_container_scanning = auto_fix_container_scanning
        setting.auto_fix_dependency_scanning = auto_fix_dependency_scanning
        setting.auto_fix_sast = auto_fix_sast
      end

      it { is_expected.to eq(auto_fix_enabled?) }
    end
  end

  describe '#auto_fix_enabled_types' do
    subject { setting.auto_fix_enabled_types }

    let_it_be(:setting) { build(:project_security_setting) }

    before do
      setting.auto_fix_container_scanning = false
      setting.auto_fix_dependency_scanning = true
      setting.auto_fix_sast = true
    end

    it 'return status only for available types' do
      is_expected.to eq([:dependency_scanning])
    end
  end

  describe '#set_continuous_vulnerability_scans' do
    where(:value_before, :enabled, :value_after) do
      true  | false | false
      true  | true  | true
      false | true  | true
      false | false | false
    end

    with_them do
      let(:setting) { create(:project_security_setting, continuous_vulnerability_scans_enabled: value_before) }

      it 'updates the attribute and returns the new value' do
        expect(setting.set_continuous_vulnerability_scans!(enabled: enabled)).to eq(value_after)
        expect(setting.reload.continuous_vulnerability_scans_enabled).to eq(value_after)
      end
    end
  end
end
