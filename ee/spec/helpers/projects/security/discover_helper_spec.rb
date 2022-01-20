# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DiscoverHelper do
  describe '#project_security_discover_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:variant) { :control }
    let(:content) { 'discover-project-security' }
    let(:expected_project_security_discover_data) do
      {
        project: {
          id: project.id,
          name: project.name
        },
        link: {
          main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
          secondary: profile_billings_path(project.group, source: content)
        }
      }.merge(helper.hand_raise_props(project.root_ancestor))
    end

    subject(:project_security_discover_data) do
      helper.project_security_discover_data(project)
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
      stub_experiments(pql_three_cta_test: variant)
    end

    it 'builds correct hash' do
      expect(project_security_discover_data).to eq(expected_project_security_discover_data)
    end

    context 'candidate for pql_three_cta_test' do
      let(:variant) { :candidate }
      let(:content) { 'discover-project-security-pqltest' }

      it 'renders a hash with pqltest content' do
        expect(project_security_discover_data).to eq(expected_project_security_discover_data)
      end
    end
  end
end
