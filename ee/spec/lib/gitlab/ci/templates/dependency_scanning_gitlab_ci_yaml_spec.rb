# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dependency-Scanning.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Dependency-Scanning') }

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:files) { { 'README.txt' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      it 'includes no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'when DEPENDENCY_SCANNING_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'DEPENDENCY_SCANNING_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'when DS_EXCLUDED_ANALYZERS set to' do
        let(:files) { { 'conan.lock' => '', 'Gemfile.lock' => '', 'package.json' => '', 'pom.xml' => '', 'Pipfile' => '' } }

        describe 'exclude' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :excluded_analyzers, :included_build_names) do
            'nothing'          | []                                                    | %w(gemnasium-dependency_scanning gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning bundler-audit-dependency_scanning retire-js-dependency_scanning)
            'gemnasium'        | %w(gemnasium)                                         | %w(gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning bundler-audit-dependency_scanning retire-js-dependency_scanning)
            'gemnasium-maven'  | %w(gemnasium-maven)                                   | %w(gemnasium-dependency_scanning gemnasium-python-dependency_scanning bundler-audit-dependency_scanning retire-js-dependency_scanning)
            'gemnasium-python' | %w(gemnasium-python)                                  | %w(gemnasium-dependency_scanning gemnasium-maven-dependency_scanning bundler-audit-dependency_scanning retire-js-dependency_scanning)
            'bundler-audit'    | %w(bundler-audit)                                     | %w(gemnasium-dependency_scanning gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning retire-js-dependency_scanning)
            'retire.js'        | %w(retire.js)                                         | %w(gemnasium-dependency_scanning gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning bundler-audit-dependency_scanning)
            'two'              | %w(gemnasium bundler-audit)                           | %w(gemnasium-maven-dependency_scanning gemnasium-python-dependency_scanning retire-js-dependency_scanning)
            'three'            | %w(gemnasium-maven retire.js gemnasium)               | %w(gemnasium-python-dependency_scanning bundler-audit-dependency_scanning)
            'four'             | %w(gemnasium-maven retire.js gemnasium bundler-audit) | %w(gemnasium-python-dependency_scanning)
          end

          with_them do
            before do
              create(:ci_variable, project: project, key: 'DS_EXCLUDED_ANALYZERS', value: excluded_analyzers.join(','))
            end

            it "creates pipeline with excluded analyzers skipped" do
              expect(build_names).to include(*included_build_names)
            end
          end

          context 'all analyzers excluded' do
            before do
              create(:ci_variable, project: project, key: 'DS_EXCLUDED_ANALYZERS', value: 'gemnasium-maven, retire.js, gemnasium-python, gemnasium, bundler-audit')
            end

            it 'creates a pipeline excluding jobs from specified analyzers' do
              expect { build_names }.to raise_error(Ci::CreatePipelineService::CreateError, %r(No stages / jobs for this pipeline.))
            end
          end
        end
      end

      context 'by default' do
        describe 'language detection' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :files, :include_build_names) do
            'Go'                             | { 'go.sum' => '' }                        | %w(gemnasium-dependency_scanning)
            'Java'                           | { 'pom.xml' => '' }                       | %w(gemnasium-maven-dependency_scanning)
            'Java Gradle'                    | { 'build.gradle' => '' }                  | %w(gemnasium-maven-dependency_scanning)
            'Java Gradle Kotlin DSL'         | { 'build.gradle.kts' => '' }              | %w(gemnasium-maven-dependency_scanning)
            'Javascript'                     | { 'package.json' => '' }                  | %w(retire-js-dependency_scanning)
            'Javascript package-lock.json'   | { 'package-lock.json' => '' }             | %w(gemnasium-dependency_scanning)
            'Javascript yarn.lock'           | { 'yarn.lock' => '' }                     | %w(gemnasium-dependency_scanning)
            'Javascript npm-shrinkwrap.json' | { 'npm-shrinkwrap.json' => '' }           | %w(gemnasium-dependency_scanning)
            'Multiple languages'             | { 'pom.xml' => '', 'package.json' => '' } | %w(gemnasium-maven-dependency_scanning retire-js-dependency_scanning)
            'NuGet'                          | { 'packages.lock.json' => '' }            | %w(gemnasium-dependency_scanning)
            'Conan'                          | { 'conan.lock' => '' }                    | %w(gemnasium-dependency_scanning)
            'PHP'                            | { 'composer.lock' => '' }                 | %w(gemnasium-dependency_scanning)
            'Python requirements.txt'        | { 'requirements.txt' => '' }              | %w(gemnasium-python-dependency_scanning)
            'Python requirements.pip'        | { 'requirements.pip' => '' }              | %w(gemnasium-python-dependency_scanning)
            'Python Pipfile'                 | { 'Pipfile' => '' }                       | %w(gemnasium-python-dependency_scanning)
            'Python requires.txt'            | { 'requires.txt' => '' }                  | %w(gemnasium-python-dependency_scanning)
            'Python with setup.py'           | { 'setup.py' => '' }                      | %w(gemnasium-python-dependency_scanning)
            'Ruby Gemfile.lock'              | { 'Gemfile.lock' => '' }                  | %w(bundler-audit-dependency_scanning gemnasium-dependency_scanning)
            'Ruby gems.locked'               | { 'gems.locked' => '' }                   | %w(gemnasium-dependency_scanning)
            'Scala'                          | { 'build.sbt' => '' }                     | %w(gemnasium-maven-dependency_scanning)
          end

          with_them do
            let(:project) { create(:project, :custom_repo, files: files_at_depth_x) }

            context 'with file at root' do
              let(:files_at_depth_x) { files }

              it 'creates a pipeline with the expected jobs' do
                expect(build_names).to include(*include_build_names)
              end
            end

            context 'with file at depth 1' do
              # prepend a directory to files (e.g. convert go.sum to foo/go.sum)
              let(:files_at_depth_x) { files.transform_keys { |k| "foo/#{k}"} }

              it 'creates a pipeline with the expected jobs' do
                expect(build_names).to include(*include_build_names)
              end
            end

            context 'with file at depth 2' do
              # prepend a directory to files (e.g. convert go.sum to foo/bar/go.sum)
              let(:files_at_depth_x) { files.transform_keys { |k| "foo/bar/#{k}"} }

              it 'creates a pipeline with the expected jobs' do
                expect(build_names).to include(*include_build_names)
              end
            end

            context 'with file at depth > 2' do
              let(:files_at_depth_x) { files.transform_keys { |k| "foo/bar/baz/#{k}"} }

              it 'includes no job' do
                expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
              end
            end
          end
        end

        context 'when PIP_REQUIREMENTS_FILE is defined' do
          before do
            create(:ci_variable, project: project, key: 'PIP_REQUIREMENTS_FILE', value: '/some/path/requirements.txt')
          end

          it 'creates a pipeline with the expected jobs' do
            expect(build_names).to include('gemnasium-python-dependency_scanning')
          end
        end
      end
    end
  end
end
