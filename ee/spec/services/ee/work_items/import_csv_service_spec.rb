# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ImportCsvService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user, username: 'csv_author') }
  let(:file) { fixture_file_upload('ee/spec/fixtures/work_items_valid_types.csv') }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  let_it_be(:issue_type) { ::WorkItems::Type.default_issue_type }
  let_it_be(:requirement_type) { ::WorkItems::Type.default_by_type(:requirement) }

  let(:work_items) { ::WorkItems::WorkItemsFinder.new(user, project: project).execute }

  subject { service.execute }

  describe '#execute', :aggregate_failures do
    before do
      project.add_maintainer(user)
      stub_licensed_features(requirements: true)
    end

    context 'when file is valid' do
      context 'when all types are available' do
        it 'creates the expected number of work items' do
          expect { subject }.to change { work_items.count }.by 2
        end

        it 'sets work item attributes' do
          result = subject

          expect(work_items.reload).to contain_exactly(
            have_attributes(
              title: 'Valid issue',
              work_item_type_id: issue_type.id
            ),
            have_attributes(
              title: 'Valid requirement',
              work_item_type_id: requirement_type.id
            )
          )

          expect(result[:success]).to eq(2)
          expect(result[:error_lines]).to be_empty
          expect(result[:type_errors]).to be_nil
          expect(result[:parse_error]).to eq(false)
        end
      end

      context 'when some types are unavailable' do
        let(:file) { fixture_file_upload('ee/spec/fixtures/work_items_invalid_types.csv') }

        it 'throws an error and does not import' do
          result = subject

          expect(result[:parse_error]).to eq(false)
          expect(result[:type_errors]).to match({
            blank: [],
            disallowed: {},
            missing: {
              "issue!!!" => [2],
              "requirement🔨" => [3],
              "nonsense??" => [4]
            }
          })
        end
      end
    end

    context 'when user cannot create type' do
      context 'when types include Requirement' do
        shared_examples 'does not create requirement' do
          specify do
            result = subject

            expect(work_items.reload).not_to include(
              have_attributes(
                title: 'Valid requirement'
              )
            )

            expect(result[:parse_error]).to eq(false)
            expect(result[:type_errors]).to match({
              blank: [],
              disallowed: { "requirement" => [3] },
              missing: {}
            })
          end
        end

        context 'when Requirement is not licensed' do
          before do
            stub_licensed_features(requirements: false)
          end

          it_behaves_like 'does not create requirement'
        end

        context 'when user cannot create a Requirement' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :create_requirement, anything).and_return(false)
          end

          it_behaves_like 'does not create requirement'
        end
      end
    end
  end
end
