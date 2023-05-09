# frozen_string_literal: true

RSpec.shared_examples 'a restricted project approval rule API endpoint' do
  context 'when admin_merge_request_approvers_rules license feature is disabled' do
    before do
      stub_licensed_features(admin_merge_request_approvers_rules: false)
    end

    context 'when disable_overriding_approvers_per_merge_request app setting is false' do
      before do
        stub_application_setting(disable_overriding_approvers_per_merge_request: false)
      end

      it_behaves_like 'a user without access'
    end

    context 'when disable_overriding_approvers_per_merge_request app setting is true' do
      before do
        stub_application_setting(disable_overriding_approvers_per_merge_request: true)
      end

      it_behaves_like 'a user without access'
    end
  end

  context 'when admin_merge_request_approvers_rules license feature is enabled' do
    before do
      stub_licensed_features(admin_merge_request_approvers_rules: true)
    end

    context 'when disable_overriding_approvers_per_merge_request app setting is false' do
      before do
        stub_application_setting(disable_overriding_approvers_per_merge_request: false)
      end

      it_behaves_like 'a user with access'
    end

    context 'when disable_overriding_approvers_per_merge_request app setting is true' do
      before do
        stub_application_setting(disable_overriding_approvers_per_merge_request: true)
      end

      it_behaves_like 'a user without access'

      context 'when user is an admin' do
        let(:current_user) { create(:admin) }

        it_behaves_like 'a user with access'
      end
    end
  end
end

RSpec.shared_examples 'an API endpoint for creating project approval rule' do
  let(:current_user) { user }
  let(:params) do
    {
      name: 'security',
      approvals_required: 10
    }
  end

  shared_examples_for 'a user with access' do
    it 'returns 201 status' do
      post api(url, current_user, admin_mode: current_user.admin?), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema(schema, dir: 'ee')
    end
  end

  shared_examples_for 'a user without access' do
    it 'returns 403' do
      post api(url, current_user), params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  it_behaves_like 'a restricted project approval rule API endpoint'

  before do
    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  context 'when missing parameters' do
    it 'returns 400 status' do
      post api(url, current_user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'when user is without access' do
    it_behaves_like 'a user without access' do
      let(:current_user) { user2 }
    end
  end

  context 'when the request is correct' do
    it_behaves_like 'a user with access'

    it 'changes settings properly' do
      create(:approval_project_rule, project: project, approvals_required: 2)

      project.reset_approvals_on_push = false
      project.disable_overriding_approvers_per_merge_request = true
      project.save!

      post api(url, current_user), params: params

      expect(json_response.symbolize_keys).to include(params)
    end

    context 'when protected_branch_ids param is present' do
      let(:protected_branches) { Array.new(2).map { create(:protected_branch, project: project) } }

      before do
        stub_licensed_features(admin_merge_request_approvers_rules: true, multiple_approval_rules: true)
        post api(url, current_user), params: params.merge(protected_branch_ids: protected_branches.map(&:id))
      end

      it 'creates approval rule associated to specified protected branches' do
        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['protected_branches']).to contain_exactly(
          a_hash_including('id' => protected_branches.first.id),
          a_hash_including('id' => protected_branches.last.id)
        )
      end
    end

    context 'when applies_to_all_protected_branches param is present' do
      let(:protected_branches) { create_list(:protected_branch, 2, project: project) }

      before do
        stub_licensed_features(admin_merge_request_approvers_rules: true, multiple_approval_rules: true)
        post api(url, current_user), params: params.merge(applies_to_all_protected_branches: true)
      end

      it 'returns a list of project protected branches in the response' do
        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['protected_branches']).to contain_exactly(*project.protected_branches)
        expect(json_response['applies_to_all_protected_branches']).to eq(true)
      end
    end

    context 'with rule_type set to report_approver' do
      before do
        params.merge!(rule_type: :report_approver)
      end

      context 'without report_type' do
        it 'returns a error http status' do
          expect do
            post api(url, current_user), params: params.merge(name: 'License-Check')
          end.not_to change { ApprovalProjectRule.report_approver.count }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when creating a approval rule for each report_type' do
        using RSpec::Parameterized::TableSyntax

        where(:rule_name, :report_type) do
          'License-Check'       | :license_scanning
          'Coverage-Check'      | :code_coverage
        end

        with_them do
          it 'specifies `report_rule` and `report_type`' do
            expect do
              post api(url, current_user), params: params.merge(name: rule_name, report_type: report_type)
            end.to change { ApprovalProjectRule.report_approver.count }.from(0).to(1)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end
    end

    context 'with valid scanners' do
      let(:scanners) { ['sast'] }

      it 'returns 201 status' do
        expect do
          post api(url, current_user), params: params.merge({ scanners: scanners })
        end.to change { project.approval_rules.count }.from(0).to(1)
        expect(response).to have_gitlab_http_status(:created)
        expect(project.approval_rules.first.scanners).to eql(scanners)
      end
    end

    context 'with valid severity_levels' do
      let(:severity_levels) { ['critical'] }

      it 'returns 201 status' do
        expect do
          post api(url, current_user), params: params.merge({ severity_levels: severity_levels })
        end.to change { project.approval_rules.count }.from(0).to(1)
        expect(response).to have_gitlab_http_status(:created)
        expect(project.approval_rules.first.severity_levels).to eql(severity_levels)
      end
    end

    context 'with username' do
      let(:approvals_usernames) { [user2.username] }

      before do
        project.add_developer(user2)
      end

      it 'returns 201 status' do
        post api(url, current_user), params: params.merge!({ usernames: approvals_usernames })

        expect(response).to have_gitlab_http_status(:created)
        expect(project.approval_rules.first.users).to contain_exactly(user2)
      end
    end
  end

  context 'with vulnerabilities_allowed' do
    let(:vulnerabilities_allowed) { 10 }

    it 'returns 201 status' do
      expect do
        post api(url, current_user), params: params.merge({ vulnerabilities_allowed: vulnerabilities_allowed })
      end.to change { project.approval_rules.count }.from(0).to(1)
      expect(response).to have_gitlab_http_status(:created)
      expect(project.approval_rules.first.vulnerabilities_allowed).to eql(vulnerabilities_allowed)
    end
  end
