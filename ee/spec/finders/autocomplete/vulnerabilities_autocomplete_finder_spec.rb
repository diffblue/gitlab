# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::VulnerabilitiesAutocompleteFinder, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:group, refind: true) { create(:group) }
    let_it_be(:project, refind: true) { create(:project, group: group) }
    let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }

    let(:params) { {} }

    subject { described_class.new(user, vulnerable, params).execute }

    shared_examples 'autocomplete vulnerabilities finder' do
      context 'when the given user is nil' do
        let(:user) { nil }

        it { is_expected.to be_empty }
      end

      context 'when the given user is not nil' do
        let_it_be(:user) { create(:user) }

        context 'when user does not have access to project' do
          it { is_expected.to be_empty }
        end

        context 'when user has access to project' do
          before do
            vulnerable.add_developer(user)
          end

          context 'when security dashboards are not enabled' do
            it { is_expected.to be_empty }
          end

          context 'when security dashboards are enabled' do
            before do
              stub_licensed_features(security_dashboard: true)
            end

            it { is_expected.to match_array([vulnerability]) }

            context 'when multiple vulnerabilities are found' do
              before do
                create_list(:vulnerability, 10, :with_finding, project: project)
              end

              it 'returns max 5 items' do
                expect(subject.count).to eq(5)
              end

              it 'is sorted descending by id' do
                expect(subject).to be_sorted(:id, :desc)
              end
            end

            context 'when search is provided in params' do
              context 'and it matches ID of vulnerability' do
                let(:params) { { search: vulnerability.id.to_s } }

                it { is_expected.to match_array([vulnerability]) }
              end

              context 'and it matches title of vulnerability' do
                let(:params) { { search: vulnerability.title } }

                it { is_expected.to match_array([vulnerability]) }
              end

              context 'and it does not match neither title or id of vulnerability' do
                let(:params) { { search: non_existing_record_id.to_s } }

                it { is_expected.to be_empty }
              end
            end
          end
        end
      end
    end

    context 'when vulnerable is project' do
      let(:vulnerable) { project }

      it_behaves_like 'autocomplete vulnerabilities finder'
    end

    context 'when vulnerable is group' do
      let(:vulnerable) { group }

      it_behaves_like 'autocomplete vulnerabilities finder'
    end
  end
end
