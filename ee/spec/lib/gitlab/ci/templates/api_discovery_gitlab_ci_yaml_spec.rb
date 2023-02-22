# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API-Discovery.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('API-Discovery') }

  specify { expect(template).not_to be_nil }

  describe 'the template file' do
    let(:template_filename) { Rails.root.join("lib/gitlab/ci/templates/#{template.full_name}") }
    let(:contents) { File.read(template_filename) }
    let(:production_registry) { 'API_DISCOVERY_PACKAGES: "$CI_API_V4_URL/projects/42503323/packages"' }
    let(:staging_registry) { 'API_DISCOVERY_PACKAGES: "$CI_API_V4_URL/projects/40229908/packages"' }

    # Make sure the staging package registry does not sneak into the production template.
    it 'uses the production registry' do
      expect(contents.include?(production_registry)).to be true
    end

    it "doesn't use the staging registry" do
      expect(contents.include?(staging_registry)).to be false
    end
  end

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }
    let(:ci_pipeline_job) do
      <<~YAML

      api_discovery:
        extends: .api_discovery_java_spring_boot
        image: openjdk:11-jre-slim
        variables:
          API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
      YAML
    end

    before do
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end

      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project defines no jobs' do
      before do
        stub_ci_pipeline_yaml_file(template.content)
      end

      it 'included jobs are hidden' do
        expect(build_names).to be_empty
      end
    end

    context 'when project defines jobs' do
      before do
        stub_ci_pipeline_yaml_file(template.content + ci_pipeline_job)
      end

      context 'when project has no license' do
        it 'includes job to display error' do
          expect(build_names).to match_array(%w[api_discovery])
        end
      end

      context 'when project has Ultimate license' do
        before do
          stub_licensed_features(api_discovery: true)
        end

        it 'includes a job' do
          expect(build_names).to match_array(%w[api_discovery])
        end

        context 'when API_DISCOVERY_DISABLED=1' do
          before do
            create(:ci_variable, project: project, key: 'API_DISCOVERY_DISABLED', value: '1')
          end

          it 'includes no jobs' do
            expect(build_names).to be_empty
            expect(pipeline.errors.full_messages).to match_array([
              'Pipeline will not run for the selected trigger. ' \
              'The rules configuration prevented any jobs from being added to the pipeline.'
            ])
          end
        end
      end
    end
  end
end
