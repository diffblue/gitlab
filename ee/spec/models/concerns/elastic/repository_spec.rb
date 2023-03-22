# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repository, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  def index!(project)
    Sidekiq::Testing.inline! do
      project.repository.index_commits_and_blobs

      ensure_elasticsearch_index!
    end
  end

  it "searches blobs and commits" do
    project = create :project, :repository
    index!(project)

    expect(project.repository.elastic_search('def popen')[:blobs][:total_count]).to eq(1)
    expect(project.repository.elastic_search('files/ruby/popen.rb')[:blobs][:total_count]).to eq(1)
    expect(project.repository.elastic_search('def | popen')[:blobs][:total_count] > 1).to be_truthy
    expect(project.repository.elastic_search('initial')[:commits][:total_count]).to eq(1)

    root_ref = project.repository.root_ref_sha.upcase
    expect(project.repository.elastic_search(root_ref)[:commits][:total_count]).to eq(1)

    partial_ref = root_ref[0...5]
    expect(project.repository.elastic_search(partial_ref)[:commits][:total_count]).to eq(1)
    expect(project.repository.elastic_search(partial_ref + '*')[:commits][:total_count]).to eq(1)
  end

  it "names elasticsearch queries" do
    project = create :project, :repository
    project.repository.elastic_search('*')

    assert_named_queries('doc:is_a:blob', 'blob:match:search_terms')
    assert_named_queries('doc:is_a:wiki_blob', 'blob:match:search_terms')
    assert_named_queries('doc:is_a:commit', 'commit:match:search_terms')
  end

  context 'filtering' do
    let(:project) { create :project, :repository }

    before do
      index!(project)
    end

    it 'can filter blobs' do
      # Finds custom-highlighting/test.gitlab-custom
      expect(project.repository.elastic_search('def | popen filename:test')[:blobs][:total_count]).to eq(1)

      # Should not find anything, since filename doesn't match on path
      expect(project.repository.elastic_search('def | popen filename:files')[:blobs][:total_count]).to eq(0)

      # Finds files/ruby/popen.rb, files/markdown/ruby-style-guide.md, files/ruby/regex.rb, files/ruby/version_info.rb
      expect(project.repository.elastic_search('def | popen path:ruby')[:blobs][:total_count]).to eq(4)

      # Finds files/markdown/ruby-style-guide.md
      expect(project.repository.elastic_search('def | popen extension:md')[:blobs][:total_count]).to eq(1)

      # Finds files/ruby/popen.rb
      expect(project.repository.elastic_search('* blob:7e3e39ebb9b2bf433b4ad17313770fbe4051649c')[:blobs][:total_count]).to eq(1)

      # filename filter without search term
      count = project.repository.ls_files('master').count { |path| path.split('/')[-1].include?('test') }
      expect(project.repository.elastic_search('filename:test')[:blobs][:total_count]).to eq(count)
      expect(project.repository.elastic_search('filename:test')[:blobs][:total_count]).to be > 0

      # extension filter without search term
      count = project.repository.ls_files('master').count { |path| path.split('/')[-1].split('.')[-1].include?('md') }
      expect(project.repository.elastic_search('extension:md')[:blobs][:total_count]).to eq(count)
      expect(project.repository.elastic_search('extension:md')[:blobs][:total_count]).to be > 0

      # path filter without search term
      count = project.repository.ls_files('master').count { |path| path.include?('ruby') }
      expect(project.repository.elastic_search('path:ruby')[:blobs][:total_count]).to eq(count)
      expect(project.repository.elastic_search('path:ruby')[:blobs][:total_count]).to be > 0

      # blob filter without search term
      expect(project.repository.elastic_search('blob:7e3e39ebb9b2bf433b4ad17313770fbe4051649c')[:blobs][:total_count]).to eq(1)
    end

    it 'filters by extension when optimization is disabled' do
      stub_feature_flags(elastic_file_name_reverse_optimization: false)

      # Finds files/markdown/ruby-style-guide.md
      expect(project.repository.elastic_search('def | popen extension:md')[:blobs][:total_count]).to eq(1)

      # extension filter without search term
      count = project.repository.ls_files('master').count { |path| path.split('/')[-1].split('.')[-1].include?('md') }
      expect(project.repository.elastic_search('extension:md')[:blobs][:total_count]).to eq(count)
      expect(project.repository.elastic_search('extension:md')[:blobs][:total_count]).to be > 0
    end
  end

  def search_and_check!(on, query, type:, per: 1000)
    results = on.elastic_search(query, type: type, per: per)["#{type}s".to_sym][:results]

    blobs, commits = results.partition { |result| result['_source']['blob'].present? }

    case type
    when 'blob'
      expect(blobs).not_to be_empty
      expect(commits).to be_empty
    when 'commit'
      expect(blobs).to be_empty
      expect(commits).not_to be_empty
    else
      raise ArgumentError
    end
  end

  # A negation query can match both commits and blobs as they both have _type
  # 'repository'. Ensure this doesn't happen, in both global and project search
  it 'filters commits from blobs, and vice-versa' do
    project = create :project, :repository
    index!(project)

    search_and_check!(Repository, '-foo', type: 'blob')
    search_and_check!(Repository, '-foo', type: 'commit')
    search_and_check!(project.repository, '-foo', type: 'blob')
    search_and_check!(project.repository, '-foo', type: 'commit')
  end

  describe 'class method find_commits_by_message_with_elastic', :sidekiq_might_not_need_inline do
    let(:project) { create :project, :repository }
    let(:project1) { create :project, :repository }
    let(:results) { Repository.find_commits_by_message_with_elastic('initial') }

    before do
      project.repository.index_commits_and_blobs
      project1.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    it 'returns commits' do
      expect(results).to contain_exactly(instance_of(Commit), instance_of(Commit))
      expect(results.count).to eq(2)
      expect(results.total_count).to eq(2)
    end

    context 'with a deleted project' do
      before do
        # Call DELETE directly to avoid triggering our callback to clear the ES index
        project.delete
      end

      it 'skips its commits' do
        expect(results).to contain_exactly(instance_of(Commit))
        expect(results.count).to eq(1)
        expect(results.total_count).to eq(1)
      end
    end

    context 'with a project pending deletion' do
      before do
        project.update!(pending_delete: true)
      end

      it 'skips its commits' do
        expect(results).to contain_exactly(instance_of(Commit))
        expect(results.count).to eq(1)
        expect(results.total_count).to eq(1)
      end
    end
  end

  describe "find_commits_by_message_with_elastic" do
    it "returns commits" do
      project = create :project, :repository

      Gitlab::Elastic::Indexer.new(project).run
      ensure_elasticsearch_index!

      expect(project.repository.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
      expect(project.repository.find_commits_by_message_with_elastic('initial').count).to eq(1)
      expect(project.repository.find_commits_by_message_with_elastic('initial').total_count).to eq(1)
    end
  end
end
