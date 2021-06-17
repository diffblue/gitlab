# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAST.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('SAST') }

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
      context 'when SAST_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'when SAST_EXPERIMENTAL_FEATURES is disabled for iOS projects' do
        let(:files) { { 'a.xcodeproj/x.pbxproj' => '' } }

        before do
          create(:ci_variable, project: project, key: 'SAST_EXPERIMENTAL_FEATURES', value: 'false')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
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
            'C#'                   | { 'app.csproj' => '' }                          | {}                                         | %w(security-code-scan-sast)
            'Elixir'               | { 'mix.exs' => '' }                             | {}                                         | %w(sobelow-sast)
            'Golang'               | { 'main.go' => '' }                             | {}                                         | %w(gosec-sast)
            'Groovy'               | { 'app.groovy' => '' }                          | {}                                         | %w(spotbugs-sast)
            ios                    | { 'a.xcodeproj/x.pbxproj' => '' }               | sast_experimental_features                 | mobsf_ios_build
            ios                    | { 'a/b/ios.ipa' => '' }                         | sast_experimental_features                 | mobsf_ios_build
            'Java'                 | { 'app.java' => '' }                            | {}                                         | %w(spotbugs-sast)
            'Java with MobSF'      | { 'app.java' => '' }                            | sast_experimental_features                 | %w(spotbugs-sast)
            'Java without MobSF'   | { 'AndroidManifest.xml' => '', 'a.java' => '' } | {}                                         | %w(spotbugs-sast)
            'Javascript'           | { 'app.js' => '' }                              | {}                                         | %w(eslint-sast semgrep-sast)
            'JSX'                  | { 'app.jsx' => '' }                             | {}                                         | %w(eslint-sast semgrep-sast)
            'Javascript Node'      | { 'package.json' => '' }                        | {}                                         | %w(nodejs-scan-sast)
            'HTML'                 | { 'index.html' => '' }                          | {}                                         | %w(eslint-sast)
            'Kubernetes Manifests' | { 'Chart.yaml' => '' }                          | { 'SCAN_KUBERNETES_MANIFESTS' => 'true' }  | %w(kubesec-sast)
            'Multiple languages'   | { 'app.java' => '', 'app.js' => '' }            | {}                                         | %w(eslint-sast spotbugs-sast)
            'PHP'                  | { 'app.php' => '' }                             | {}                                         | %w(phpcs-security-audit-sast)
            'Python'               | { 'app.py' => '' }                              | {}                                         | %w(bandit-sast semgrep-sast)
            'Ruby'                 | { 'config/routes.rb' => '' }                    | {}                                         | %w(brakeman-sast)
            'Scala'                | { 'app.scala' => '' }                           | {}                                         | %w(spotbugs-sast)
            'Typescript'           | { 'app.ts' => '' }                              | {}                                         | %w(eslint-sast semgrep-sast)
            'Typescript JSX'       | { 'app.tsx' => '' }                             | {}                                         | %w(eslint-sast semgrep-sast)
            'Visual Basic'         | { 'app.vbproj' => '' }                          | {}                                         | %w(security-code-scan-sast)
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
