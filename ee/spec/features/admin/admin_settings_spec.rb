# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates EE-only settings' do
  include StubENV

  before do
    stub_feature_flags(bootstrap_confirmation_modals: false)
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    allow(License).to receive(:feature_available?).and_return(true)
    allow(Gitlab::Elastic::Helper.default).to receive(:index_exists?).and_return(true)
  end

  context 'Geo settings' do
    context 'when the license has Geo feature' do
      before do
        visit admin_geo_settings_path
      end

      it 'hides JS alert' do
        expect(page).not_to have_content("Geo is only available for users who have at least a Premium license.")
      end

      it 'renders JS form' do
        expect(page).to have_css("#js-geo-settings-form")
      end
    end

    context 'when the license does not have Geo feature' do
      before do
        allow(License).to receive(:feature_available?).and_return(false)
        visit admin_geo_settings_path
      end

      it 'shows JS alert' do
        expect(page).to have_content("Geo is only available for users who have at least a Premium license.")
      end
    end
  end

  it 'enables external authentication' do
    visit general_admin_application_settings_path
    page.within('.as-external-auth') do
      check 'Enable classification control using an external service'
      fill_in 'Default classification label', with: 'default'
      click_button 'Save changes'
    end

    expect(page).to have_content 'Application settings saved successfully'
  end

  context 'Elasticsearch settings', :elastic_delete_by_query do
    let(:elastic_search_license) { true }

    before do
      stub_licensed_features(elastic_search: elastic_search_license)
      visit advanced_search_admin_application_settings_path
    end

    it 'changes elasticsearch settings' do
      page.within('.as-elasticsearch') do
        check 'Elasticsearch indexing'
        check 'Search with Elasticsearch enabled'

        fill_in 'application_setting_elasticsearch_shards[gitlab-test]', with: '120'
        fill_in 'application_setting_elasticsearch_replicas[gitlab-test]', with: '2'
        fill_in 'application_setting_elasticsearch_shards[gitlab-test-issues]', with: '10'
        fill_in 'application_setting_elasticsearch_replicas[gitlab-test-issues]', with: '3'
        fill_in 'application_setting_elasticsearch_shards[gitlab-test-notes]', with: '20'
        fill_in 'application_setting_elasticsearch_replicas[gitlab-test-notes]', with: '4'
        fill_in 'application_setting_elasticsearch_shards[gitlab-test-merge_requests]', with: '15'
        fill_in 'application_setting_elasticsearch_replicas[gitlab-test-merge_requests]', with: '5'

        fill_in 'Maximum file size indexed (KiB)', with: '5000'
        fill_in 'Maximum field length', with: '100000'
        fill_in 'Maximum bulk request size (MiB)', with: '17'
        fill_in 'Bulk request concurrency', with: '23'
        fill_in 'Client request timeout', with: '30'

        click_button 'Save changes'
      end

      aggregate_failures do
        expect(current_settings.elasticsearch_indexing).to be_truthy
        expect(current_settings.elasticsearch_search).to be_truthy

        expect(current_settings.elasticsearch_shards).to eq(120)
        expect(current_settings.elasticsearch_replicas).to eq(2)
        expect(Elastic::IndexSetting['gitlab-test'].number_of_shards).to eq(120)
        expect(Elastic::IndexSetting['gitlab-test'].number_of_replicas).to eq(2)
        expect(Elastic::IndexSetting['gitlab-test-issues'].number_of_shards).to eq(10)
        expect(Elastic::IndexSetting['gitlab-test-issues'].number_of_replicas).to eq(3)
        expect(Elastic::IndexSetting['gitlab-test-notes'].number_of_shards).to eq(20)
        expect(Elastic::IndexSetting['gitlab-test-notes'].number_of_replicas).to eq(4)
        expect(Elastic::IndexSetting['gitlab-test-merge_requests'].number_of_shards).to eq(15)
        expect(Elastic::IndexSetting['gitlab-test-merge_requests'].number_of_replicas).to eq(5)

        expect(current_settings.elasticsearch_indexed_file_size_limit_kb).to eq(5000)
        expect(current_settings.elasticsearch_indexed_field_length_limit).to eq(100000)
        expect(current_settings.elasticsearch_max_bulk_size_mb).to eq(17)
        expect(current_settings.elasticsearch_max_bulk_concurrency).to eq(23)
        expect(current_settings.elasticsearch_client_request_timeout).to eq(30)
        expect(page).to have_content 'Application settings saved successfully'
      end
    end

    it 'allows limiting projects and namespaces to index', :aggregate_failures, :js do
      project = create(:project)
      namespace = create(:namespace)

      page.within('.as-elasticsearch') do
        expect(page).not_to have_content('Namespaces to index')
        expect(page).not_to have_content('Projects to index')

        check 'Limit the number of namespaces and projects that can be indexed.'

        expect(page).to have_content('Namespaces to index')
        expect(page).to have_content('Projects to index')

        fill_in 'Namespaces to index', with: namespace.path
        wait_for_requests
      end

      page.within('#select2-drop') do
        expect(page).to have_content(namespace.full_path)
      end

      page.within('.as-elasticsearch') do
        find('.js-limit-namespaces .select2-choices input[type=text]').native.send_keys(:enter)

        fill_in 'Projects to index', with: project.path
        wait_for_requests
      end

      page.within('#select2-drop') do
        expect(page).to have_content(project.name_with_namespace)
      end

      page.within('.as-elasticsearch') do
        find('.js-limit-projects .select2-choices input[type=text]').native.send_keys(:enter)

        click_button 'Save changes'
      end

      expect(current_settings.elasticsearch_limit_indexing).to be_truthy
      expect(ElasticsearchIndexedNamespace.exists?(namespace_id: namespace.id)).to be_truthy
      expect(ElasticsearchIndexedProject.exists?(project_id: project.id)).to be_truthy
    end

    it 'allows removing all namespaces and projects', :aggregate_failures, :js do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)

      namespace = create(:elasticsearch_indexed_namespace).namespace
      project = create(:elasticsearch_indexed_project).project

      visit advanced_search_admin_application_settings_path

      expect(ElasticsearchIndexedNamespace.count).to be > 0
      expect(ElasticsearchIndexedProject.count).to be > 0

      page.within('.as-elasticsearch') do
        expect(page).to have_content('Namespaces to index')
        expect(page).to have_content('Projects to index')
        expect(page).to have_content(namespace.full_path)
        expect(page).to have_content(project.full_path)

        find('.js-limit-namespaces .select2-search-choice-close').click
        find('.js-limit-projects .select2-search-choice-close').click

        expect(page).not_to have_content(namespace.full_path)
        expect(page).not_to have_content(project.full_path)

        click_button 'Save changes'
      end

      expect(ElasticsearchIndexedNamespace.count).to eq(0)
      expect(ElasticsearchIndexedProject.count).to eq(0)
      expect(page).to have_content 'Application settings saved successfully'
    end

    it 'zero-downtime reindexing shows popup', :js do
      page.within('.as-elasticsearch-reindexing') do
        expect(page).to have_content 'Trigger cluster reindexing'
        click_button 'Trigger cluster reindexing'
      end

      text = page.driver.browser.switch_to.alert.text
      expect(text).to eq 'Are you sure you want to reindex?'
      page.driver.browser.switch_to.alert.accept
    end

    context 'when not licensed' do
      let(:elastic_search_license) { false }

      it 'cannot access the page' do
        expect(page).not_to have_content("Advanced Search with Elasticsearch")
      end
    end
  end

  it 'enable Slack application' do
    allow(Gitlab).to receive(:com?).and_return(true)
    visit general_admin_application_settings_path

    page.within('.as-slack') do
      check 'Enable Slack application'
      click_button 'Save changes'
    end

    expect(page).to have_content 'Application settings saved successfully'
  end

  context 'Templates page' do
    before do
      visit templates_admin_application_settings_path
    end

    it 'render "Templates" section' do
      page.within('.as-visibility-access') do
        expect(page).to have_content 'Templates'
      end
    end

    it 'render "Custom project templates" section' do
      page.within('.as-custom-project-templates') do
        expect(page).to have_content 'Custom project templates'
      end
    end
  end

  describe 'LDAP settings' do
    before do
      allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(ldap_setting)

      visit general_admin_application_settings_path
    end

    context 'with LDAP enabled' do
      let(:ldap_setting) { true }

      it 'changes to allow group owners to manage ldap' do
        page.within('.as-visibility-access') do
          find('#application_setting_allow_group_owners_to_manage_ldap').set(false)
          click_button 'Save'
        end

        expect(page).to have_content('Application settings saved successfully')
        expect(find('#application_setting_allow_group_owners_to_manage_ldap')).not_to be_checked
      end
    end

    context 'with LDAP disabled' do
      let(:ldap_setting) { false }

      it 'does not show option to allow group owners to manage ldap' do
        expect(page).not_to have_css('#application_setting_allow_group_owners_to_manage_ldap')
      end
    end
  end

  context 'package registry settings' do
    before do
      visit ci_cd_admin_application_settings_path
    end

    it 'allows you to change the npm_forwarding setting' do
      page.within('#js-package-settings') do
        check 'Forward npm package requests to the npm Registry if the packages are not found in the GitLab Package Registry'
        click_button 'Save'
      end

      expect(current_settings.npm_package_requests_forwarding).to be true
    end

    it 'allows you to change the pypi_forwarding setting' do
      page.within('#js-package-settings') do
        check 'Forward PyPI package requests to the PyPI Registry if the packages are not found in the GitLab Package Registry'
        click_button 'Save'
      end

      expect(current_settings.pypi_package_requests_forwarding).to be true
    end
  end

  context 'sign up settings', :js do
    before do
      visit general_admin_application_settings_path
    end

    it 'changes the user cap from unlimited to 5' do
      expect(current_settings.new_user_signups_cap).to be_nil

      page.within('#js-signup-settings') do
        fill_in 'application_setting[new_user_signups_cap]', with: 5

        click_button 'Save changes'

        expect(current_settings.new_user_signups_cap).to eq(5)
      end
    end

    context 'with a user cap assigned' do
      before do
        current_settings.update_attribute(:new_user_signups_cap, 5)
      end

      it 'changes the user cap to unlimited' do
        page.within('#js-signup-settings') do
          fill_in 'application_setting[new_user_signups_cap]', with: nil

          click_button 'Save changes'

          expect(current_settings.new_user_signups_cap).to be_nil
        end
      end

      context 'with pending users' do
        before do
          create(:user, :blocked_pending_approval)
          visit general_admin_application_settings_path
        end

        it 'displays a modal confirmation when removing the cap' do
          page.within('#js-signup-settings') do
            fill_in 'application_setting[new_user_signups_cap]', with: nil

            click_button 'Save changes'
          end

          page.within('.modal') do
            click_button 'Approve 1 user'
          end

          expect(current_settings.new_user_signups_cap).to be_nil
        end
      end
    end

    context 'form submit button confirmation modal for side-effect of possibly adding unwanted new users' do
      [
        [:unchanged_true, :unchanged, false, :submits_form],
        [:unchanged_false, :unchanged, false, :submits_form],
        [:toggled_off, :unchanged, true, :shows_confirmation_modal],
        [:toggled_off, :unchanged, false, :submits_form],
        [:toggled_on, :unchanged, false, :submits_form],
        [:unchanged_false, :increased, true, :shows_confirmation_modal],
        [:unchanged_true, :increased, false, :submits_form],
        [:toggled_off, :increased, true, :shows_confirmation_modal],
        [:toggled_off, :increased, false, :submits_form],
        [:toggled_on, :increased, true, :shows_confirmation_modal],
        [:toggled_on, :increased, false, :submits_form],
        [:toggled_on, :decreased, false, :submits_form],
        [:toggled_on, :decreased, true, :submits_form],
        [:unchanged_false, :changed_from_limited_to_unlimited, true, :shows_confirmation_modal],
        [:unchanged_false, :changed_from_limited_to_unlimited, false, :submits_form],
        [:unchanged_false, :changed_from_unlimited_to_limited, false, :submits_form],
        [:unchanged_false, :unchanged_unlimited, false, :submits_form]
      ].each do |(require_admin_approval_action, user_cap_action, add_pending_user, button_effect)|
        it "#{button_effect} if 'require admin approval for new sign-ups' is #{require_admin_approval_action} and the user cap is #{user_cap_action} and #{add_pending_user ? "has" : "doesn't have"} pending user count" do
          user_cap_default = 5
          require_admin_approval_value = [:unchanged_true, :toggled_off].include?(require_admin_approval_action)

          current_settings.update_attribute(:require_admin_approval_after_user_signup, require_admin_approval_value)

          unless [:changed_from_unlimited_to_limited, :unchanged_unlimited].include?(user_cap_action)
            current_settings.update_attribute(:new_user_signups_cap, user_cap_default)
          end

          if add_pending_user
            create(:user, :blocked_pending_approval)
            visit general_admin_application_settings_path
          end

          page.within('#js-signup-settings') do
            case require_admin_approval_action
            when :toggled_on
              find('[data-testid="require-admin-approval-checkbox"]').set(true)
            when :toggled_off
              find('[data-testid="require-admin-approval-checkbox"]').set(false)
            end

            case user_cap_action
            when :increased
              fill_in 'application_setting[new_user_signups_cap]', with: user_cap_default + 1
            when :decreased
              fill_in 'application_setting[new_user_signups_cap]', with: user_cap_default - 1
            when :changed_from_limited_to_unlimited
              fill_in 'application_setting[new_user_signups_cap]', with: nil
            when :changed_from_unlimited_to_limited
              fill_in 'application_setting[new_user_signups_cap]', with: user_cap_default
            end

            click_button 'Save changes'
          end

          case button_effect
          when :shows_confirmation_modal
            expect(page).to have_selector('.modal')
            expect(page).to have_css('.modal .modal-body', text: 'By making this change, you will automatically approve 1 user who is pending approval.')
          when :submits_form
            expect(page).to have_content 'Application settings saved successfully'
          end
        end
      end
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
