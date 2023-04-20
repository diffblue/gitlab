# frozen_string_literal: true

RSpec.shared_examples 'merge validation hooks' do |args|
  def hooks_error(squashing: false)
    service.hooks_validation_error(merge_request, validate_squash_message: squashing)
  end

  def hooks_pass?(squashing: false)
    service.hooks_validation_pass?(merge_request, validate_squash_message: squashing)
  end

  shared_examples 'hook validations are skipped when push rules unlicensed' do
    subject { service.hooks_validation_pass?(merge_request) }

    before do
      stub_licensed_features(push_rules: false)
    end

    it { is_expected.to be_truthy }
  end

  it 'returns true when valid' do
    expect(service.hooks_validation_pass?(merge_request)).to be(true)
  end

  context 'commit message validation for required characters' do
    before do
      allow(project).to receive(:push_rule) { build(:push_rule, commit_message_regex: 'unmatched pattern .*') }
    end

    it_behaves_like 'hook validations are skipped when push rules unlicensed'

    it 'returns false and matches validation error' do
      expect(hooks_pass?).to be(false)
      expect(hooks_error).not_to be_empty

      if args[:persisted]
        expect(merge_request.merge_error).to eq(hooks_error)
      else
        expect(merge_request.merge_error).to be_nil
      end
    end
  end

  context 'commit message validation for forbidden characters' do
    before do
      allow(project).to receive(:push_rule) { build(:push_rule, commit_message_negative_regex: '.*') }
    end

    it_behaves_like 'hook validations are skipped when push rules unlicensed'

    it 'returns false and saves error when invalid' do
      expect(hooks_pass?).to be(false)
      expect(hooks_error).not_to be_empty

      if args[:persisted]
        expect(merge_request.merge_error).to eq(hooks_error)
      else
        expect(merge_request.merge_error).to be_nil
      end
    end
  end

  context 'authors email validation' do
    before do
      allow(project).to receive(:push_rule) { build(:push_rule, author_email_regex: '.*@unmatchedemaildomain.com') }
    end

    it_behaves_like 'hook validations are skipped when push rules unlicensed'

    it 'returns false and saves error when invalid' do
      expect(hooks_pass?).to be(false)
      expect(hooks_error).not_to be_empty

      if args[:persisted]
        expect(merge_request.merge_error).to eq(hooks_error)
      else
        expect(merge_request.merge_error).to be_nil
      end
    end

    it 'validates against the commit email' do
      user.commit_email = 'foo@unmatchedemaildomain.com'

      expect(hooks_pass?).to be(true)
      expect(hooks_error).to be_nil
    end
  end

  context 'DCO signoff validation' do
    before do
      stub_licensed_features(reject_non_dco_commits: true)
      allow(project).to receive(:push_rule) { build(:push_rule, reject_non_dco_commits: true) }
    end

    it_behaves_like 'hook validations are skipped when push rules unlicensed'

    context 'when a non DCO commit message is used' do
      it 'returns false and saves error when invalid' do
        expect(hooks_pass?).to be(false)
        expect(hooks_error).not_to be_empty

        if args[:persisted]
          expect(merge_request.merge_error).to eq(hooks_error)
        else
          expect(merge_request.merge_error).to be_nil
        end
      end
    end

    context 'when a DCO compliant commit message is used' do
      let(:dco_commit_message) { 'DCO Signed Commit\n\nSigned-off-by: Test user <test-user@example.com>' }
      let(:params) { super().merge(commit_message: dco_commit_message) }

      it 'accepts the commit message' do
        expect(hooks_pass?).to be(true)
        expect(hooks_error).to be_nil
      end
    end
  end

  context 'fast forward merge request' do
    it 'returns true when fast forward is enabled' do
      allow(project).to receive(:merge_requests_ff_only_enabled) { true }

      expect(hooks_pass?).to be(true)
      expect(hooks_error).to be_nil
    end
  end

  shared_examples 'squashing commits' do
    let(:squash_commit_message) { 'Squashed messages' }
    let(:params) { super().merge(squash_commit_message: squash_commit_message) }

    context 'and the project has a push rule for required characters' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, commit_message_regex: params[:commit_message]) }
      end

      it 'returns false and saves error when invalid' do
        expect(hooks_pass?(squashing: true)).to be(false)
        expect(hooks_error(squashing: true)).not_to be_empty

        if args[:persisted]
          expect(merge_request.merge_error).to eq(hooks_error(squashing: true))
        else
          expect(merge_request.merge_error).to be_nil
        end
      end
    end

    context 'and the project has a push rule for forbidden characters' do
      before do
        allow(project).to receive(:push_rule) do
          build(:push_rule, commit_message_negative_regex: squash_commit_message)
        end
      end

      it 'returns false and saves error when invalid' do
        expect(hooks_pass?(squashing: true)).to be(false)
        expect(hooks_error(squashing: true)).not_to be_empty

        if args[:persisted]
          expect(merge_request.merge_error).to eq(hooks_error(squashing: true))
        else
          expect(merge_request.merge_error).to be_nil
        end
      end
    end
  end

  it_behaves_like 'squashing commits'

  context 'when the project uses the fast-forward merge method' do
    before do
      allow(project).to receive(:merge_requests_ff_only_enabled) { true }
    end

    it_behaves_like 'squashing commits'
  end
