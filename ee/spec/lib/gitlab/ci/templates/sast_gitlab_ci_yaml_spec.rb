# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAST.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('SAST') }

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:files) { { 'README.txt' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      context 'when SAST_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
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
          sast_experimental_features = { 'SAST_EXPERIMENTAL_FEATURES' => 'true' }
          android = 'Android'
          ios = 'iOS'
          mobsf_android_build = %w(mobsf-android-sast)
          mobsf_ios_build = %w(mobsf-ios-sast)

          using RSpec::Parameterized::TableSyntax

          where(:case_name, :files, :variables, :include_build_names) do
            android                | { 'AndroidManifest.xml' => '', 'a.java' => '' } | sast_experimental_features                 | mobsf_android_build
            android                | { 'app/src/main/AndroidManifest.xml' => '' }    | sast_experimental_features                 | mobsf_android_build
            android                | { 'a/b/AndroidManifest.xml' => '' }             | sast_experimental_features                 | mobsf_android_build
            android                | { 'a/b/android.apk' => '' }                     | sast_experimental_features                 | mobsf_android_build
            android                | { 'android.apk' => '' }                         | sast_experimental_features                 | mobsf_android_build
            'Apex'                 | { 'app.cls' => '' }                             | {}                                         | %w(pmd-apex-sast)
            'C'                    | { 'app.c' => '' }                               | {}                                         | %w(flawfinder-sast)
            'C++'                  | { 'app.cpp' => '' }                             | {}                                         | %w(flawfinder-sast)
            'C#'                   | { 'app.cs' => '' }                              | {}                                         | %w(semgrep-sast)
            'Elixir'               | { 'mix.exs' => '' }                             | {}                                         | %w(sobelow-sast)
            'Elixir, nested'       | { 'a/b/mix.exs' => '' }                         | {}                                         | %w(sobelow-sast)
            'Golang'               | { 'main.go' => '' }                             | {}                                         | %w(semgrep-sast)
            'Groovy'               | { 'app.groovy' => '' }                          | {}                                         | %w(spotbugs-sast)
            ios                    | { 'a.xcodeproj/x.pbxproj' => '' }               | sast_experimental_features                 | mobsf_ios_build
            ios                    | { 'a/b/ios.ipa' => '' }                         | sast_experimental_features                 | mobsf_ios_build
            'Java'                 | { 'app.java' => '' }                            | {}                                         | %w(semgrep-sast)
            'Java with MobSF'      | { 'app.java' => '' }                            | sast_experimental_features                 | %w(semgrep-sast)
            'Java without MobSF'   | { 'AndroidManifest.xml' => '', 'a.java' => '' } | {}                                         | %w(semgrep-sast)
            'Javascript'           | { 'app.js' => '' }                              | {}                                         | %w(semgrep-sast)
            'JSX'                  | { 'app.jsx' => '' }                             | {}                                         | %w(semgrep-sast)
            'Javascript Node'      | { 'package.json' => '' }                        | {}                                         | %w(nodejs-scan-sast)
            'HTML'                 | { 'index.html' => '' }                          | {}                                         | %w(semgrep-sast)
            'Kubernetes Manifests' | { 'Chart.yaml' => '' }                          | { 'SCAN_KUBERNETES_MANIFESTS' => 'true' }  | %w(kubesec-sast)
            'Multiple languages'   | { 'app.java' => '', 'app.js' => '', 'app.php' => '' } | {}                                   | %w(semgrep-sast phpcs-security-audit-sast)
            'PHP'                  | { 'app.php' => '' }                             | {}                                         | %w(phpcs-security-audit-sast)
            'Python'               | { 'app.py' => '' }                              | {}                                         | %w(semgrep-sast)
            'Ruby'                 | { 'config/routes.rb' => '' }                    | {}                                         | %w(brakeman-sast)
            'Scala'                | { 'app.scala' => '' }                           | {}                                         | %w(spotbugs-sast)
            'Scala'                | { 'app.scala' => '' }                           | {}                                         | %w(semgrep-sast)
            'Scala'                | { 'app.sc' => '' }                              | {}                                         | %w(semgrep-sast)
            'Typescript'           | { 'app.ts' => '' }                              | {}                                         | %w(semgrep-sast)
            'Typescript JSX'       | { 'app.tsx' => '' }                             | {}                                         | %w(semgrep-sast)
          end

          with_them do
            before do
              variables.each do |(key, value)|
                create(:ci_variable, project: project, key: key, value: value)
              end
            end

            it 'creates a pipeline with the expected jobs' do
              expect(build_names).to include(*include_build_names)
            end
          end
        end
      end
    end
  end
end
