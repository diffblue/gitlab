# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DevopsAdoption::EnabledNamespaces::FindOrCreateService do
  let_it_be(:group) { create(:group) }
  let_it_be(:display_group) { create(:group) }

  let_it_be(:reporter) do
    create(:user).tap do |u|
      group.add_reporter(u)
      display_group.add_reporter(u)
    end
  end

  let(:current_user) { reporter }

  let(:params) { { namespace: group, display_namespace: display_group } }

  subject(:response) { described_class.new(params: params, current_user: current_user).execute }

  before do
    stub_licensed_features(group_level_devops_adoption: true, instance_level_devops_adoption: true)
  end

  context 'when enabled_namespace for given namespace & display_namespace already exists' do
    let!(:enabled_namespace) { create :devops_adoption_enabled_namespace, namespace: group, display_namespace: display_group }

    it 'returns existing enabled_namespace' do
      expect { response }.not_to change { Analytics::DevopsAdoption::EnabledNamespace.count }

      expect(subject.payload.fetch(:enabled_namespace)).to eq(enabled_namespace)
    end
  end

  context 'when enabled_namespace for given namespace does not exist' do
    let!(:enabled_namespace2) { create :devops_adoption_enabled_namespace, namespace: group }
    let!(:enabled_namespace3) { create :devops_adoption_enabled_namespace, display_namespace: display_group }

    it 'calls for enabled_namespace creation' do
      expect_next_instance_of(
        Analytics::DevopsAdoption::EnabledNamespaces::CreateService,
        current_user: current_user,
        params: { namespace: group, display_namespace: display_group }
      ) do |instance|
        expect(instance).to receive(:execute).and_return('create_response')
      end

      expect(response).to eq 'create_response'
    end
  end

  it 'authorizes for manage_devops_adoption' do
    expect(::Ability).to receive(:allowed?)
      .with(current_user, :manage_devops_adoption_namespaces, group)
      .at_least(1)
      .and_return(true)

    expect(::Ability).to receive(:allowed?)
      .with(current_user, :manage_devops_adoption_namespaces, display_group)
      .at_least(1)
      .and_return(true)

    response
  end

  context 'when user cannot manage devops adoption for given namespace' do
    let(:current_user) { create(:user) }

    it 'returns forbidden error' do
      expect { response }.to raise_error(Analytics::DevopsAdoption::EnabledNamespaces::AuthorizationError)
    end
  end
end
