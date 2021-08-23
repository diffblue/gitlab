# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Create do
  include GraphqlHelpers
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) }
  let(:mutated_vulnerability) { subject[:vulnerability] }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  describe '#resolve' do
    using RSpec::Parameterized::TableSyntax

    context 'when a vulnerability with the same identifier already exists' do
      subject { resolve(described_class, args: attributes, ctx: { current_user: user }) }

      let(:project_gid) { GitlabSchema.id_from_object(project) }

      let(:identifier_attributes) do
        {
          name: "Test identifier",
          url: "https://vulnerabilities.com/test"
        }
      end

      let(:attributes) do
        {
          project: project_gid,
          title: "Test vulnerability",
          description: "Test vulnerability created via GraphQL",
          scanner_type: "dast",
          scanner_name: "My custom DAST scanner",
          identifiers: [identifier_attributes],
          state: "detected",
          severity: "unknown",
          confidence: "unknown",
          solution: "rm -rf --no-preserve-root /",
          message: "You can't fix this"
        }
      end

      before do
        project.add_developer(user)
        resolve(described_class, args: attributes, ctx: { current_user: user })
      end

      it 'returns the created vulnerability' do
        expect(subject[:errors]).to contain_exactly("Vulnerability with those details already exists")
      end
    end

    context 'with valid parameters' do
      before do
        project.add_developer(user)
      end

      subject { resolve(described_class, args: attributes, ctx: { current_user: user }) }

      let(:project_gid) { GitlabSchema.id_from_object(project) }

      let(:identifier_attributes) do
        {
          name: "Test identifier",
          url: "https://vulnerabilities.com/test"
        }
      end

      let(:attributes) do
        {
          project: project_gid,
          title: "Test vulnerability",
          description: "Test vulnerability created via GraphQL",
          scanner_type: "dast",
          scanner_name: "My custom DAST scanner",
          identifiers: [identifier_attributes],
          state: "detected",
          severity: "unknown",
          confidence: "unknown",
          solution: "rm -rf --no-preserve-root /",
          message: "You can't fix this"
        }
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(create_vulnerabilities_via_api: false)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when feature flag is enabled' do
        before do
          stub_feature_flags(create_vulnerabilities_via_api: project)
        end

        it 'returns the created vulnerability' do
          expect(mutated_vulnerability).to be_detected
          expect(subject[:errors]).to be_empty
        end

        context 'with custom state' do
          let(:custom_timestamp) { Time.new(2020, 6, 21, 14, 22, 20) }

          where(:state, :detected_at, :confirmed_at, :confirmed_by, :resolved_at, :resolved_by, :dismissed_at, :dismissed_by) do
            [
              ['confirmed', ref(:custom_timestamp), ref(:custom_timestamp), ref(:user), nil, nil, nil, nil],
              ['resolved', ref(:custom_timestamp), nil, nil, ref(:custom_timestamp), ref(:user), nil, nil],
              ['dismissed', ref(:custom_timestamp), nil, nil, nil, nil, ref(:custom_timestamp), ref(:user)]
            ]
          end

          with_them do
            let(:attributes) do
              {
                project: project_gid,
                title: "Test vulnerability",
                description: "Test vulnerability created via GraphQL",
                scanner_type: "dast",
                scanner_name: "My custom DAST scanner",
                identifiers: [identifier_attributes],
                state: state,
                severity: "unknown",
                confidence: "unknown",
                detected_at: detected_at,
                confirmed_at: confirmed_at,
                resolved_at: resolved_at,
                dismissed_at: dismissed_at,
                solution: "rm -rf --no-preserve-root /",
                message: "You can't fix this"
              }
            end

            it "returns a #{params[:state]} vulnerability", :aggregate_failures do
              expect(mutated_vulnerability.state).to eq(state)

              expect(mutated_vulnerability.detected_at).to eq(detected_at)

              expect(mutated_vulnerability.confirmed_at).to eq(confirmed_at)
              expect(mutated_vulnerability.confirmed_by).to eq(confirmed_by)

              expect(mutated_vulnerability.resolved_at).to eq(resolved_at)
              expect(mutated_vulnerability.resolved_by).to eq(resolved_by)

              expect(mutated_vulnerability.dismissed_at).to eq(dismissed_at)
              expect(mutated_vulnerability.dismissed_by).to eq(dismissed_by)

              expect(subject[:errors]).to be_empty
            end
          end
        end
      end
    end
  end
end
