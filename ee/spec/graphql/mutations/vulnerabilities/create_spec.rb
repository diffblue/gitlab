# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Create, feature_category: :vulnerability_management do
  include GraphqlHelpers
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user).tap { |user| project.add_developer(user) } }

  let(:mutated_vulnerability) { subject[:vulnerability] }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  describe '#resolve' do
    subject { resolve(described_class, args: attributes, ctx: { current_user: user }) }

    let(:identifier_attributes) do
      {
        name: "Test identifier",
        url: "https://vulnerabilities.com/test"
      }
    end

    let(:scanner_attributes) do
      {
        id: "my-custom-scanner",
        name: "My Custom Scanner",
        url: "https://superscanner.com",
        vendor: vendor_attributes,
        version: "21.37.00"
      }
    end

    let(:vendor_attributes) do
      {
        name: "Custom Scanner Vendor"
      }
    end

    let(:attributes) do
      {
        project: project_gid,
        name: "Test vulnerability",
        description: "Test vulnerability created via GraphQL",
        scanner: scanner_attributes,
        identifiers: [identifier_attributes],
        state: "detected",
        severity: "unknown",
        confidence: "unknown",
        solution: "rm -rf --no-preserve-root /",
        message: "You can't fix this"
      }
    end

    shared_examples 'successfully created vulnerability' do
      it 'returns the created vulnerability' do
        expect(mutated_vulnerability).to be_detected
        expect(mutated_vulnerability.description).to eq(attributes.dig(:description))
        expect(mutated_vulnerability.finding_description).to eq(attributes.dig(:description))
        expect(mutated_vulnerability.finding_message).to eq(attributes.dig(:message))
        expect(mutated_vulnerability.solution).to eq(attributes.dig(:solution))
        expect(subject[:errors]).to be_empty
      end
    end

    context 'when a vulnerability with the same identifier already exists' do
      let(:project_gid) { GitlabSchema.id_from_object(project) }

      before do
        resolve(described_class, args: attributes, ctx: { current_user: user })
      end

      it_behaves_like 'successfully created vulnerability'
    end

    context 'with valid parameters' do
      subject { resolve(described_class, args: attributes, ctx: { current_user: user }) }

      let(:project_gid) { GitlabSchema.id_from_object(project) }

      it_behaves_like 'successfully created vulnerability'

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
              name: "Test vulnerability",
              description: "Test vulnerability created via GraphQL",
              scanner: scanner_attributes,
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
            }.compact
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

        context 'when user is not authorized to create vulnerabilities' do
          let_it_be(:user) { create(:user).tap { |user| project.add_reporter(user) } }

          it 'raises an error' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
              subject
            end
          end
        end
      end
    end
  end
end
