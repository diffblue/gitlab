# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Zoekt::SearchResults, :zoekt, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let(:query) { 'hello world' }
  let_it_be(:project_1) { create(:project, :public, :repository) }
  let_it_be(:project_2) { create(:project, :public, :repository) }
  let(:limit_project_ids) { [project_1.id] }

  before do
    zoekt_ensure_project_indexed!(project_1)
    zoekt_ensure_project_indexed!(project_2)
  end

  describe 'blobs' do
    before do
      zoekt_ensure_project_indexed!(project_1)
    end

    it 'finds blobs by regex search' do
      results = described_class.new(user, 'use.*egex', limit_project_ids)
      blobs = results.objects('blobs')

      expect(blobs.map(&:data).join).to include("def username_regex\n      default_regex")
      expect(results.blobs_count).to eq 5
    end

    it 'correctly handles pagination' do
      per_page = 2

      results = described_class.new(user, 'use.*egex', limit_project_ids)
      blobs_page1 = results.objects('blobs', page: 1, per_page: per_page)
      blobs_page2 = results.objects('blobs', page: 2, per_page: per_page)
      blobs_page3 = results.objects('blobs', page: 3, per_page: per_page)

      expect(blobs_page1.map(&:data).join).to include("def username_regex\n      default_regex")
      expect(blobs_page2.map(&:data).join).to include("regexp group matches\n  (`$1`, `$2`, etc)")
      expect(blobs_page3.map(&:data).join).to include("more readable and you\n  can add some useful comments")
      expect(results.blobs_count).to eq 5
    end

    it 'finds blobs from searched projects only' do
      project_3 = create :project, :repository, :private
      zoekt_ensure_project_indexed!(project_3)
      project_3.add_reporter(user)

      results = described_class.new(user, 'project_name_regex', [project_1.id])
      expect(results.blobs_count).to eq 1
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to match_array([project_1.id])

      results = described_class.new(user, 'project_name_regex', [project_1.id, project_3.id])
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to match_array([project_1.id, project_3.id])
      expect(results.blobs_count).to eq 2

      results = described_class.new(user, 'project_name_regex', :any)
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to match_array([project_1.id, project_2.id, project_3.id])
      expect(results.blobs_count).to eq 3
    end

    it 'raises an error if there are somehow no project_id in the filter' do
      expect do
        described_class.new(user, 'project_name_regex', []).objects('blobs')
      end.to raise_error('Not possible to search no projects')
    end

    it 'returns zero when blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.blobs_count).to eq 0
    end

    context 'with an invalid search' do
      it 'logs an error and returns an empty array for results', :aggregate_failures do
        search_results = described_class.new(user, '(invalid search(', limit_project_ids)

        logger = instance_double(::Zoekt::Logger)
        expect(::Zoekt::Logger).to receive(:build).and_return(logger)
        expect(logger).to receive(:error).with(hash_including(status: 400))

        blobs = search_results.objects('blobs')
        expect(blobs).to be_empty
        expect(search_results).to be_failed
        expect(search_results.error).to include('error parsing regexp')
      end
    end

    context 'when searching with special characters', :aggregate_failures do
      let(:examples) do
        {
          'perlMethodCall' => '$my_perl_object->perlMethodCall',
          '"absolute_with_specials.txt"' => '/a/longer/file-path/absolute_with_specials.txt',
          '"components-within-slashes"' => '/file-path/components-within-slashes/',
          'bar\(x\)' => 'Foo.bar(x)',
          'someSingleColonMethodCall' => 'LanguageWithSingleColon:someSingleColonMethodCall',
          'javaLangStaticMethodCall' => 'MyJavaClass::javaLangStaticMethodCall',
          'tokenAfterParentheses' => 'ParenthesesBetweenTokens)tokenAfterParentheses',
          'ruby_call_method_123' => 'RubyClassInvoking.ruby_call_method_123(with_arg)',
          'ruby_method_call' => 'RubyClassInvoking.ruby_method_call(with_arg)',
          '#ambitious-planning' => 'We [plan ambitiously](#ambitious-planning).',
          'ambitious-planning' => 'We [plan ambitiously](#ambitious-planning).',
          'tokenAfterCommaWithNoSpace' => 'WouldHappenInManyLanguages,tokenAfterCommaWithNoSpace',
          'missing_token_around_equals' => 'a.b.c=missing_token_around_equals',
          'and;colons:too\$' => 'and;colons:too$',
          '"differeñt-lønguage.txt"' => 'another/file-path/differeñt-lønguage.txt',
          '"relative-with-specials.txt"' => 'another/file-path/relative-with-specials.txt',
          'ruby_method_123' => 'def self.ruby_method_123(ruby_another_method_arg)',
          'ruby_method_name' => 'def self.ruby_method_name(ruby_method_arg)',
          '"dots.also.neeeeed.testing"' => 'dots.also.neeeeed.testing',
          '.testing' => 'dots.also.neeeeed.testing',
          'dots' => 'dots.also.neeeeed.testing',
          'also.neeeeed' => 'dots.also.neeeeed.testing',
          'neeeeed' => 'dots.also.neeeeed.testing',
          'tests-image' => 'extends: .gitlab-tests-image',
          'gitlab-tests' => 'extends: .gitlab-tests-image',
          'gitlab-tests-image' => 'extends: .gitlab-tests-image',
          'foo/bar' => 'https://s3.amazonaws.com/foo/bar/baz.png',
          'https://test.or.dev.com/repository' => 'https://test.or.dev.com/repository/maven-all',
          'test.or.dev.com/repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'https://test.or.dev.com/repository/maven-all' => 'https://test.or.dev.com/repository/maven-all',
          'bar-baz-conventions' => 'id("foo.bar-baz-conventions")',
          'baz-conventions' => 'id("foo.bar-baz-conventions")',
          'baz' => 'id("foo.bar-baz-conventions")',
          'bikes-3.4' => 'include "bikes-3.4"',
          'sql_log_bin' => 'q = "SET @@session.sql_log_bin=0;"',
          'sql_log_bin=0' => 'q = "SET @@session.sql_log_bin=0;"',
          'v3/delData' => 'uri: "v3/delData"',
          '"us-east-2"' => 'us-east-2'
        }
      end

      before do
        examples.values.uniq.each do |file_content|
          file_name = Digest::SHA256.hexdigest(file_content)
          project_1.repository.create_file(user, file_name, file_content, message: 'Some commit message',
branch_name: 'master')
        end

        zoekt_ensure_project_indexed!(project_1)
      end

      it 'finds all examples' do
        examples.each do |search_term, file_content|
          file_name = Digest::SHA256.hexdigest(file_content)

          results = described_class.new(user, search_term, limit_project_ids).objects('blobs').map(&:path)
          expect(results).to include(file_name)
        end
      end
    end
  end
end
