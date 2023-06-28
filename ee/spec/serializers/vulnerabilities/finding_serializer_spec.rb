# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingSerializer, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:serializer) do
    described_class.new(current_user: user)
  end

  let(:opts) { {} }

  subject { serializer.represent(resource, opts) }

  shared_examples '#represent' do
    context 'when used without pagination' do
      it 'created a not paginated serializer' do
        expect(serializer).not_to be_paginated
      end

      context 'when a single object is being serialized' do
        let(:resource) { create(:vulnerabilities_finding, project: project) }

        it 'serializers the vulnerability finding object' do
          expect(subject[:id]).to eq resource.id
        end
      end

      context 'when multiple objects are being serialized' do
        let(:resource) { create_list(:vulnerabilities_finding, 2, project: project) }

        it 'serializers the array of vulnerability finding object' do
          expect(subject.count).to be 2
        end
      end
    end

    context 'when used with pagination' do
      let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
      let(:response) { spy('response') }
      let(:query) { {} }

      let(:serializer) do
        described_class.new(current_user: user)
          .with_pagination(request, response)
      end

      it 'created a paginated serializer' do
        expect(serializer).to be_paginated
      end

      context 'when resource is not paginatable' do
        context 'when a single vulnerability finding object is being serialized' do
          let(:resource) { create(:vulnerabilities_finding) }
          let(:query) { { page: 1, per_page: 1 } }

          it 'raises error' do
            expect { subject }.to raise_error(
              Gitlab::Serializer::Pagination::InvalidResourceError)
          end
        end
      end

      context 'when resource is paginatable relation' do
        let(:resource) { Vulnerabilities::Finding.all }
        let(:query) { { page: 1, per_page: 2 } }

        context 'when a single vulnerability finding object is present in relation' do
          before do
            create(:vulnerabilities_finding)
          end

          it 'serializes vulnerability finding relation' do
            expect(subject.first).to have_key :id
          end
        end

        context 'when multiple vulnerability finding objects are being serialized' do
          before do
            create_list(:vulnerabilities_finding, 3)
          end

          it 'serializes appropriate number of objects' do
            expect(subject.count).to be 2
          end

          it 'append relevant headers' do
            expect(response).to receive(:[]=).with('X-Total', '3')
            expect(response).to receive(:[]=).with('X-Total-Pages', '2')
            expect(response).to receive(:[]=).with('X-Per-Page', '2')

            subject
          end
        end
      end
    end
  end

  include_examples '#represent'
end
