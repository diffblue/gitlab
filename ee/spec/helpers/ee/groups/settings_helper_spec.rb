# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Groups::SettingsHelper do
  include AdminModeHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }

  describe('#delayed_project_removal_help_text') do
    using RSpec::Parameterized::TableSyntax

    settings_path = '/admin/application_settings/general#js-visibility-settings'

    where(:is_admin, :expected) do
      true  | "Projects will be permanently deleted after a 7-day delay. This delay can be <a href=\"#{settings_path}\">customized by an admin</a> in instance settings. Inherited by subgroups."
      false | 'Projects will be permanently deleted after a 7-day delay. Inherited by subgroups.'
    end

    with_them do
      before do
        stub_application_setting(deletion_adjourned_period: 7)
        allow(helper).to receive(:general_admin_application_settings_path).with(anchor: 'js-visibility-settings').and_return(settings_path)

        if is_admin
          allow(helper).to receive(:current_user).and_return(admin)
          enable_admin_mode!(admin)
        else
          allow(helper).to receive(:current_user).and_return(user)
        end
      end

      it "returns expected helper text" do
        expect(helper.delayed_project_removal_help_text).to eq expected
      end
    end
  end
end
