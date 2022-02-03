# frozen_string_literal: true

module Projects::Security::DiscoverHelper
  def pql_three_cta_test_experiment_candidate?(namespace)
    experiment(:pql_three_cta_test, namespace: namespace) do |e|
      e.control { false }
      e.candidate { true }
    end.run
  end

  def project_security_discover_data(project)
    content = pql_three_cta_test_experiment_candidate?(project.root_ancestor) ? 'discover-project-security-pqltest' : 'discover-project-security'
    link_upgrade = project.personal? ? profile_billings_path(project.group, source: content) : group_billings_path(@project.root_ancestor, source: content)

    data = {
      project: {
        id: project.id,
        name: project.name
      },
      link: {
        main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
        secondary: link_upgrade
      }
    }

    data.merge(hand_raise_props(project.root_ancestor, glm_content: content))
  end
end
