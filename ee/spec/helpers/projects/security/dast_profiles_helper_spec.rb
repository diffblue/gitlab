# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastProfilesHelper do
  let_it_be(:project) { create(:project) }

  before do
    allow(project).to receive(:path_with_namespace).and_return("foo/bar")
  end

  describe '#dast_profiles_list_data' do
    let_it_be(:timezones) { [{ identifier: "Europe/Paris" }] }

    before do
      allow(helper).to receive(:timezone_data).with(format: :abbr).and_return(timezones)
    end

    it 'returns proper data' do
      expect(helper.dast_profiles_list_data(project)).to eq(
        {
          'new_dast_site_profile_path' => "/#{project.full_path}/-/security/configuration/profile_library/dast_site_profiles/new",
          'new_dast_scanner_profile_path' => "/#{project.full_path}/-/security/configuration/profile_library/dast_scanner_profiles/new",
          'project_full_path' => "foo/bar",
          'timezones' => timezones.to_json
        }
      )
    end
  end

  shared_examples 'passes on-demand scan edit path when from_on_demand_scan_id param is present' do
    before do
      allow(helper).to receive(:params).and_return({ from_on_demand_scan_id: '1' })
    end

    it 'returns edit path as on_demand_scan_form_path' do
      expect(subject[:on_demand_scan_form_path]).to eq(
        "/#{project.full_path}/-/on_demand_scans/1/edit"
      )
    end
  end

  describe "#dast_scanner_profile_form_data" do
    subject { helper.dast_scanner_profile_form_data(project) }

    before do
      allow(helper).to receive(:params).and_return({})
    end

    it 'returns proper data' do
      expect(subject).to eq(
        {
          project_full_path: "foo/bar",
          on_demand_scan_form_path: "/#{project.full_path}/-/on_demand_scans/new",
          dast_configuration_path: "/#{project.full_path}/-/security/configuration/dast",
          profiles_library_path: "/#{project.full_path}/-/security/configuration/profile_library#scanner-profiles"
        }
      )
    end

    it_behaves_like 'passes on-demand scan edit path when from_on_demand_scan_id param is present'
  end

  describe "#edit_dast_scanner_profile_form_data" do
    subject { helper.edit_dast_scanner_profile_form_data(project, scanner_profile) }

    let_it_be(:scanner_profile) { create(:dast_scanner_profile, project: project) }

    before do
      allow(helper).to receive(:params).and_return({})
    end

    it 'returns proper data' do
      expect(subject).to eq(
        {
          project_full_path: "foo/bar",
          on_demand_scan_form_path: "/#{project.full_path}/-/on_demand_scans/new",
          dast_configuration_path: "/#{project.full_path}/-/security/configuration/dast",
          profiles_library_path: "/#{project.full_path}/-/security/configuration/profile_library#scanner-profiles",
          scanner_profile: {
            id: scanner_profile.to_global_id.to_s,
            profile_name: scanner_profile.name,
            spider_timeout: scanner_profile.spider_timeout,
            target_timeout: scanner_profile.target_timeout,
            scan_type: scanner_profile.scan_type.upcase,
            use_ajax_spider: scanner_profile.use_ajax_spider,
            show_debug_messages: scanner_profile.show_debug_messages,
            referenced_in_security_policies: scanner_profile.referenced_in_security_policies
          }.to_json
        }
      )
    end

    it_behaves_like 'passes on-demand scan edit path when from_on_demand_scan_id param is present'
  end

  describe "#dast_site_profile_form_data" do
    subject { helper.dast_site_profile_form_data(project) }

    before do
      allow(helper).to receive(:params).and_return({})
    end

    it 'returns proper data' do
      expect(subject).to eq(
        {
          project_full_path: "foo/bar",
          on_demand_scan_form_path: "/#{project.full_path}/-/on_demand_scans/new",
          dast_configuration_path: "/#{project.full_path}/-/security/configuration/dast",
          profiles_library_path: "/#{project.full_path}/-/security/configuration/profile_library#site-profiles"
        }
      )
    end

    it_behaves_like 'passes on-demand scan edit path when from_on_demand_scan_id param is present'
  end

  describe "#edit_dast_site_profile_form_data" do
    subject { helper.edit_dast_site_profile_form_data(project, site_profile) }

    let_it_be(:site_profile) { create(:dast_site_profile, project: project) }

    before do
      allow(helper).to receive(:params).and_return({})
    end

    it 'returns proper data' do
      expect(subject).to eq(
        {
          project_full_path: "foo/bar",
          on_demand_scan_form_path: "/#{project.full_path}/-/on_demand_scans/new",
          dast_configuration_path: "/#{project.full_path}/-/security/configuration/dast",
          profiles_library_path: "/#{project.full_path}/-/security/configuration/profile_library#site-profiles",
          site_profile: site_profile.to_json
        }
      )
    end

    it_behaves_like 'passes on-demand scan edit path when from_on_demand_scan_id param is present'
  end
end
