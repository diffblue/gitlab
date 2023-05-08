# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure-Binaries.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Secure-Binaries') }

  specify { expect(template).not_to be_nil }

  describe 'template content' do
    let(:secure_binaries) { YAML.safe_load(template.content) }
    let(:secure_binaries_analyzers) { secure_binaries["variables"]["SECURE_BINARIES_ANALYZERS"].split(%r{\s*,\s*}) }
    let(:secure_analyzers_prefix) { secure_binaries["variables"]["SECURE_ANALYZERS_PREFIX"] }

    context 'when compared to DAST-API template' do
      let(:dast_api_template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-API') }
      let(:dast_api) { YAML.safe_load(dast_api_template.content) }
      let(:dast_api_image_prefix) { dast_api["variables"]["SECURE_ANALYZERS_PREFIX"] }
      let(:dast_api_image_version) { dast_api["variables"]["DAST_API_VERSION"] }
      let(:dast_api_image_name) { dast_api["variables"]["DAST_API_IMAGE"] }

      it 'includes the same DAST API image prefix' do
        expect(secure_analyzers_prefix).to eq(dast_api_image_prefix)
      end

      it 'includes the DAST API image name in secure binary analyzers' do
        expect(secure_binaries_analyzers).to include(dast_api_image_name)
      end

      it 'includes a job named after the DAST API image name' do
        expect(secure_binaries.has_key?(dast_api_image_name)).to be true
      end

      it 'includes the same DAST API image version' do
        version = secure_binaries[dast_api_image_name]["variables"]["SECURE_BINARIES_ANALYZER_VERSION"]
        expect(version).to eq(dast_api_image_version)
      end

      it 'filters the secure binary analyzers by the DAST API image name' do
        only_variables = secure_binaries[dast_api_image_name]["only"]["variables"][0]
        filter_expr = "$SECURE_BINARIES_ANALYZERS =~ /\\b#{dast_api_image_name}\\b/"
        expect(only_variables).to include(filter_expr)
      end
    end

    context 'when compared to DAST-API.latest template' do
      let(:dast_api_latest_template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-API.latest') }
      let(:dast_api_latest) { YAML.safe_load(dast_api_latest_template.content) }
      let(:dast_api_latest_image_prefix) { dast_api_latest["variables"]["SECURE_ANALYZERS_PREFIX"] }
      let(:dast_api_latest_image_version) { dast_api_latest["variables"]["DAST_API_VERSION"] }
      let(:dast_api_latest_image_name) { dast_api_latest["variables"]["DAST_API_IMAGE"] }

      it 'includes the same DAST API image prefix' do
        expect(secure_analyzers_prefix).to eq(dast_api_latest_image_prefix)
      end

      it 'includes the DAST API image name in secure binary analyzers' do
        expect(secure_binaries_analyzers).to include(dast_api_latest_image_name)
      end

      it 'includes a job named after the DAST API image name' do
        expect(secure_binaries.has_key?(dast_api_latest_image_name)).to be true
      end

      it 'includes the same DAST API image version' do
        version = secure_binaries[dast_api_latest_image_name]["variables"]["SECURE_BINARIES_ANALYZER_VERSION"]
        expect(version).to eq(dast_api_latest_image_version)
      end

      it 'filters the secure binary analyzers by the DAST API image name' do
        only_variables = secure_binaries[dast_api_latest_image_name]["only"]["variables"][0]
        filter_expr = "$SECURE_BINARIES_ANALYZERS =~ /\\b#{dast_api_latest_image_name}\\b/"
        expect(only_variables).to include(filter_expr)
      end
    end

    context 'when compared to API-Fuzzing template' do
      let(:api_fuzzing_template) { Gitlab::Template::GitlabCiYmlTemplate.find('API-Fuzzing') }
      let(:api_fuzzing) { YAML.safe_load(api_fuzzing_template.content) }
      let(:api_fuzzing_image_prefix) { api_fuzzing["variables"]["SECURE_ANALYZERS_PREFIX"] }
      let(:api_fuzzing_image_version) { api_fuzzing["variables"]["FUZZAPI_VERSION"] }
      let(:api_fuzzing_image_name) { api_fuzzing["variables"]["FUZZAPI_IMAGE"] }

      it 'includes the same API Fuzzing image prefix' do
        expect(secure_analyzers_prefix).to eq(api_fuzzing_image_prefix)
      end

      it 'includes the API Fuzzing image name in secure binary analyzers' do
        expect(secure_binaries_analyzers).to include(api_fuzzing_image_name)
      end

      it 'includes a job named after the API Fuzzing image name' do
        expect(secure_binaries.has_key?(api_fuzzing_image_name)).to be true
      end

      it 'includes the same API Fuzzing image version' do
        version = secure_binaries[api_fuzzing_image_name]["variables"]["SECURE_BINARIES_ANALYZER_VERSION"]
        expect(version).to eq(api_fuzzing_image_version)
      end

      it 'filters the secure binary analyzers by the API Fuzzing image name' do
        only_variables = secure_binaries[api_fuzzing_image_name]["only"]["variables"][0]
        filter_expr = "$SECURE_BINARIES_ANALYZERS =~ /\\b#{api_fuzzing_image_name}\\b/"
        expect(only_variables).to include(filter_expr)
      end
    end

    context 'when compared to API-Fuzzing.latest template' do
      let(:api_fuzzing_latest_template) { Gitlab::Template::GitlabCiYmlTemplate.find('API-Fuzzing.latest') }
      let(:api_fuzzing_latest) { YAML.safe_load(api_fuzzing_latest_template.content) }
      let(:api_fuzzing_latest_image_prefix) { api_fuzzing_latest["variables"]["SECURE_ANALYZERS_PREFIX"] }
      let(:api_fuzzing_latest_image_version) { api_fuzzing_latest["variables"]["FUZZAPI_VERSION"] }
      let(:api_fuzzing_latest_image_name) { api_fuzzing_latest["variables"]["FUZZAPI_IMAGE"] }

      it 'includes the same API Fuzzing image prefix' do
        expect(secure_analyzers_prefix).to eq(api_fuzzing_latest_image_prefix)
      end

      it 'includes the API Fuzzing image name in secure binary analyzers' do
        expect(secure_binaries_analyzers).to include(api_fuzzing_latest_image_name)
      end

      it 'includes a job named after the API Fuzzing image name' do
        expect(secure_binaries.has_key?(api_fuzzing_latest_image_name)).to be true
      end

      it 'includes the same API Fuzzing image version' do
        version = secure_binaries[api_fuzzing_latest_image_name]["variables"]["SECURE_BINARIES_ANALYZER_VERSION"]
        expect(version).to eq(api_fuzzing_latest_image_version)
      end

      it 'filters the secure binary analyzers by the API Fuzzing image name' do
        only_variables = secure_binaries[api_fuzzing_latest_image_name]["only"]["variables"][0]
        filter_expr = "$SECURE_BINARIES_ANALYZERS =~ /\\b#{api_fuzzing_latest_image_name}\\b/"
        expect(only_variables).to include(filter_expr)
      end
    end
  end

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }

    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)

      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end

      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    shared_examples 'an offline image download job' do
      let(:build) { pipeline.builds.find_by(name: build_name) }

      it 'creates the job' do
        expect(build_names).to include(build_name)
      end

      it 'sets SECURE_BINARIES_ANALYZER_VERSION to the correct version' do
        expect(build.variables.to_hash).to include('SECURE_BINARIES_ANALYZER_VERSION' => String(version))
      end
    end

    describe 'dast' do
      let_it_be(:build_name) { 'dast' }
      let_it_be(:version) { 2 }

      it_behaves_like 'an offline image download job'
    end

    describe 'dast-runner-validation' do
      let_it_be(:build_name) { 'dast-runner-validation' }
      let_it_be(:version) { 1 }

      it_behaves_like 'an offline image download job' do
        it 'sets SECURE_BINARIES_IMAGE explicitly' do
          image = "${CI_TEMPLATE_REGISTRY_HOST}/security-products/${CI_JOB_NAME}:${SECURE_BINARIES_ANALYZER_VERSION}"

          expect(build.variables.to_hash).to include('SECURE_BINARIES_IMAGE' => image)
        end
      end
    end

    describe 'api-security' do
      let_it_be(:build_name) { 'api-security' }
      let_it_be(:version) { 3 }

      it_behaves_like 'an offline image download job' do
        it 'sets SECURE_BINARIES_ANALYZER_VERSION explicitly' do
          api_security_analyzer_version = "3"

          expect(build.variables.to_hash).to include(
            'SECURE_BINARIES_ANALYZER_VERSION' => api_security_analyzer_version)
        end
      end
    end
  end
end
