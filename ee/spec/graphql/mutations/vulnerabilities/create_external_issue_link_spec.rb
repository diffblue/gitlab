# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::CreateExternalIssueLink, feature_category: :vulnerability_management do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:vulnerability) { create(:vulnerability, :with_findings) }
    let_it_be(:user) { create(:user) }

    context 'for JIRA external tracker and CREATED issue link' do
      subject { mutation.resolve(id: GitlabSchema.id_from_object(vulnerability), link_type: 'created', external_tracker: 'jira') }

      context 'when the project can have external issue links' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'when user does not have access to the project' do
          it 'raises an error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when user has access to the project' do
          before do
            vulnerability.project.add_developer(user)
            allow_next_instance_of(::VulnerabilityExternalIssueLinks::CreateService) do |create_service|
              allow(create_service).to receive(:execute).and_return(result)
            end
          end

          context 'when issue creation fails' do
            let(:result) { double(success?: false, payload: {}, errors: ['Error when creating issue in Jira']) }

            it 'returns empty external issue link' do
              expect(subject[:external_issue_link]).to be_nil
            end

            it 'returns error collection' do
              expect(subject[:errors]).to eq(['Error when creating issue in Jira'])
            end
          end

          context 'when issue creation succeeds' do
            let_it_be(:external_issue_link) { build(:vulnerabilities_external_issue_link) }

            let(:result) { double(success?: true, payload: { record: external_issue_link }, errors: []) }

            it 'returns empty external issue link' do
              expect(subject[:external_issue_link]).to eq(external_issue_link)
            end

            it 'returns empty error collection' do
              expect(subject[:errors]).to be_empty
            end
          end
        end
      end
    end
  end
end
