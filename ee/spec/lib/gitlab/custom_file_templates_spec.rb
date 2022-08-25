# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CustomFileTemplates do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:instance_template_project) { create(:project, :custom_repo, files: template_files('instance')) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:group_template_project) { create(:project, :custom_repo, namespace: group, files: template_files('group')) }

  subject(:templates) { described_class.new(template_finder, target_project) }

  def template_files(prefix)
    {
      "Dockerfile/#{prefix}_dockerfile.dockerfile" => "#{prefix}_dockerfile content",
      "gitignore/#{prefix}_gitignore.gitignore" => "#{prefix}_gitignore content",
      "gitlab-ci/#{prefix}_gitlab_ci_yml.yml" => "#{prefix}_gitlab_ci_yml content",
      "LICENSE/#{prefix}_license.txt" => "#{prefix}_license content"
    }
  end

  describe '#enabled?' do
    where(
      instance_licensed: [false, true],
      namespace_licensed: [false, true],
      instance_enabled: [false, true],
      namespace_enabled: [false, true]
    )

    with_them do
      let(:target_project) { project }
      let(:template_finder) { double('template-finder') }
      let(:expected_result) { (instance_licensed && instance_enabled) || (namespace_licensed && namespace_enabled) }

      subject { templates.enabled? }

      before do
        stub_licensed_features(
          custom_file_templates: instance_licensed,
          custom_file_templates_for_namespace: namespace_licensed
        )

        stub_ee_application_setting(file_template_project: instance_template_project) if instance_enabled
        group.update_columns(file_template_project_id: group_template_project.id) if namespace_enabled
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#all' do
    where(:template_finder, :type) do
      Gitlab::Template::CustomDockerfileTemplate  | :dockerfile
      Gitlab::Template::CustomGitignoreTemplate   | :gitignore
      Gitlab::Template::CustomGitlabCiYmlTemplate | :gitlab_ci_yml
      Gitlab::Template::CustomLicenseTemplate     | :license
    end

    with_them do
      subject(:result) { templates.all }

      before do
        stub_ee_application_setting(file_template_project: instance_template_project)
        group.update_columns(file_template_project_id: group_template_project.id)
      end

      context 'unlicensed' do
        let(:target_project) { project }

        it { expect(result).to be_empty }
      end

      context 'licensed' do
        before do
          stub_licensed_features(custom_file_templates: true, custom_file_templates_for_namespace: true)
        end

        context 'in a toplevel group' do
          let(:target_project) { project }

          it 'orders results from most specific to least specific' do
            expect(result.map(&:key)).to eq(["group_#{type}", "instance_#{type}"])
          end
        end

        context 'in a subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:subproject) { create(:project, namespace: subgroup) }
          let_it_be(:subgroup_template_project) { create(:project, :custom_repo, namespace: subgroup, files: template_files('subgroup')) }

          let(:target_project) { subproject }

          before do
            subgroup.update_columns(file_template_project_id: subgroup_template_project.id)
          end

          it 'orders results from most specific to least specific' do
            expect(result.map(&:key)).to eq(["subgroup_#{type}", "group_#{type}", "instance_#{type}"])
          end
        end
      end
    end
  end

  describe '#find' do
    def be_template(key, category)
      have_attributes(key: key, name: key, category: category, content: "#{key} content")
    end

    where(:template_finder, :type) do
      Gitlab::Template::CustomDockerfileTemplate  | :dockerfile
      Gitlab::Template::CustomGitignoreTemplate   | :gitignore
      Gitlab::Template::CustomGitlabCiYmlTemplate | :gitlab_ci_yml
      Gitlab::Template::CustomLicenseTemplate     | :license
    end

    with_them do
      let(:group_key) { "group_#{type}" }
      let(:instance_key) { "instance_#{type}" }

      before do
        stub_ee_application_setting(file_template_project: instance_template_project)
        group.update_columns(file_template_project_id: group_template_project.id)
      end

      context 'unlicensed' do
        let(:target_project) { project }

        it { expect(templates.find(group_key)).to be_nil }
        it { expect(templates.find(instance_key)).to be_nil }
      end

      context 'licensed' do
        before do
          stub_licensed_features(custom_file_templates: true, custom_file_templates_for_namespace: true)
        end

        context 'in a toplevel group' do
          let(:target_project) { project }

          it 'finds a group template' do
            expect(templates.find(group_key)).to be_template(group_key, "Group #{group.full_name}")
          end

          it 'finds an instance template' do
            expect(templates.find(instance_key)).to be_template(instance_key, 'Instance')
          end

          it 'returns nil for an unknown key' do
            expect(templates.find('unknown')).to be_nil
          end
        end

        context 'in a subgroup' do
          let(:subgroup) { create(:group, parent: group) }
          let(:subproject) { create(:project, namespace: subgroup) }
          let(:subgroup_template_project) { create(:project, :custom_repo, namespace: subgroup, files: template_files('subgroup')) }

          let(:target_project) { subproject }
          let(:subgroup_key) { "subgroup_#{type}" }

          before do
            subgroup.update!(file_template_project: subgroup_template_project)
          end

          it 'finds a template from the subgroup' do
            expect(templates.find(subgroup_key)).to be_template(subgroup_key, "Group #{subgroup.full_name}")
          end

          it 'finds a template from the parent group' do
            expect(templates.find(group_key)).to be_template(group_key, "Group #{group.full_name}")
          end

          it 'finds an instance template' do
            expect(templates.find(instance_key)).to be_template(instance_key, 'Instance')
          end

          it 'returns nil for an unknown key' do
            expect(templates.find('unknown')).to be_nil
          end

          context 'when subgroup template names overlap with ancestor' do
            let(:subgroup_template_project) { create(:project, :custom_repo, namespace: subgroup, files: template_files('group')) }

            before do
              subgroup.update!(file_template_project: subgroup_template_project)
            end

            it 'returns a template from the subgroup' do
              expect(templates.find(group_key)).to be_template(group_key, "Group #{subgroup.full_name}")
            end

            it 'finds a template from the parent group with specified project' do
              expect(templates.find(group_key, group_template_project.id)).to be_template(group_key, "Group #{group.full_name}")
            end
          end
        end

        context 'when looking for template for a specific project' do
          let(:target_project) { project }

          let_it_be(:another_project) { create(:project, :custom_repo, namespace: group, files: template_files('group')) }

          it 'finds a valid template when looking into group template project' do
            templates_find = templates.find(group_key, group_template_project.id)

            expect(templates_find).to be_template(group_key, "Group #{group.full_name}")
          end

          it 'finds a valid template when looking into instance template project' do
            templates_find = templates.find(instance_key, instance_template_project.id)

            expect(templates_find).to be_template(instance_key, "Instance")
          end

          it 'does not find a template when given project does not have the template' do
            expect(templates.find(group_key, another_project.id)).to be_nil
          end
        end
      end
    end
  end

  describe '#all_template_names' do
    RSpec.shared_examples 'does not list an empty category' do
      it 'misses subgroup category' do
        expect(template_categories).to eq(["Group #{group.full_name}", "Instance"])
      end

      it 'misses subgroup templates' do
        expect(template_file_names).to eq(["group_#{type}", "instance_#{type}"])
      end
    end

    where(:template_finder, :type) do
      Gitlab::Template::CustomDockerfileTemplate  | :dockerfile
      Gitlab::Template::CustomGitignoreTemplate   | :gitignore
      Gitlab::Template::CustomGitlabCiYmlTemplate | :gitlab_ci_yml
      Gitlab::Template::CustomLicenseTemplate     | :license
    end

    with_them do
      let(:result) { templates.all_template_names }
      let(:template_file_names) { result.values.flatten.map { |el| el[:name] } }
      let(:template_categories) { result.keys }

      before do
        stub_ee_application_setting(file_template_project: instance_template_project)
        group.update_columns(file_template_project_id: group_template_project.id)
      end

      context 'unlicensed' do
        let(:target_project) { project }

        it { expect(result).to be_empty }
      end

      context 'licensed' do
        before do
          stub_licensed_features(custom_file_templates: true, custom_file_templates_for_namespace: true)
        end

        context 'in a toplevel group' do
          let(:target_project) { project }

          it 'has the group names and instance as category' do
            expect(template_categories).to eq(["Group #{group.full_name}", "Instance"])
          end

          it 'orders results from most specific to least specific' do
            expect(template_file_names).to eq(["group_#{type}", "instance_#{type}"])
          end
        end

        context 'in a subgroup' do
          let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
          let_it_be_with_reload(:subproject) { create(:project, namespace: subgroup) }
          let_it_be(:subgroup_template_project) { create(:project, :custom_repo, namespace: subgroup, files: template_files('subgroup')) }

          let(:target_project) { subproject }

          context 'with nested group templates' do
            before do
              subgroup.update_columns(file_template_project_id: subgroup_template_project.id)
            end

            it 'has the group names and instance as category' do
              expect(template_categories).to eq(["Group #{subgroup.full_name}", "Group #{group.full_name}", "Instance"])
            end

            it 'orders results from most specific to least specific' do
              expect(template_file_names).to eq(["subgroup_#{type}", "group_#{type}", "instance_#{type}"])
            end
          end

          context 'with templates missing for a nested group' do
            context 'when subgroup template config points to a project that has no templates' do
              before do
                subgroup.update_columns(file_template_project_id: subproject.id)
              end

              it_behaves_like 'does not list an empty category'
            end

            context 'when subgroup template config is not setup' do
              before do
                subgroup.update_columns(file_template_project_id: nil)
              end

              it_behaves_like 'does not list an empty category'
            end
          end
        end
      end
    end
  end
end
