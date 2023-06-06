# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::DefaultBranchImageValidator do
  let_it_be(:project) { create(:project) }

  let(:validator) { described_class.new(project) }

  shared_examples 'when asked for same image multiple times' do
    it 'queries database only once per image name' do
      expect { [validator.valid?(image_name), validator.valid?('alpine:3.12'), validator.valid?(image_name)] }
        .not_to exceed_query_limit(2)
    end
  end

  describe '#valid?' do
    subject(:is_valid) { validator.valid?(image_name) }

    context 'when image name is blank' do
      let(:image_name) { '' }

      it { is_expected.to be false }
    end

    context 'when image name is present' do
      let(:image_name) { 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0/main:latest-sha' }

      context 'when there is no vulnerability with given location for project' do
        it { is_expected.to be false }

        include_examples 'when asked for same image multiple times'
      end

      context 'when there is at least one vulnerability with given location for project' do
        let_it_be(:vulnerability) { create(:vulnerability, report_type: :container_scanning, project: project) }
        let_it_be(:finding) do
          create(:vulnerabilities_finding,
            :with_container_scanning_metadata,
            image: 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0/main:new-mr-sha',
            vulnerability: vulnerability
          )
        end

        it { is_expected.to be true }

        include_examples 'when asked for same image multiple times'
      end
    end
  end
end
