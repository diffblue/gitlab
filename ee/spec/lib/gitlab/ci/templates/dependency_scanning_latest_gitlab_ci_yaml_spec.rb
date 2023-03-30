# frozen_string_literal: true
# rubocop:disable Layout/LineLength

require 'spec_helper'

RSpec.shared_examples 'language detection' do
  using RSpec::Parameterized::TableSyntax

  where(:case_name, :files, :include_build_names) do
    'Go'                             | { 'go.sum' => '' }                        | %w[gemnasium-dependency_scanning]
    'Java'                           | { 'pom.xml' => '' }                       | %w[gemnasium-maven-dependency_scanning]
    'Java Gradle'                    | { 'build.gradle' => '' }                  | %w[gemnasium-maven-dependency_scanning]
    'Java Gradle Kotlin DSL'         | { 'build.gradle.kts' => '' }              | %w[gemnasium-maven-dependency_scanning]
    'Javascript package-lock.json'   | { 'package-lock.json' => '' }             | %w[gemnasium-dependency_scanning]
    'Javascript yarn.lock'           | { 'yarn.lock' => '' }                     | %w[gemnasium-dependency_scanning]
    'Javascript npm-shrinkwrap.json' | { 'npm-shrinkwrap.json' => '' }           | %w[gemnasium-dependency_scanning]
    'Multiple languages'             | { 'pom.xml' => '', 'package-lock.json' => '' } | %w[gemnasium-maven-dependency_scanning gemnasium-dependency_scanning]
    'NuGet'                          | { 'packages.lock.json' => '' }            | %w[gemnasium-dependency_scanning]
    'Conan'                          | { 'conan.lock' => '' }                    | %w[gemnasium-dependency_scanning]
    'PHP'                            | { 'composer.lock' => '' }                 | %w[gemnasium-dependency_scanning]
    'Python requirements.txt'        | { 'requirements.txt' => '' }              | %w[gemnasium-python-dependency_scanning]
    'Python requirements.pip'        | { 'requirements.pip' => '' }              | %w[gemnasium-python-dependency_scanning]
    'Python Pipfile'                 | { 'Pipfile' => '' }                       | %w[gemnasium-python-dependency_scanning]
    'Python requires.txt'            | { 'requires.txt' => '' }                  | %w[gemnasium-python-dependency_scanning]
    'Python with setup.py'           | { 'setup.py' => '' }                      | %w[gemnasium-python-dependency_scanning]
    'Python with poetry.lock'        | { 'poetry.lock' => '' }                   | %w[gemnasium-python-dependency_scanning]
    'Ruby Gemfile.lock'              | { 'Gemfile.lock' => '' }                  | %w[gemnasium-dependency_scanning]
    'Ruby gems.locked'               | { 'gems.locked' => '' }                   | %w[gemnasium-dependency_scanning]
    'Scala'                          | { 'build.sbt' => '' }                     | %w[gemnasium-maven-dependency_scanning]
  end

  with_them do
    let(:project) { create(:project, :custom_repo, files: files_at_depth_x) }

    context 'with file at root' do
      let(:files_at_depth_x) { files }

      it 'creates a pipeline with the expected jobs' do
        expect(build_names).to include(*include_build_names)
      end

      include_examples 'predefined image suffix'
    end

    context 'with file at depth 1' do
      # prepend a directory to files (e.g. convert go.sum to foo/go.sum)
      let(:files_at_depth_x) { files.transform_keys { |k| "foo/#{k}" } }

      it 'creates a pipeline with the expected jobs' do
        expect(build_names).to include(*include_build_names)
      end

      include_examples 'predefined image suffix'
    end

    context 'with file at depth 2' do
      # prepend a directory to files (e.g. convert go.sum to foo/bar/go.sum)
      let(:files_at_depth_x) { files.transform_keys { |k| "foo/bar/#{k}" } }

      it 'creates a pipeline with the expected jobs' do
        expect(build_names).to include(*include_build_names)
      end

      include_examples 'predefined image suffix'
    end

    context 'with file at depth > 2' do
      let(:files_at_depth_x) { files.transform_keys { |k| "foo/bar/baz/#{k}" } }

      it 'creates a pipeline with the expected jobs' do
        expect(build_names).to include(*include_build_names)
      end

      include_examples 'predefined image suffix'
    end

    context 'with merge request pipelines' do
      let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:feature_branch) { 'feature' }
      let(:pipeline) { service.execute(merge_request).payload }
      let(:files_at_depth_x) { files }

      let(:merge_request) do
        create(:merge_request,
          source_project: project,
          source_branch: feature_branch,
          target_project: project,
          target_branch: default_branch)
      end

      before do
        files.each do |filename, contents|
          project.repository.create_file(
            project.creator,
            filename,
            contents,
            message: "Add #{filename}",
            branch_name: feature_branch)
        end
      end

      it 'includes jobs' do
        expect(pipeline).to be_merge_request_event
        expect(pipeline.errors.full_messages).to be_empty
        expect(build_names).to match_array(include_build_names)
      end
    end
  end
