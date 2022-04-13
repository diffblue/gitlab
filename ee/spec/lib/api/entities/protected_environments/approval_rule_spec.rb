# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProtectedEnvironments::ApprovalRule do
  subject { described_class.new(approval_rule).as_json }

  let(:approval_rule) { build(:protected_environment_approval_rule) }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:user_id, :group_id, :access_level, :access_level_description,
                                            :required_approvals)
  end
end
