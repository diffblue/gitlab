# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DiscoverHelper do
  describe '#project_security_showcase_data' do
    let_it_be(:project) { create(:project) }

    subject(:project_security_showcase_data) do
      helper.project_security_showcase_data(project)
    end

    # rubocop: disable Layout/LineLength
    it 'builds correct hash' do
      expect(project_security_showcase_data)
        .to eq({
                 billing_container_scanning: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-container-scanning', glm_source: 'gitlab.com'),
                 billing_dast: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-dast', glm_source: 'gitlab.com'),
                 billing_dependency_scanning: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-dependency-scanning', glm_source: 'gitlab.com'),
                 billing_vulnerability_management: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-vulnerability-management', glm_source: 'gitlab.com'),
                 trial_vulnerability_management: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-vulnerability-management', glm_source: 'gitlab.com'),
                 trial_dependency_scanning: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-dependency-scanning', glm_source: 'gitlab.com'),
                 trial_dast: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-dast', glm_source: 'gitlab.com'),
                 trial_container_scanning: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-container-scanning', glm_source: 'gitlab.com')
               })
    end
  end

  describe '#project_security_discover_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    let(:content) { 'discover-project-security' }

    let(:expected_project_security_discover_data) do
      {
        project: {
          id: project.id,
          name: project.name,
          personal: "true"
        },
        link: {
          main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
          secondary: profile_billings_path(project.group, source: content)
        }
      }
    end

    subject(:project_security_discover_data) do
      helper.project_security_discover_data(project)
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      expect(project_security_discover_data).to eq(expected_project_security_discover_data)
    end
  end
end