end

RSpec.shared_examples 'an API endpoint for updating project approval rule' do
  let(:params) { {} }

  shared_examples 'a user with access' do
    before do
      project.add_developer(approver)
      project.add_developer(other_approver)
    end

    context 'when applies_to_all_protected_branches param is present' do
      let(:protected_branches) { create_list(:protected_branch, 2, project: project) }

      before do
        stub_licensed_features(admin_merge_request_approvers_rules: true, multiple_approval_rules: true)
        put api(url, current_user, admin_mode: current_user.admin?), params: params.merge(applies_to_all_protected_branches: true)
      end

      it 'returns a list of project protected branches in the response' do
        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['protected_branches']).to contain_exactly(*project.protected_branches)
        expect(json_response['applies_to_all_protected_branches']).to eq(true)
      end
    end

    context 'when protected_branch_ids param is present' do
      let(:protected_branches) { Array.new(2).map { create(:protected_branch, project: project) } }

      before do
        stub_licensed_features(admin_merge_request_approvers_rules: true, multiple_approval_rules: true)
        put api(url, current_user, admin_mode: current_user.admin?), params: { protected_branch_ids: protected_branches.map(&:id) }
      end

      it 'associates approval rule to specified protected branches' do
        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['protected_branches']).to contain_exactly(
          a_hash_including('id' => protected_branches.first.id),
          a_hash_including('id' => protected_branches.last.id)
        )
      end
    end

    context 'with valid scanners' do
      let(:scanners) { ['sast'] }

      it 'returns 200 status' do
        expect do
          put api(url, current_user, admin_mode: current_user.admin?), params: { scanners: scanners }
        end.to change { approval_rule.reload.scanners.count }.from(0).to(scanners.count)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with nil scanners' do
      let(:scanners) { nil }

      it 'returns 200 status' do
        expect do
          put api(url, current_user, admin_mode: current_user.admin?), params: { scanners: scanners }
        end.not_to change { approval_rule.reload.scanners }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when scanners is NULL in the database' do
      let(:vulnerabilities_allowed) { 10 }

      before do
        approval_rule.update_column(:scanners, nil)
      end

      it 'returns 200 status' do
        expect do
          put api(url, current_user, admin_mode: current_user.admin?), params: { vulnerabilities_allowed: vulnerabilities_allowed }
        end.not_to change { approval_rule.reload.scanners }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with valid severity_levels' do
      let(:severity_levels) { ['critical'] }

      it 'returns 200 status' do
        expect do
          put api(url, current_user, admin_mode: current_user.admin?), params: { severity_levels: severity_levels }
        end.to change { approval_rule.reload.severity_levels.count }.from(::ApprovalProjectRule::DEFAULT_SEVERITIES.count).to(severity_levels.count)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when approver already exists' do
      before do
        approval_rule.users << approver
        approval_rule.groups << group
      end

      context 'when sending json data' do
        it 'removes all approvers if empty params are given' do
          expect do
            put api(url, current_user, admin_mode: current_user.admin?), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
          end.to change { approval_rule.users.count + approval_rule.groups.count }.from(2).to(0)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema(schema, dir: 'ee')
        end
      end
    end

    it 'sets approvers' do
      expect do
        put api(url, current_user, admin_mode: current_user.admin?), params: { users: "#{approver.id},#{other_approver.id}" }
      end.to change { approval_rule.users.count }.from(0).to(2)

      expect(approval_rule.users).to contain_exactly(approver, other_approver)
      expect(approval_rule.groups).to be_empty

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with vulnerabilities_allowed' do
      let(:vulnerabilities_allowed) { 10 }

      it 'returns 200 status' do
        expect do
          put api(url, current_user, admin_mode: current_user.admin?), params: { vulnerabilities_allowed: vulnerabilities_allowed }
        end.to change { approval_rule.reload.vulnerabilities_allowed }.from(0).to(vulnerabilities_allowed)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  shared_examples_for 'a user without access' do
    it 'returns 403' do
      project.approvers.create!(user: approver)

      expect do
        put api(url, current_user), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
      end.not_to change { approval_rule.approvers.size }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  before do
    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  it_behaves_like 'a restricted project approval rule API endpoint' do
    let(:current_user) { user }
    let(:visible_approver_groups_count) { 0 }
  end

  context 'as a project admin' do
    it_behaves_like 'a user with access' do
      let(:current_user) { user }
      let(:visible_approver_groups_count) { 0 }
    end
  end

  context 'as a global admin' do
    it_behaves_like 'a user with access' do
      let(:current_user) { admin }
      let(:visible_approver_groups_count) { 1 }
    end
  end

  context 'as a random user' do
    it_behaves_like 'a user without access' do
      let(:current_user) { user2 }
    end
  end
end

RSpec.shared_examples 'an API endpoint for deleting project approval rule' do
  let(:current_user) { user }

  shared_examples_for 'a user with access' do
    it 'destroys' do
      delete api(url, current_user, admin_mode: current_user.admin?)

      expect(ApprovalProjectRule.exists?(id: approval_rule.id)).to eq(false)
      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  shared_examples_for 'a user without access' do
    it 'returns 403' do
      delete api(url, current_user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  before do
    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  it_behaves_like 'a user with access'
  it_behaves_like 'a restricted project approval rule API endpoint'

  context 'when approval rule not found' do
    let!(:approval_rule_2) { create(:approval_project_rule) }
    let(:url) { "/projects/#{project.id}/approval_settings/#{approval_rule_2.id}" }

    it 'returns not found' do
      delete api(url, user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when user is not eligible to delete' do
    it_behaves_like 'a user without access' do
      let(:current_user) { user2 }
    end
  end
end
