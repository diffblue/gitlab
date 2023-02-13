# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ExportCsvService, feature_category: :requirements_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create_default(:group) }
  let_it_be(:project) { create_default(:project, :public) }
  let_it_be_with_reload(:requirement) { create(:work_item, :requirement, state: :opened, author: user).requirement }

  let(:fields) { [] }

  subject { described_class.new(WorkItem.all, project, fields) }

  before do
    stub_licensed_features(requirements: true)
  end

  it 'renders csv to string' do
    expect(subject.csv_data).to be_a String
  end

  describe '#email' do
    it 'emails csv' do
      expect { subject.email(user) }.to change(ActionMailer::Base.deliveries, :count).from(0).to(1)
    end

    it 'renders with a target filesize' do
      expect_next_instance_of(CsvBuilder) do |csv_builder|
        expect(csv_builder).to receive(:render).with(described_class::TARGET_FILESIZE).once
      end

      subject.email(user)
    end
  end

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  context 'includes' do
    let_it_be(:report) { create(:test_report, requirement_issue: requirement.requirement_issue, state: :passed, build: nil, author: user) }

    let(:time_format) { '%Y-%m-%d %H:%M:%S %Z' }

    it 'includes the columns required for import' do
      expect(csv.headers).to include('Title', 'Description')
    end

    specify 'iid' do
      expect(csv[0]['Requirement ID']).to eq requirement.iid.to_s
    end

    specify 'title' do
      expect(csv[0]['Title']).to eq requirement.title
    end

    specify 'description' do
      expect(csv[0]['Description']).to eq requirement.description
    end

    specify 'author' do
      expect(csv[0]['Author']).to eq requirement.author.name
    end

    specify 'author username' do
      expect(csv[0]['Author Username']).to eq requirement.author.username
    end

    specify 'created date' do
      expect(csv[0]['Created At (UTC)']).to eq requirement.created_at.utc.strftime(time_format)
    end

    it 'does not execute n+1 queries' do
      control = ActiveRecord::QueryRecorder.new { described_class.new(WorkItem.all, project, fields).csv_data }

      create(:work_item, :requirement, state: :opened)

      expect { described_class.new(WorkItem.all, project, fields).csv_data }
        .not_to exceed_query_limit(control)
    end

    context 'when last test report failed' do
      before do
        report.update!(state: :failed)
      end

      specify 'latest test report state' do
        expect(csv[0]['State']).to eq ''
      end

      specify 'latest test report created at' do
        expect(csv[0]['State Updated At (UTC)']).to eq report.created_at.utc.strftime(time_format)
      end
    end

    context 'when last test report passed' do
      before do
        report.update!(state: :passed)
      end

      specify 'latest test report state' do
        expect(csv[0]['State']).to eq 'Satisfied'
      end

      specify 'latest test report created at' do
        expect(csv[0]['State Updated At (UTC)']).to eq report.created_at.utc.strftime(time_format)
      end
    end

    context 'when selected fields are present' do
      let(:fields) { ['Title', 'Author username', 'created at', 'state', 'State updated At (UTC)'] }

      it 'returns data for requested fields' do
        expect(csv[0].to_hash).to eq(
          'Title' => requirement.title,
          'Author Username' => requirement.author.username,
          'State' => 'Satisfied',
          'State Updated At (UTC)' => report.created_at.utc.strftime(time_format)
        )
      end
    end

    it_behaves_like 'a service that returns invalid fields from selection'
  end
end
