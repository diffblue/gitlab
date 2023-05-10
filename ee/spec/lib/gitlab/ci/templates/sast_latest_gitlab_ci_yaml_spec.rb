# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAST.latest.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) do
    <<~YAML
      include:
        - template: 'Jobs/SAST.latest.gitlab-ci.yml'
    YAML
  end

  describe 'the created pipeline' do
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
      let(:files) { { 'a.rb' => '' } }

      context 'when SAST_DISABLED="1"' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when SAST_DISABLED="true"' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: 'true')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when SAST_DISABLED="false"' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: 'false')
        end

        it 'includes jobs' do
          expect(build_names).not_to be_empty
        end
      end

      context 'when SAST_EXPERIMENTAL_FEATURES is disabled for iOS projects' do
        let(:files) { { 'a.xcodeproj/x.pbxproj' => '' } }

        before do
          create(:ci_variable, project: project, key: 'SAST_EXPERIMENTAL_FEATURES', value: 'false')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'by default' do
        describe 'language detection' do
          let(:experimental_vars) { { 'SAST_EXPERIMENTAL_FEATURES' => 'true' } }
          let(:kubernetes_vars) { { 'SCAN_KUBERNETES_MANIFESTS' => 'true' } }
          let(:android) { 'Android' }
          let(:ios) { 'iOS' }

          using RSpec::Parameterized::TableSyntax

          where(:case_name, :files, :variables, :include_build_names) do
            ref(:android)          | { 'AndroidManifest.xml' => '', 'a.java' => '' } | ref(:experimental_vars) | %w(mobsf-android-sast)
            ref(:android)          | { 'app/src/main/AndroidManifest.xml' => '' }    | ref(:experimental_vars) | %w(mobsf-android-sast)
            ref(:android)          | { 'a/b/AndroidManifest.xml' => '' }             | ref(:experimental_vars) | %w(mobsf-android-sast)
            ref(:android)          | { 'a/b/android.apk' => '' }                     | ref(:experimental_vars) | %w(mobsf-android-sast)
            ref(:android)          | { 'android.apk' => '' }                         | ref(:experimental_vars) | %w(mobsf-android-sast)
            'Apex'                 | { 'app.cls' => '' }                             | {}                      | %w(pmd-apex-sast)
            'C'                    | { 'app.c' => '' }                               | {}                      | %w(flawfinder-sast)
            'C++'                  | { 'app.cpp' => '' }                             | {}                      | %w(flawfinder-sast)
            'C#'                   | { 'app.cs' => '' }                              | {}                      | %w(semgrep-sast)
            'Elixir'               | { 'mix.exs' => '' }                             | {}                      | %w(sobelow-sast)
            'Elixir, nested'       | { 'a/b/mix.exs' => '' }                         | {}                      | %w(sobelow-sast)
            'Golang'               | { 'main.go' => '' }                             | {}                      | %w(semgrep-sast)
            'Groovy'               | { 'app.groovy' => '' }                          | {}                      | %w(spotbugs-sast)
            ref(:ios)              | { 'a.xcodeproj/x.pbxproj' => '' }               | ref(:experimental_vars) | %w(mobsf-ios-sast)
            ref(:ios)              | { 'a/b/ios.ipa' => '' }                         | ref(:experimental_vars) | %w(mobsf-ios-sast)
            'Java'                 | { 'app.java' => '' }                            | {}                      | %w(semgrep-sast)
            'Java with MobSF'      | { 'app.java' => '' }                            | ref(:experimental_vars) | %w(semgrep-sast)
            'Java without MobSF'   | { 'AndroidManifest.xml' => '', 'a.java' => '' } | {}                      | %w(semgrep-sast)
            'Javascript'           | { 'app.js' => '' }                              | {}                      | %w(semgrep-sast)
            'JSX'                  | { 'app.jsx' => '' }                             | {}                      | %w(semgrep-sast)
            'Javascript Node'      | { 'package.json' => '' }                        | {}                      | %w(nodejs-scan-sast)
            'HTML'                 | { 'index.html' => '' }                          | {}                      | %w(semgrep-sast)
            'Kubernetes Manifests' | { 'Chart.yaml' => '' }                          | ref(:kubernetes_vars)   | %w(kubesec-sast)
            'Multiple languages'   | { 'app.java' => '', 'app.js' => '' }            | {}                      | %w(semgrep-sast)
            'PHP'                  | { 'app.php' => '' }                             | {}                      | %w(phpcs-security-audit-sast)
            'Python'               | { 'app.py' => '' }                              | {}                      | %w(semgrep-sast)
            'Ruby'                 | { 'config/routes.rb' => '' }                    | {}                      | %w(brakeman-sast)
            'Scala'                | { 'app.scala' => '' }                           | {}                      | %w(semgrep-sast)
            'Scala'                | { 'app.sc' => '' }                              | {}                      | %w(semgrep-sast)
            'Typescript'           | { 'app.ts' => '' }                              | {}                      | %w(semgrep-sast)
            'Typescript JSX'       | { 'app.tsx' => '' }                             | {}                      | %w(semgrep-sast)
          end

          with_them do
            before do
              variables.each do |(key, value)|
                create(:ci_variable, project: project, key: key, value: value)
              end
            end

            context 'when branch pipeline' do
              it 'creates a pipeline with the expected jobs' do
                expect(pipeline.errors.full_messages).to be_empty
                expect(build_names).to include(*include_build_names)
              end
            end

            context 'when MR pipeline' do
              let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
              let(:feature_branch) { 'feature' }
              let(:pipeline) { service.execute(merge_request).payload }

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

              it 'creates a pipeline with the expected jobs' do
                expect(pipeline).to be_merge_request_event
                expect(pipeline.errors.full_messages).to be_empty
                expect(build_names).to include(*include_build_names)
              end
            end
          end
        end
      end
    end
  end
end