end

RSpec.shared_examples 'service with multiple reviewers' do
  context 'with multiple reviewer assignments' do
    let(:opts) { super().merge(reviewer_ids_param) }
    let(:reviewer_ids_param) { { reviewer_ids: [reviewer1.id, reviewer2.id] } }
    let(:reviewer1) { create(:user) }
    let(:reviewer2) { create(:user) }

    before do
      project.add_developer(reviewer1)
      project.add_developer(reviewer2)
    end

    context 'with multiple_merge_request_reviewers feature on' do
      before do
        stub_licensed_features(multiple_merge_request_reviewers: true)
      end

      it 'allows multiple reviewers' do
        expect(execute.reviewers).to contain_exactly(reviewer1, reviewer2)
      end
    end

    context 'with multiple_merge_request_reviewers feature off' do
      before do
        stub_licensed_features(multiple_merge_request_reviewers: false)
      end

      it 'only allows one reviewer' do
        expect(execute.reviewers).to contain_exactly(reviewer1)
      end
    end
  end
end

RSpec.shared_examples 'service with approval rules' do
  let(:opts) { super().merge(approval_attributes) }
  let(:approval_attributes) { {} }

  context 'when project approval rules are missing' do
    context 'when approval rules attributes are missing' do
      it 'does not create approval rules' do
        expect(execute.approval_rules).to be_empty
      end
    end

    context 'when approval rules attributes are provided' do
      let(:approval_attributes) { { approval_rules_attributes: approval_rules } }
      let(:approval_rules) do
        [
          {
            name: 'Test',
            approvals_required: 5
          }
        ]
      end

      it 'creates approval rules' do
        expect(execute.approval_rules.count).to eq(1)
        expect(execute.approval_rules.first).to have_attributes(approvals_required: 5, name: 'Test')
      end
    end
  end

  context 'when project has approval rules' do
    let!(:any_approver_rule) do
      create(:approval_project_rule, :any_approver_rule, project: project, approvals_required: 1)
    end

    let!(:regular_rule) do
      create(:approval_project_rule, project: project, approvals_required: 2)
    end

    let!(:special_approver_rule) do
      create(:approval_project_rule, :license_scanning, project: project, approvals_required: 3)
    end

    context 'when approval rules attributes are missing' do
      it 'inherits only regular and any_approver rules from the project' do
        expect(execute.approval_rules.count).to eq(2)

        expect(execute.approval_rules.map(&:attributes)).to match(
          [
            a_hash_including('approvals_required' => 1, 'rule_type' => 'any_approver'),
            a_hash_including('approvals_required' => 2, 'rule_type' => 'regular')
          ]
        )
      end

      context 'when inherit_approval_rules_on_creation is disabled' do
        before do
          stub_feature_flags(inherit_approval_rules_on_creation: false)
        end

        it 'does not create approval rules' do
          expect(execute.approval_rules).to be_empty
        end
      end
    end

    context 'when approval rules attributes are provided' do
      let(:approval_attributes) { { approval_rules_attributes: approval_rules } }
      let(:approval_rules) do
        [
          {
            name: 'Test',
            approvals_required: 5
          }
        ]
      end

      it 'creates only requested approval rules' do
        expect(execute.approval_rules.count).to eq(1)
        expect(execute.approval_rules.first).to have_attributes(approvals_required: 5, name: 'Test')
      end
    end
  end
end
