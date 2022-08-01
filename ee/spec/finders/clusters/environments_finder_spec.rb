# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::EnvironmentsFinder, '#execute' do
  let(:current_user) { create(:user) }
  let(:last_deployment) { create(:deployment, :success, :on_cluster) }
  let(:cluster) { last_deployment.cluster }
  let(:environment) { last_deployment.environment }

  before do
    allow(Ability).to receive(:allowed?)
      .with(current_user, :read_cluster_environments, cluster)
      .and_return(allowed)
  end

  subject { described_class.new(cluster, current_user).execute }

  context 'current_user can read cluster environments' do
    let(:allowed) { true }

    it { is_expected.to include(environment) }

    context 'environment is not available' do
      before do
        environment.stop!
      end

      it { is_expected.not_to include(environment) }
    end
  end

  context 'current_user cannot read cluster environments' do
    let(:allowed) { false }

    it { is_expected.to be_empty }
  end
end
