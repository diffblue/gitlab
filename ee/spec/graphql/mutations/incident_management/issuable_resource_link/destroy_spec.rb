# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::IssuableResourceLink::Destroy do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let(:issuable_resource_link) { create(:issuable_resource_link, issue: incident) }
  let(:args) { { id: issuable_resource_link.to_global_id } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_issuable_resource_link) }

  before do
    stub_licensed_features(issuable_resource_links: true)
  end

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(**args) }

    context 'when a user has permissions to delete issuable resource link' do
      before do
        project.add_reporter(current_user)
      end

      context 'when IssuableResourceLinks::DestroyService responds with success' do
        it 'returns the issuable resource link with no errors' do
          expect(resolve).to eq(
            issuable_resource_link: issuable_resource_link,
            errors: []
          )
        end
      end

      context 'when IssuableResourceLinks::DestroyService responds with an error' do
        before do
          allow_next_instance_of(::IncidentManagement::IssuableResourceLinks::DestroyService) do |service|
            allow(service)
              .to receive(:execute)
              .and_return(ServiceResponse.error(payload: { issuable_resource_link: nil }, message: 'An error occurred'))
          end
        end

        it 'returns errors' do
          expect(resolve).to eq(
            issuable_resource_link: nil,
            errors: ['An error occurred']
          )
        end
      end
    end

    context 'when a user has no permissions to delete an issuable resource link' do
      before do
        project.add_guest(current_user)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when issuable resource links feature is not avaiable' do
      before do
        stub_licensed_features(issuable_resource_links: false)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
