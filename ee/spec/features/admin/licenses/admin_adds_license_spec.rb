# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin add license", :js, feature_category: :sm_provisioning do
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    # It's important to set this variable so that we don't save a memoized
    # (supposed to be) in-memory record in `Gitlab::CurrentSettings.in_memory_application_settings`
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'default state' do
    before do
      visit(general_admin_application_settings_path)
    end

    it 'has the correct headline' do
      expect(page).to have_content("Add License")
    end

    it 'has unselected EULA checkbox by default' do
      expect(page).to have_unchecked_field('accept_eula')
    end

    it 'has disabled button "Add license" by default' do
      expect(page).to have_button('Add license', disabled: true)
    end

    it 'redirects to current Subscription terms' do
      expect(page).to have_link('Terms of Service', href: "https://#{ApplicationHelper.promo_host}/terms/#subscription")
    end

    it 'enables button "Add license" when EULA checkbox is selected' do
      expect(page).to have_button('Add license', disabled: true)

      check('accept_eula')

      expect(page).to have_button('Add license', disabled: false)
    end
  end

  context "uploading license" do
    before do
      visit(general_admin_application_settings_path)

      File.write(path, new_license.export)
    end

    shared_examples 'active navigation item' do
      it 'activates the "Settings General" navigation item' do
        expect(find('.sidebar-top-level-items > li.active')).to have_content('Settings')
        expect(find('.sidebar-top-level-items > li.active')).to have_content('General')
      end
    end

    context "when license is valid" do
      let_it_be(:path) { Rails.root.join("tmp/valid_license.gitlab-license") }

      context "when license is active immediately" do
        let_it_be(:new_license) { build(:gitlab_license) }

        it_behaves_like 'active navigation item'

        it "uploads license" do
          attach_and_upload(path)

          expect(page).to have_content("The license was successfully uploaded and is now active.")
                    .and have_content(new_license.licensee.each_value.first)
        end
      end

      context "when license starts in the future" do
        let_it_be(:new_license) { build(:gitlab_license, starts_at: Date.current + 1.month) }

        context "when a current license exists" do
          it_behaves_like 'active navigation item'

          it "uploads license" do
            attach_and_upload(path)

            expect(page)
              .to have_content("The license was successfully uploaded and will be active from "\
                "#{new_license.starts_at}. You can see the details below.")
              .and have_content(new_license.licensee.each_value.first)
          end
        end

        context "when no current license exists" do
          before do
            allow(License).to receive(:current).and_return(nil)
          end

          it_behaves_like 'active navigation item'

          it "uploads license" do
            attach_and_upload(path)

            expect(page)
              .to have_content("The license was successfully uploaded and will be active from "\
              "#{new_license.starts_at}. You can see the details below.")
          end
        end
      end
    end

    context "when license is invalid" do
      let_it_be(:new_license) { build(:gitlab_license, expires_at: Date.yesterday) }
      let_it_be(:path) { Rails.root.join("tmp/invalid_license.gitlab-license") }

      it_behaves_like 'active navigation item'

      it "doesn't upload license" do
        attach_and_upload(path)

        expect(page).to have_content("This license has already expired.")
      end
    end
  end

  private

  def attach_and_upload(path)
    attach_file("license[data_file]", path, make_visible: true)
    check("accept_eula")
    click_button("Add license")
  end
end
