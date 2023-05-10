# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SoftwareLicensePolicies::CreateService, feature_category: :security_policy_management do
  let(:project) { create(:project) }
  let(:params) { { name: 'ExamplePL/2.1', approval_status: 'denied' } }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  before do
    stub_licensed_features(license_scanning: true)
  end

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with license management unavailable' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      it 'does not creates a software license policy' do
        expect { subject.execute }.to change { project.software_license_policies.count }.by(0)
      end
    end

    context 'with a user who is allowed to admin' do
      before do
        # We disable the check because the specs are wrapped in a transaction
        allow(SoftwareLicense).to receive(:transaction_open?).and_return(false)
      end

      context 'when valid parameters are specified' do
        let(:params) { { name: 'MIT', approval_status: 'allowed' } }
        let(:result) { subject.execute }

        before do
          result
        end

        it 'creates one software license policy correctly' do
          expect(project.software_license_policies.count).to be(1)
          expect(result[:status]).to be(:success)
          expect(result[:software_license_policy]).to be_present
          expect(result[:software_license_policy]).to be_persisted
          expect(result[:software_license_policy].name).to eq(params[:name])
          expect(result[:software_license_policy].classification).to eq(params[:approval_status])
        end

        context 'when name contains whitespaces' do
          let(:params) { { name: '  MIT   ', approval_status: 'allowed' } }

          it 'creates one software license policy with stripped name' do
            expect(project.software_license_policies.count).to be(1)
            expect(result[:status]).to be(:success)
            expect(result[:software_license_policy]).to be_persisted
            expect(result[:software_license_policy].name).to eq('MIT')
          end
        end
      end

      context "when an argument error is raised" do
        before do
          allow_next_instance_of(Project) do |instance|
            allow(instance).to receive(:software_license_policies).and_raise(ArgumentError)
          end
        end

        specify { expect(subject.execute[:status]).to be(:error) }
        specify { expect(subject.execute[:message]).to be_present }
        specify { expect(subject.execute[:http_status]).to be(400) }
      end

      context "when invalid input is provided" do
        before do
          params[:approval_status] = nil
        end

        specify { expect(subject.execute[:status]).to be(:error) }
        specify { expect(subject.execute[:message]).to be_present }
        specify { expect(subject.execute[:http_status]).to be(400) }
      end
    end

    context 'with a user not allowed to admin' do
      let(:user) { create(:user) }

      it 'does not create a software license policy' do
        expect { subject.execute }.to change { project.software_license_policies.count }.by(0)
      end

      context 'when is_scan_result_policy is set' do
        it 'creates software license policy' do
          result = subject.execute(is_scan_result_policy: true)

          expect(project.software_license_policies.count).to be(1)
          expect(result[:status]).to be(:success)
          expect(result[:software_license_policy]).to be_present
          expect(result[:software_license_policy]).to be_persisted
          expect(result[:software_license_policy].name).to eq(params[:name])
          expect(result[:software_license_policy].classification).to eq(params[:approval_status])
        end

        it 'calls unsafe_create_policy_for' do
          expect(SoftwareLicense).to receive(:unsafe_create_policy_for!).with(
            project: project,
            classification: 'denied',
            name: params[:name],
            scan_result_policy_read: params[:scan_result_policy_read]
          ).and_call_original

          subject.execute(is_scan_result_policy: true)
        end
      end
    end
  end
end
