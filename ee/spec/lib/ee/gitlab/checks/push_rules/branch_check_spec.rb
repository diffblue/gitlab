# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Checks::PushRules::BranchCheck do
  include_context 'push rules checks context'

  describe '#validate!' do
    let!(:push_rule) { create(:push_rule, branch_name_regex: '^(w*)$') }
    let(:ref) { 'refs/heads/a-branch-that-is-not-allowed' }

    it_behaves_like 'check ignored when push rule unlicensed'
    it_behaves_like 'use predefined push rules'

    it 'rejects the branch that is not allowed' do
      expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "Branch name 'a-branch-that-is-not-allowed' does not follow the pattern '^(w*)$'")
    end

    it 'returns an error if the regex is invalid' do
      push_rule.branch_name_regex = '+'

      expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /\ARegular expression '\+' is invalid/)
    end

    context 'when the ref is not a branch ref' do
      let(:ref) { 'a/ref/thats/not/abranch' }

      it 'allows the creation' do
        expect { subject.validate! }.not_to raise_error
      end
    end

    context 'when no commits are present' do
      before do
        allow(project.repository).to receive(:new_commits) { [] }
      end

      it 'rejects the branch that is not allowed' do
        expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, "Branch name 'a-branch-that-is-not-allowed' does not follow the pattern '^(w*)$'")
      end
    end

    context 'when the default branch does not match the push rules' do
      let(:push_rule) { create(:push_rule, branch_name_regex: 'not-master') }
      let(:ref) { "refs/heads/#{project.default_branch}" }

      it 'allows the default branch even if it does not match push rule' do
        expect { subject.validate! }.not_to raise_error
      end
    end
  end
end
