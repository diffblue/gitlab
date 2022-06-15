# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Groups::SettingsHelper do
  describe('#delayed_project_removal_help_text') do
    using RSpec::Parameterized::TableSyntax

    where(:admin_only, :expected) do
      true  | 'Only administrators can delete projects.'
      false | 'Owners and administrators can delete projects.'
    end

    with_them do
      before do
        stub_application_setting(default_project_deletion_protection: admin_only)
      end

      it "returns expected helper text" do
        expect(helper.delayed_project_removal_help_text).to eq expected
      end
    end
  end

  describe('#keep_deleted_option_label') do
    using RSpec::Parameterized::TableSyntax

    where(:adjourned_period, :expected) do
      1 | 'Keep deleted projects for 1 day'
      4 | 'Keep deleted projects for 4 days'
    end

    with_them do
      before do
        stub_application_setting(deletion_adjourned_period: adjourned_period)
      end

      it "returns expected helper text" do
        expect(helper.keep_deleted_option_label).to eq expected
      end
    end
  end
end
