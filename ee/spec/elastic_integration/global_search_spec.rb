# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GlobalSearch', :elastic_clean, :clean_gitlab_redis_shared_state, feature_category: :global_search do
  include AdminModeHelper

  let(:features) { %i(issues merge_requests repository builds wiki snippets) }
  let(:admin_with_admin_mode) { create :user, admin: true }
  let(:admin_without_admin_mode) { create :user, admin: true }
  let(:auditor) { create :user, auditor: true }
  let(:non_member) { create :user }
  let(:external_non_member) { create :user, external: true }
  let(:member) { create :user }
  let(:external_member) { create :user, external: true }
  let(:guest) { create :user }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    stub_const('POSSIBLE_FEATURES', %i(issues merge_requests wiki_blobs blobs commits).freeze)

    project.add_developer(member)
    project.add_developer(external_member)
    project.add_guest(guest)

    enable_admin_mode!(admin_with_admin_mode)
  end

  context "Respect feature visibility levels", :aggregate_failures do
    context "Private projects" do
      let(:project) { create(:project, :private, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest, except: [:merge_requests, :blobs, :commits])
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Internal projects" do
      let(:project) { create(:project, :internal, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin_with_admin_mode)
        expect_items_to_be_found(admin_without_admin_mode)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are private" do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest, except: :merge_requests)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Public projects" do
      let(:project) { create(:project, :public, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "finds items if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin_with_admin_mode)
        expect_items_to_be_found(admin_without_admin_mode)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_items_to_be_found(external_non_member)
        expect_items_to_be_found(nil)
      end

      it "shows items to member only if features are private", :aggregate_failures do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin_with_admin_mode)
        expect_no_items_to_be_found(admin_without_admin_mode)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest, except: :merge_requests)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end
  end

  def create_items(project, feature_settings = nil)
    Sidekiq::Testing.inline! do
      create :issue, title: 'term', project: project
      create :merge_request, title: 'term', target_project: project, source_project: project
      project.wiki.create_page('index_page', 'term')

      # Going through the project ensures its elasticsearch document is updated
      project.update!(project_feature_attributes: feature_settings) if feature_settings

      project.repository.index_commits_and_blobs
      project.wiki.index_wiki_blobs

      ensure_elasticsearch_index!
    end
  end

  # access_level can be :disabled, :enabled or :private
  def feature_settings(access_level)
    features.to_h { |k| ["#{k}_access_level", Featurable.const_get(access_level.to_s.upcase, false)] }
  end

  def expect_no_items_to_be_found(user)
    expect_items_to_be_found(user, except: :all)
  end

  def expect_items_to_be_found(user, only: nil, except: nil)
    arr = if only
            [only].flatten.compact
          elsif except == :all
            []
          else
            POSSIBLE_FEATURES - [except].flatten.compact
          end

    check_count = lambda do |feature, c|
      if arr.include?(feature)
        expect(c).to be > 0, "Search returned no #{feature} for #{user}"
      else
        expect(c).to eq(0), "Search returned #{feature} for #{user}"
      end
    end

    results = search(user, 'term')

    check_count[:issues, results.issues_count]
    check_count[:merge_requests, results.merge_requests_count]
    check_count[:wiki_blobs, results.wiki_blobs_count]
    check_count[:blobs, search(user, 'def').blobs_count]
    check_count[:commits, search(user, 'add').commits_count]
  end

  def search(user, search, snippets: false)
    SearchService.new(user, search: search, snippets: snippets ? 'true' : 'false').search_results
  end
end
