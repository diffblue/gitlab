# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DAST-On-Demand-API-Scan.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-On-Demand-API-Scan') }

  specify { expect(template).not_to be_nil }

  describe 'template content' do
    let(:dast_on_demand_api_scan) { YAML.safe_load(template.content) }

    context 'when compared to DAST-API template' do
      let(:dast_api_template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST-API') }
      let(:dast_api) { YAML.safe_load(dast_api_template.content) }
      let(:dast_api_image_prefix) { dast_api["variables"]["SECURE_ANALYZERS_PREFIX"] }
      let(:dast_api_image_version) { dast_api["variables"]["DAST_API_VERSION"] }
      let(:dast_api_image_suffix) { dast_api["variables"]["DAST_API_IMAGE_SUFFIX"] }
      let(:dast_api_image_name) { dast_api["variables"]["DAST_API_IMAGE"] }
      let(:dast_api_image) { dast_api["dast_api"]["image"] }

      it 'includes the same DAST API image prefix' do
        prefix = dast_on_demand_api_scan["variables"]["SECURE_ANALYZERS_PREFIX"]
        expect(prefix).to eq(dast_api_image_prefix)
      end

      it 'includes the same DAST API image version' do
        version = dast_on_demand_api_scan["variables"]["DAST_API_VERSION"]
        expect(version).to eq(dast_api_image_version)
      end

      it 'includes the same DAST API image suffix' do
        suffix = dast_on_demand_api_scan["variables"]["DAST_API_IMAGE_SUFFIX"]
        expect(suffix).to eq(dast_api_image_suffix)
      end

      it 'includes the same DAST API image name' do
        name = dast_on_demand_api_scan["variables"]["DAST_API_IMAGE"]
        expect(name).to eq(dast_api_image_name)
      end

      it 'computes the same DAST API image' do
        image = dast_on_demand_api_scan["dast"]["image"]
        expect(image).to eq(dast_api_image)
      end
    end
  end
end
