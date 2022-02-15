# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group routing', "routing" do
  include RSpec::Rails::RoutingExampleGroup

  before do
    allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)
  end

  describe 'subgroup "boards"' do
    it 'shows group show page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq/boards', any_args).and_return(true)

      expect(get('/groups/gitlabhq/boards')).to route_to('groups#show', id: 'gitlabhq/boards')
    end

    it 'shows boards index page' do
      expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
    end
  end

  describe 'security' do
    it 'shows group dashboard' do
      expect(get('/groups/gitlabhq/-/security/dashboard')).to route_to('groups/security/dashboard#show', group_id: 'gitlabhq')
    end

    it 'shows vulnerability list' do
      expect(get('/groups/gitlabhq/-/security/vulnerabilities')).to route_to('groups/security/vulnerabilities#index', group_id: 'gitlabhq')
    end
  end

  describe 'packages' do
    it 'routes to packages index page' do
      expect(get('/groups/gitlabhq/-/packages')).to route_to('groups/packages#index', group_id: 'gitlabhq')
    end
  end

  describe 'issues' do
    it 'routes post to #bulk_update' do
      expect(post('/groups/gitlabhq/-/issues/bulk_update')).to route_to('groups/issues#bulk_update', group_id: 'gitlabhq')
    end
  end

  describe 'merge_requests' do
    it 'routes post to #bulk_update' do
      expect(post('/groups/gitlabhq/-/merge_requests/bulk_update')).to route_to('groups/merge_requests#bulk_update', group_id: 'gitlabhq')
    end
  end

  describe 'epics' do
    it 'routes post to #bulk_update' do
      expect(post('/groups/gitlabhq/-/epics/bulk_update')).to route_to('groups/epics#bulk_update', group_id: 'gitlabhq')
    end
  end

  #      group_wikis_git_access GET    /:group_id/-/wikis/git_access(.:format) groups/wikis#git_access
  #           group_wikis_pages GET    /:group_id/-/wikis/pages(.:format)      groups/wikis#pages
  #             group_wikis_new GET    /:group_id/-/wikis/new(.:format)        groups/wikis#new
  #                             POST   /:group_id/-/wikis(.:format)            groups/wikis#create
  #             group_wiki_edit GET    /:group_id/-/wikis/*id/edit             groups/wikis#edit
  #          group_wiki_history GET    /:group_id/-/wikis/*id/history          groups/wikis#history
  # group_wiki_preview_markdown POST   /:group_id/-/wikis/*id/preview_markdown groups/wikis#preview_markdown
  #                  group_wiki GET    /:group_id/-/wikis/*id                  groups/wikis#show
  #                             PUT    /:group_id/-/wikis/*id                  groups/wikis#update
  #                             DELETE /:group_id/-/wikis/*id                  groups/wikis#destroy
  describe Groups::WikisController, 'routing' do
    it_behaves_like 'wiki routing' do
      let(:base_path) { '/groups/gitlabhq/-/wikis' }
      let(:base_params) { { group_id: 'gitlabhq' } }
    end
  end

  describe 'feature discovery moments' do
    it 'routes to #advanced_features_dashboard' do
      expect(get("/groups/gitlabhq/-/discover_premium_and_ultimate")).to route_to('groups/feature_discovery_moments#advanced_features_dashboard', group_id: 'gitlabhq')
    end
  end
end
