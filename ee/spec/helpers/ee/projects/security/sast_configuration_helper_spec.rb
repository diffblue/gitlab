# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::SastConfigurationHelper do
  let_it_be(:project) { create(:project) }

  let(:project_path) { project.full_path }
  let(:docs_path) { help_page_path('user/application_security/sast/index', anchor: 'configuration') }
  let(:analyzers_docs_path) { help_page_path('user/application_security/sast/analyzers') }

  describe '#sast_configuration_data' do
    subject { helper.sast_configuration_data(project) }

    it {
      is_expected.to eq({
        project_path: project_path,
        sast_documentation_path: docs_path,
        security_configuration_path: project_security_configuration_path(project)
      })
    }
  end
end
