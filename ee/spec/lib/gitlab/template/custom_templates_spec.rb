# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Custom file template classes" do
  files = {
    'Dockerfile/foo.dockerfile' => 'CustomDockerfileTemplate Foo',
    'Dockerfile/bar.dockerfile' => 'CustomDockerfileTemplate Bar',
    'Dockerfile/bad.xyz' => 'CustomDockerfileTemplate Bad',

    'gitignore/foo.gitignore' => 'CustomGitignoreTemplate Foo',
    'gitignore/bar.gitignore' => 'CustomGitignoreTemplate Bar',
    'gitignore/bad.xyz' => 'CustomGitignoreTemplate Bad',

    'gitlab-ci/foo.yml' => 'CustomGitlabCiYmlTemplate Foo',
    'gitlab-ci/bar.yml' => 'CustomGitlabCiYmlTemplate Bar',
    'gitlab-ci/bad.xyz' => 'CustomGitlabCiYmlTemplate Bad',

    'LICENSE/foo.txt' => 'CustomLicenseTemplate Foo',
    'LICENSE/bar.txt' => 'CustomLicenseTemplate Bar',
    'LICENSE/bad.xyz' => 'CustomLicenseTemplate Bad',

    'Dockerfile/category/baz.txt' => 'CustomDockerfileTemplate category baz',
    'gitignore/category/baz.txt' => 'CustomGitignoreTemplate category baz',
    'gitlab-ci/category/baz.yml' => 'CustomGitlabCiYmlTemplate category baz',
    'LICENSE/category/baz.txt' => 'CustomLicenseTemplate category baz',

    '.gitlab/issue_templates/bar.md' => 'IssueTemplate Bar',
    '.gitlab/issue_templates/foo.md' => 'IssueTemplate Foo',
    '.gitlab/issue_templates/bad.txt' => 'IssueTemplate Bad',
    '.gitlab/issue_templates/baz.xyz' => 'IssueTemplate Baz',

    '.gitlab/merge_request_templates/bar.md' => 'MergeRequestTemplate Bar',
    '.gitlab/merge_request_templates/foo.md' => 'MergeRequestTemplate Foo',
    '.gitlab/merge_request_templates/bad.txt' => 'MergeRequestTemplate Bad',
    '.gitlab/merge_request_templates/baz.xyz' => 'MergeRequestTemplate Baz'
  }

  let_it_be(:project) { create(:project, :custom_repo, files: files) }

  custom_templates = [
    { class_name: ::Gitlab::Template::CustomDockerfileTemplate, category: 'Custom' },
    { class_name: ::Gitlab::Template::CustomGitignoreTemplate, category: 'Custom' },
    { class_name: ::Gitlab::Template::CustomGitlabCiYmlTemplate, category: 'Custom' },
    { class_name: ::Gitlab::Template::CustomLicenseTemplate, category: 'Custom' },
    { class_name: ::Gitlab::Template::IssueTemplate, category: 'Project Templates' },
    { class_name: ::Gitlab::Template::MergeRequestTemplate, category: 'Project Templates' }
  ].freeze

  custom_templates.each do |template_class|
    describe template_class[:class_name] do
      let(:name) { template_class[:class_name].name.demodulize }

      describe '.all' do
        it 'returns all valid templates' do
          found = described_class.all(project)

          aggregate_failures do
            expect(found.map(&:name)).to contain_exactly('foo', 'bar')
            expect(found.map(&:category).uniq).to contain_exactly(template_class[:category])
          end
        end
      end

      describe '.find' do
        let(:not_found_error) { ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError }

        it 'finds a valid template' do
          found = described_class.find('foo', project)

          expect(found.name).to eq('foo')
          expect(found.content).to eq("#{name} Foo")
        end

        it 'sets the category correctly' do
          pending("#{template_class}.find does not set category correctly")
          found = described_class.find('foo', project)

          expect(found.category).to eq('Custom')
        end

        it 'does not find a template with the wrong extension' do
          expect { described_class.find('bad', project) }.to raise_error(not_found_error)
        end

        it 'does not find a template in a subdirectory' do
          expect { described_class.find('baz', project) }.to raise_error(not_found_error)
        end
      end
    end
  end
end
