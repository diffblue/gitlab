# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::IssuableResourceLink::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:link_text) { 'Text about link' }

  let(:link_type) { :zoom }
  let(:link) { 'http://gitlab.foo.com/zoom_link' }
  let(:args) { { link: link, link_text: link_text, link_type: link_type } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_issuable_resource_link) }

  before do
    stub_licensed_features(issuable_resource_links: true)
  end

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(id: incident.to_global_id, **args) }

    context 'when a user has permissions to create a resource link' do
      before do
        project.add_reporter(current_user)
      end

      context 'when IssuableResourceLink::CreateService responds with success' do
        it 'adds issuable resource link to database' do
          expect { resolve }.to change(IncidentManagement::IssuableResourceLink, :count).by(1)
        end

        it 'adds associated resource link with incident' do
          resolve

          expect(incident.issuable_resource_links.size).to eq(1)
        end
      end

      context 'when IssuableResourceLink::CreateService responds with an error' do
        let(:args) { {} }

        it 'returns error' do
          expect(resolve).to eq(
            issuable_resource_link: nil,
            errors: ["Link can't be blank and Link must be a valid URL"])
        end
      end

      context 'when incorrect link is passed' do
        let(:link) { 'ftp://random-ftp-url' }

        it 'returns error' do
          expect(resolve).to eq(
            issuable_resource_link: nil,
            errors: ["Link is blocked: Only allowed schemes are http, https"])
        end
      end

      context 'when incorrect link type is passed' do
        let(:link_type) { :some_random_link_type }

        it 'raises an error' do
          expect { resolve }.to raise_error(ArgumentError)
        end
      end

      context 'when issue type is not incident' do
        let(:incident) { create(:issue, project: project) }

        it 'raises an error' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when a user has no permissions to create issuable resource link' do
      before do
        project.add_guest(current_user)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when issuable resource link feature is not avaiable' do
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
