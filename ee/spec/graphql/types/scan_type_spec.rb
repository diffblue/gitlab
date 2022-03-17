# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Scan'] do
  include GraphqlHelpers

  let(:fields) { %i(name errors warnings status) }

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_scan) }

  describe 'field values' do
    let_it_be(:build) { create(:ee_ci_build, :dast, name: 'foo') }
    let_it_be(:security_scan) { build.security_scans.first }
    let_it_be(:user) { create(:user) }

    subject { resolve_field(field_name, security_scan, current_user: user) }

    before do
      stub_licensed_features(security_dashboard: true)

      build.project.add_developer(user)
    end

    describe 'name' do
      let(:field_name) { :name }

      it { is_expected.to eq('foo') }
    end

    describe 'errors' do
      let(:field_name) { :errors }

      before do
        security_scan.update!(info: { 'errors' => [{ 'type' => 'foo', 'message' => 'bar' }] })
      end

      it { is_expected.to match_array(['[foo] bar']) }
    end

    describe 'warnings' do
      let(:field_name) { :warnings }

      before do
        security_scan.update!(info: { 'warnings' => [{ 'type' => 'foo', 'message' => 'bar' }] })
      end

      it { is_expected.to match_array(['[foo] bar']) }
    end

    describe 'status' do
      let(:field_name) { :status }

      it { is_expected.to eq('created') }
    end
  end
end
