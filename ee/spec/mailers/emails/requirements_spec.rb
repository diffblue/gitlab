# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::Requirements do
  include EmailSpec::Matchers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe "#import_requirements_csv_email" do
    let(:results) { { success: 0, error_lines: [], parse_error: false } }

    subject { Notify.import_requirements_csv_email(user.id, project.id, results) }

    it "shows number of successful requirements imported" do
      results[:success] = 165

      expect(subject).to have_body_text "165 requirements imported"
    end

    it "shows error when file is invalid" do
      results[:parse_error] = true

      expect(subject).to have_body_text "Error parsing CSV"
    end

    it "shows line numbers with errors" do
      results[:error_lines] = [23, 34, 58]

      expect(subject).to have_body_text "23, 34, 58"
    end

    context 'with header and footer' do
      let(:results) { { success: 165, error_lines: [], parse_error: false } }

      subject { Notify.import_requirements_csv_email(user.id, project.id, results) }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
    end
  end

  describe '#requirements_csv_email' do
    let_it_be(:requirements) { create_list(:work_item, 10, :requirement) }
    let(:export_status) do
      {
        rows_expected: 10,
        rows_written: 10,
        truncated: false
      }
    end

    let_it_be(:csv_data) do
      RequirementsManagement::ExportCsvService
        .new(WorkItem.all, project).csv_data
    end

    subject { Notify.requirements_csv_email(user, project, csv_data, export_status) }

    specify { expect(subject.subject).to eq("#{project.name} | Exported requirements") }
    specify { expect(subject.to).to contain_exactly(user.notification_email_for(project.group)) }
    specify { expect(subject.html_part).to have_content("Your CSV export of 10 requirements from project") }
    specify { expect(subject.text_part).to have_content("Your CSV export of 10 requirements from project") }

    context 'when truncated' do
      let(:export_status) do
        {
            rows_expected: 10,
            rows_written: 10,
            truncated: true
        }
      end

      specify { expect(subject).to have_content('This attachment has been truncated to avoid exceeding the maximum allowed attachment size of 15 MiB.') }
    end
  end
end
