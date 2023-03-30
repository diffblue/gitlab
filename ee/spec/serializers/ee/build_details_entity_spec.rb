# frozen_string_literal: true
require 'spec_helper'

RSpec.describe BuildDetailsEntity, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }

  let(:namespace) { create(:namespace, :with_ci_minutes, ci_minutes_used: 800) }
  let(:project) { create(:project, namespace: namespace) }
  let(:request) { double('request', project: project) }
  let(:build) { create(:ci_build, project: project) }

  let(:entity) do
    described_class.new(build, request: request, current_user: user, project: project)
  end

  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  context 'when namespace has CI minutes limit enabled' do
    before do
      allow(namespace).to receive(:shared_runners_minutes_limit).and_return(1000)
    end

    it 'contains CI minutes quota details' do
      quota = subject.dig(:runners, :quota)

      expect(quota).to be_present
      expect(quota.fetch(:used)).to eq(800)
      expect(quota.fetch(:limit)).to eq(1000)
    end
  end

  context 'when namespace does not qualify for CI minutes' do
    before do
      allow(namespace).to receive(:shared_runners_minutes_limit).and_return(0)
    end

    it 'does not contain CI minutes quota details' do
      expect(subject.dig(:runners, :quota)).not_to be_present
    end
  end
end
