# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::IssuableResourceLinksResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:first_issuable_resource_link) { create(:issuable_resource_link, issue: incident) }
  let_it_be(:second_issuable_resource_link) { create(:issuable_resource_link, issue: incident) }

  let(:args) { { incident_id: incident.to_global_id } }
  let(:resolver) { described_class }

  subject(:resolved_issuable_resource_links) do
    sync(resolve_issuable_resource_link(args, current_user: current_user).to_a)
  end

  before do
    stub_licensed_features(issuable_resource_links: true)
    project.add_reporter(current_user)
  end

  specify do
    expect(resolver).to have_nullable_graphql_type(
      Types::IncidentManagement::IssuableResourceLinkType.connection_type
    )
  end

  it 'returns issuable resource links', :aggregate_failures do
    expect(resolved_issuable_resource_links.length).to eq(2)
    expect(resolved_issuable_resource_links.first).to be_a(::IncidentManagement::IssuableResourceLink)
  end

  context 'when user does not have permissions' do
    before do
      project.add_guest(current_user)
    end

    it 'returns no resource links' do
      expect(resolved_issuable_resource_links.length).to eq(0)
    end
  end

  private

  def resolve_issuable_resource_link(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: incident, args: args, ctx: context, arg_style: :internal_prepared)
  end
end
