# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRule, feature_category: :source_code_management do
  let_it_be(:protected_branch) { create(:protected_branch) }

  subject { described_class.new(protected_branch.project, protected_branch) }

  it 'delegates methods to protected branch' do
    expect(subject).to delegate_method(:approval_project_rules).to(:protected_branch)
    expect(subject).to delegate_method(:external_status_checks).to(:protected_branch)
    expect(subject).to delegate_method(:can_unprotect?).to(:protected_branch)
  end
end
