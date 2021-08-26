# frozen_string_literal: true

RSpec.shared_examples 'an API endpoint for creating project approval rule' do
  let(:current_user) { user }
  let(:params) do
    {
      name: 'security',
      approvals_required: 10
    }
  end

  context 'when missing parameters' do
    it 'returns 400 status' do
      post api(url, current_user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'when user is without access' do
    it 'returns 403' do
      post api(url, user2), params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when the request is correct' do
    it 'returns 201 status' do
      post api(url, current_user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema(schema, dir: 'ee')
    end

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
        stub_licensed_features(multiple_approval_rules: true)
        post api(url, current_user), params: params.merge(protected_branch_ids: protected_branches.map(&:id))
      end

      it 'creates approval rule associated to specified protected branches' do
        expect(json_response['protected_branches']).to contain_exactly(
          a_hash_including('id' => protected_branches.first.id),
          a_hash_including('id' => protected_branches.last.id)
        )
      end
    end

    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME.keys.each do |rule_name|
      context "when creating a '#{rule_name}' approval rule" do
        it 'specifies a `rule_type` of `report_approver`' do
          expect do
            post api(url, current_user), params: params.merge(name: rule_name)
          end.to change { ApprovalProjectRule.report_approver.count }.from(0).to(1)

          expect(response).to have_gitlab_http_status(:created)
        end
      end
    end

    context 'with valid scanners' do
      let(:scanners) { ['sast'] }

      it 'returns 201 status' do
        expect do
          post api(url, current_user), params: params.merge({ scanners: scanners })
        end.to change { project.approval_rules.count}.from(0).to(1)
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
  end

  context 'with vulnerabilities_allowed' do
    let(:vulnerabilities_allowed) { 10 }

    it 'returns 201 status' do
      expect do
        post api(url, current_user), params: params.merge({ vulnerabilities_allowed: vulnerabilities_allowed })
      end.to change { project.approval_rules.count}.from(0).to(1)
      expect(response).to have_gitlab_http_status(:created)
      expect(project.approval_rules.first.vulnerabilities_allowed).to eql(vulnerabilities_allowed)
    end
  end
end

RSpec.shared_examples 'an API endpoint for updating project approval rule' do
  shared_examples 'a user with access' do
    before do
      project.add_developer(approver)
      project.add_developer(other_approver)
    end

    context 'when protected_branch_ids param is present' do
      let(:protected_branches) { Array.new(2).map { create(:protected_branch, project: project) } }

      before do
        stub_licensed_features(multiple_approval_rules: true)
        put api(url, current_user), params: { protected_branch_ids: protected_branches.map(&:id) }
      end

      it 'associates approval rule to specified protected branches' do
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
          put api(url, current_user), params: { scanners: scanners }
        end.to change { approval_rule.reload.scanners.count }.from(::ApprovalProjectRule::SUPPORTED_SCANNERS.count).to(scanners.count)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with valid severity_levels' do
      let(:severity_levels) { ['critical'] }

      it 'returns 200 status' do
        expect do
          put api(url, current_user), params: { severity_levels: severity_levels }
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
            put api(url, current_user), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
          end.to change { approval_rule.users.count + approval_rule.groups.count }.from(2).to(0)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema(schema, dir: 'ee')
        end
      end
    end

    it 'sets approvers' do
      expect do
        put api(url, current_user), params: { users: "#{approver.id},#{other_approver.id}" }
      end.to change { approval_rule.users.count }.from(0).to(2)

      expect(approval_rule.users).to contain_exactly(approver, other_approver)
      expect(approval_rule.groups).to be_empty

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with vulnerabilities_allowed' do
      let(:vulnerabilities_allowed) { 10 }

      it 'returns 200 status' do
        expect do
          put api(url, current_user), params: { vulnerabilities_allowed: vulnerabilities_allowed }
        end.to change { approval_rule.reload.vulnerabilities_allowed }.from(0).to(vulnerabilities_allowed)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
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
    it 'returns 403' do
      project.approvers.create!(user: approver)

      expect do
        put api(url, user2), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
      end.not_to change { approval_rule.approvers.size }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples 'an API endpoint for deleting project approval rule' do
  it 'destroys' do
    delete api(url, user)

    expect(ApprovalProjectRule.exists?(id: approval_rule.id)).to eq(false)
    expect(response).to have_gitlab_http_status(:no_content)
  end

  context 'when approval rule not found' do
    let!(:approval_rule_2) { create(:approval_project_rule) }
    let(:url) { "/projects/#{project.id}/approval_settings/#{approval_rule_2.id}" }

    it 'returns not found' do
      delete api(url, user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when user is not eligible to delete' do
    it 'returns forbidden' do
      delete api(url, user2)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
