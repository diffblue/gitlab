# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TemplateFinder do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }

  let(:params) { {} }

  let(:fake_template_source) { double(::Gitlab::CustomFileTemplates) }
  let(:custom_template) { OpenStruct.new(key: 'foo', name: 'foo', category: nil, content: 'Template') }
  let(:custom_templates) { [custom_template] }

  subject(:finder) { described_class.build(type, project, params) }

  describe '#execute' do
    where(:type, :expected_template_finder) do
      :dockerfiles    | ::Gitlab::Template::CustomDockerfileTemplate
      :gitignores     | ::Gitlab::Template::CustomGitignoreTemplate
      :gitlab_ci_ymls | ::Gitlab::Template::CustomGitlabCiYmlTemplate
      :issues         | ::Gitlab::Template::IssueTemplate
      :merge_requests | ::Gitlab::Template::MergeRequestTemplate
    end

    with_them do
      subject(:result) { finder.execute }

      before do
        expect(Gitlab::CustomFileTemplates)
          .to receive(:new)
          .with(expected_template_finder, project)
          .and_return(fake_template_source)

        allow(fake_template_source)
          .to receive(:find)
          .with(custom_template.key, nil)
          .and_return(custom_template)

        allow(fake_template_source)
          .to receive(:all)
          .and_return(custom_templates)
      end

      context 'custom templates enabled' do
        before do
          allow(fake_template_source).to receive(:enabled?).and_return(true)
        end

        it 'returns custom templates' do
          is_expected.to include(custom_template)
        end

        context 'a custom template is specified by name' do
          let(:params) { { name: custom_template.key } }

          it 'returns the custom template if its name is specified' do
            is_expected.to eq(custom_template)
          end
        end
      end

      context 'custom templates disabled' do
        before do
          allow(fake_template_source).to receive(:enabled?).and_return(false)
        end

        it 'does not return any custom templates' do
          is_expected.not_to include(custom_template)
        end
      end
    end
  end

  describe '#template_names' do
    let_it_be(:template_files) do
      {
        "Dockerfile/project_dockerfiles_template.dockerfile" => "project_dockerfiles_template content",
        "gitignore/project_gitignores_template.gitignore" => "project_gitignores_template content",
        "gitlab-ci/project_gitlab_ci_ymls_template.yml" => "project_gitlab_ci_ymls_template content",
        ".gitlab/issue_templates/project_issues_template.md" => "project_issues_template content",
        ".gitlab/merge_request_templates/project_merge_requests_template.md" => "project_merge_requests_template content"
      }
    end

    let_it_be(:group, reload: true) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, group: group) }
    let_it_be(:group_template_project, reload: true) { create(:project, :custom_repo, group: group, files: template_files) }

    where(:type, :custom_name) do
      :dockerfiles            | 'project_dockerfiles_template'
      :gitignores             | 'project_gitignores_template'
      :gitlab_ci_ymls         | 'project_gitlab_ci_ymls_template'
    end

    before do
      stub_licensed_features(custom_file_templates: true, custom_file_templates_for_namespace: true)
      group.update_columns(file_template_project_id: group_template_project.id)
    end

    subject(:result) { described_class.new(type, project, params).template_names.values.flatten.map { |el| OpenStruct.new(el) } }

    with_them do
      context 'when project has a repository' do
        it 'returns all custom templates' do
          expect(result).to include(have_attributes(name: custom_name))
        end
      end

      context 'template names hash keys' do
        it 'has all the expected keys' do
          expect(result.first.to_h.keys).to match_array(%i(id key name project_id))
        end
      end
    end
  end
end
