# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Deployments::Approval do
  subject { described_class.new(approval).as_json }

  let(:approval) { build(:deployment_approval) }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:user, :status, :created_at, :comment)
  end
end
