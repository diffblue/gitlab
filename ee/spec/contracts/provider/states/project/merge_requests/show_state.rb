# frozen_string_literal: true

Pact.provider_states_for "MergeRequests#show" do
  provider_state "a merge request exists with suggested reviewers available for selection" do
    set_up do
      # Suggested Reviewers is a SaaS feature, but we can't use the `:saas` RSpec metadata like we do in other specs
      allow(::Gitlab).to receive(:com?).and_return(true)

      stub_licensed_features(suggested_reviewers: true)
      stub_feature_flags(suggested_reviewers_control: true)

      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, id: 12345, name: 'gitlab-qa', namespace: namespace)
      project.add_maintainer(user)
      project.project_setting.update!(suggested_reviewers_enabled: true)
      merge_request = create(:merge_request, iid: 54321, source_project: project, author: user)

      merge_request.build_predictions
      merge_request.predictions.update!(suggested_reviewers: { reviewers: [user.username] })
    end
  end
end