end

RSpec.shared_examples 'PIP_REQUIREMENTS_FILE support' do
  context 'when PIP_REQUIREMENTS_FILE is defined' do
    before do
      create(:ci_variable, project: project, key: 'PIP_REQUIREMENTS_FILE', value: '/some/path/requirements.txt')
    end

    it 'creates a pipeline with the expected jobs' do
      expect(build_names).to include('gemnasium-python-dependency_scanning')
    end

    include_examples 'predefined image suffix'
  end
end

RSpec.shared_examples 'predefined image suffix' do
  it 'sets the image suffix as expected' do
    pipeline.builds.each do |build|
      expect(build.image.name).to end_with('$DS_IMAGE_SUFFIX')
      expect(String(build.variables.to_hash['DS_IMAGE_SUFFIX'])).to eql(expected_image_suffix)
    end
  end
end

RSpec.shared_examples 'DS_REMEDIATE default value' do |expected|
  context 'when project supported by gemnasium analyzer' do
    let(:project) { create(:project, :custom_repo, files: { 'yarn.lock' => '' }) }

    it 'sets default value for DS_REMEDIATE' do
      build = pipeline.builds.first
      expect(String(build.variables.to_hash['DS_REMEDIATE'])).to eql(expected)
    end
  end
end

RSpec.describe 'Dependency-Scanning.latest.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) do
    <<~YAML
      include:
        - template: 'Jobs/Dependency-Scanning.latest.gitlab-ci.yml'
    YAML
  end

  context 'on branch pipeline' do
    let(:default_branch) { 'master' }
    let(:files) { { 'README.txt' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      it 'includes no jobs' do
        expect(build_names).to be_empty
        expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
          'The rules configuration prevented any jobs from being added to the pipeline.'])
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }
      let(:files) { { 'conan.lock' => '', 'Gemfile.lock' => '', 'package.json' => '', 'pom.xml' => '', 'Pipfile' => '' } }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'when DEPENDENCY_SCANNING_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'DEPENDENCY_SCANNING_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when DEPENDENCY_SCANNING_DISABLED="true"' do
        before do
          create(:ci_variable, project: project, key: 'DEPENDENCY_SCANNING_DISABLED', value: 'true')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when DEPENDENCY_SCANNING_DISABLED="false"' do
        before do
          create(:ci_variable, project: project, key: 'DEPENDENCY_SCANNING_DISABLED', value: 'false')
        end

        it 'includes jobs' do
          expect(pipeline.errors.full_messages).to be_empty
          expect(build_names).not_to be_empty
        end
      end

      context 'when DS_EXCLUDED_ANALYZERS set to' do
        describe 'exclude' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :excluded_analyzers, :included_build_names) do
            'nothing'          | []                            | %w[gemnasium-dependency_scanning gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning]
            'gemnasium'        | %w[gemnasium]                 | %w[gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning]
            'gemnasium-maven'  | %w[gemnasium-maven]           | %w[gemnasium-dependency_scanning gemnasium-python-dependency_scanning]
            'gemnasium-python' | %w[gemnasium-python]          | %w[gemnasium-dependency_scanning gemnasium-maven-dependency_scanning]
            'two'              | %w[gemnasium]                 | %w[gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning]
            'three'            | %w[gemnasium-maven gemnasium] | %w[gemnasium-python-dependency_scanning]
            'four'             | %w[gemnasium-maven gemnasium] | %w[gemnasium-python-dependency_scanning]
          end

          with_them do
            before do
              create(:ci_variable, project: project, key: 'DS_EXCLUDED_ANALYZERS', value: excluded_analyzers.join(','))
            end

            it "creates pipeline with excluded analyzers skipped" do
              expect(build_names).to include(*included_build_names)
            end
          end

          context 'when all analyzers excluded' do
            before do
              create(:ci_variable, project: project, key: 'DS_EXCLUDED_ANALYZERS', value: 'gemnasium-maven, gemnasium-python, gemnasium')
            end

            it 'creates a pipeline excluding jobs from specified analyzers' do
              expect(build_names).to be_empty
              expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
                'The rules configuration prevented any jobs from being added to the pipeline.'])
            end
          end
        end
      end

      context 'as default', fips_mode: false do
        let(:expected_image_suffix) { "" }

        include_examples 'language detection'
        include_examples 'PIP_REQUIREMENTS_FILE support'
        include_examples 'DS_REMEDIATE default value', ""
      end

      context 'when FIPS mode is enabled', :fips_mode do
        let(:expected_image_suffix) { "-fips" }

        include_examples 'language detection'
        include_examples 'PIP_REQUIREMENTS_FILE support'
        include_examples 'DS_REMEDIATE default value', "false"
      end
    end
  end
end
# rubocop:enable Layout/LineLength
