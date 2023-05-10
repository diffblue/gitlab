# frozen_string_literal: true

module Projects::Security::DiscoverHelper
  def project_security_showcase_data(project)
    {
      billing_vulnerability_management: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-vulnerability-management', glm_source: 'gitlab.com'),
      billing_dependency_scanning: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-dependency-scanning', glm_source: 'gitlab.com'),
      billing_dast: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-dast', glm_source: 'gitlab.com'),
      billing_container_scanning: group_billings_path(project.root_ancestor, glm_content: 'security-showcase-container-scanning', glm_source: 'gitlab.com'),
      trial_vulnerability_management: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-vulnerability-management', glm_source: 'gitlab.com'),
      trial_dependency_scanning: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-dependency-scanning', glm_source: 'gitlab.com'),
      trial_dast: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-dast', glm_source: 'gitlab.com'),
      trial_container_scanning: new_trial_registration_path(project.root_ancestor, glm_content: 'security-showcase-container-scanning', glm_source: 'gitlab.com')
    }
  end

  def project_security_discover_data(project)
    content = 'discover-project-security'
    link_upgrade = project.personal? ? profile_billings_path(project.group, source: content) : group_billings_path(project.root_ancestor, source: content)

    {
      project: {
        id: project.id,
        name: project.name,
        personal: project.personal?.to_s
      },
      link: {
        main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
        secondary: link_upgrade
      }
    }
  end
end
