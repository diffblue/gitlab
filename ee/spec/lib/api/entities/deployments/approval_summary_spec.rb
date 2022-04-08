# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Deployments::ApprovalSummary do
  subject { described_class.new(approval_summary).as_json }

  let(:deployment) { build(:deployment) }
  let(:approval_summary) { deployment.approval_summary }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:rules)
  end
end
