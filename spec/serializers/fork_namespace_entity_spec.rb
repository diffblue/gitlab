# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkNamespaceEntity do
  include Gitlab::Routing.url_helpers
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:namespace) { create(:group, :with_avatar, description: 'test') }
  let(:entity) { described_class.new(namespace, current_user: user, project: project) }

  subject(:json) { entity.as_json }

  before do
    project.add_maintainer(user)
  end

  it 'renders json' do
    is_expected.not_to be_nil
  end

  %w[id
     name
     description
     markdown_description
     visibility
     full_name
     created_at
     updated_at
     avatar_url].each do |attribute|
    it "includes #{attribute}" do
      expect(json[attribute.to_sym]).to be_present
    end
  end

  it 'exposes path for forking project to the namespace' do
    expect(json[:fork_path]).to eq project_forks_path(project, namespace_key: namespace.id)
  end

  it 'exposes forked_project_path when fork exists in namespace' do
    namespace.add_maintainer(user)
    fork_in_namespace = fork_project(project, user, namespace: namespace)

    expect(json[:forked_project_path]).to eql project_path(fork_in_namespace)
  end

  it 'exposes relative path to the namespace' do
    expect(json[:relative_path]).to eql polymorphic_path(namespace)
  end

  it 'exposes human readable permission level' do
    namespace.add_developer(user)
    expect(json[:permission]).to eql 'Developer'
  end

  it 'sets can_create_project to true when user can create projects in namespace' do
    allow(user).to receive(:can?).with(:create_projects, namespace).and_return(true)

    expect(json[:can_create_project]).to be true
  end

  it 'sets can_create_project to false when user is not allowed create projects in namespace' do
    allow(user).to receive(:can?).with(:create_projects, namespace).and_return(false)

    expect(json[:can_create_project]).to be false
  end
end
