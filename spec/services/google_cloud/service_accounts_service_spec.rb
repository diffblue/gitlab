# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::ServiceAccountsService do
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(project) }

  describe 'find_for_project' do
    context 'when a project does not have GCP service account vars' do
      before do
        project.variables.build(key: 'blah', value: 'foo', environment_scope: 'world')
        project.save!
      end

      it 'returns an empty list' do
        expect(service.find_for_project.length).to equal(0)
      end
    end

    context 'when a project has GCP service account ci vars' do
      before do
        project.variables.build(environment_scope: '*', key: 'GCP_PROJECT_ID', value: 'prj1')
        project.variables.build(environment_scope: '*', key: 'GCP_SERVICE_ACCOUNT_KEY', value: '')
        project.variables.build(environment_scope: 'staging', key: 'GCP_PROJECT_ID', value: 'prj2')
        project.variables.build(environment_scope: 'staging', key: 'GCP_SERVICE_ACCOUNT', value: '')
        project.variables.build(environment_scope: 'production', key: 'GCP_PROJECT_ID', value: 'prj3')
        project.variables.build(environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT', value: '')
        project.variables.build(environment_scope: 'production', key: 'GCP_SERVICE_ACCOUNT_KEY', value: '')
        project.save!
      end

      it 'returns a list of service accounts' do
        list = service.find_for_project
        first = list[0]
        second = list[1]
        third = list[2]

        expect(list.length).to equal(3)

        expect(first[:environment]).to equal('*')
        expect(first[:gcp_project]).to equal('prj1')
        expect(first[:service_account_exists]).to equal(false)
        expect(first[:service_account_key_exists]).to equal(true)

        expect(second[:environment]).to equal('staging')
        expect(second[:gcp_project]).to equal('prj2')
        expect(second[:service_account_exists]).to equal(true)
        expect(second[:service_account_key_exists]).to equal(false)

        expect(third[:environment]).to equal('production')
        expect(third[:gcp_project]).to equal('prj3')
        expect(third[:service_account_exists]).to equal(true)
        expect(third[:service_account_key_exists]).to equal(true)
      end
    end
  end
end
