# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::Incidents::UploadMetricService, feature_category: :incident_management do
  subject(:service) { described_class.new(issuable, current_user, params) }

  let_it_be_with_refind(:project) { create(:project) }
  let_it_be_with_refind(:issuable) { create(:incident, project: project) }
  let_it_be_with_refind(:current_user) { create(:user) }

  let(:params) do
    {
      file: fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg'),
      url: 'https://www.gitlab.com'
    }
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'uploads the metric' do
      it 'uploads the metric and returns a success' do
        expect { subject }.to change(IssuableMetricImage, :count).by(1)
        expect(subject.success?).to eq(true)
        expect(subject.payload).to match({ metric: instance_of(IssuableMetricImage), issuable: issuable })
      end
    end

    shared_examples 'no metric saved, an error given' do |message|
      it 'returns an error and does not upload', :aggregate_failures do
        expect(subject.success?).to eq(false)
        expect(subject.message).to match(a_string_matching(message))
        expect(IssuableMetricImage.count).to eq(0)
      end
    end

    context 'user does not have permissions' do
      it_behaves_like 'no metric saved, an error given', 'Not allowed!'
    end

    context 'user has permissions' do
      before_all do
        project.add_developer(current_user)
      end

      it_behaves_like 'no metric saved, an error given', 'Not allowed!'

      context 'with license' do
        before do
          stub_licensed_features(incident_metric_upload: true)
        end

        it_behaves_like 'uploads the metric'

        context 'no url given' do
          let(:params) do
            {
              file: fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg')
            }
          end

          it_behaves_like 'uploads the metric'
        end

        context 'record invalid' do
          let(:params) do
            {
              file: fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain'),
              url: 'https://www.gitlab.com'
            }
          end

          it_behaves_like 'no metric saved, an error given', /Validation failed/
        end

        context 'user is guest' do
          before_all do
            project.add_guest(current_user)
          end

          it_behaves_like 'no metric saved, an error given', 'Not allowed!'

          context 'guest is author of issuable' do
            let(:issuable) { create(:incident, project: project, author: current_user) }

            it_behaves_like 'no metric saved, an error given', 'Not allowed!'
          end
        end
      end
    end
  end
end
