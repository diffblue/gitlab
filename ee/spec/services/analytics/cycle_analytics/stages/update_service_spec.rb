# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stages::UpdateService do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:value_stream, refind: true) { create(:cycle_analytics_group_value_stream, namespace: group) }
  let_it_be(:user, refind: true) { create(:user) }

  let(:default_stages) { Gitlab::Analytics::CycleAnalytics::DefaultStages.all }
  let(:params) { { value_stream: value_stream } }
  let(:persisted_stages) { group.reload.cycle_analytics_stages.ordered }

  subject { described_class.new(parent: group, params: params, current_user: user).execute }

  before_all do
    group.add_member(user, :reporter)
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  it_behaves_like 'permission check for Value Stream Analytics Stage services', :cycle_analytics_for_groups

  context 'when updating a default stage' do
    let(:stage) { Analytics::CycleAnalytics::GroupStage.new(default_stages.first.merge(namespace: group)) }
    let(:params) { { id: stage.name, hidden: true, value_stream: value_stream } }
    let(:updated_stage) { subject.payload[:stage] }

    context 'when hiding a default stage' do
      it { expect(subject).to be_success }
      it { expect(updated_stage).to be_persisted }
      it { expect(updated_stage).to be_hidden }
    end

    context 'when other parameters than "hidden" are given' do
      before do
        params[:name] = 'should not be updated'
      end

      it { expect(subject).to be_success }
      it { expect(updated_stage.name).not_to eq(params[:name]) }
    end

    context 'when the first update happens on a default stage' do
      it { expect(subject).to be_success }

      it 'persists all default stages' do
        subject

        expect(persisted_stages.count).to eq(default_stages.count)
        expect(persisted_stages).to all(be_persisted)
      end

      it 'matches with the configured default stage name' do
        subject

        default_stage_names = default_stages.map { |s| s[:name] }
        expect(default_stage_names).to include(updated_stage.name)
      end

      context 'when the update fails' do
        before do
          invalid_stage = Analytics::CycleAnalytics::GroupStage.new(name: '')
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:find_stage).and_return(invalid_stage)
          end
        end

        it 'returns unsuccessful service response' do
          subject

          expect(subject).not_to be_success
        end

        it 'does not persist the default stages if the stage is invalid' do
          subject

          expect(persisted_stages).not_to include(be_persisted)
        end
      end
    end

    context 'when updating an already persisted default stage' do
      let(:persisted_stage) { subject.payload[:stage] }

      let(:updated_stage) do
        described_class
          .new(parent: group, params: { id: persisted_stage.id, hidden: false }, current_user: user)
          .execute
          .payload[:stage]
      end

      it { expect(updated_stage).to be_persisted }
      it { expect(updated_stage).not_to be_hidden }
    end
  end

  context 'when updating a custom stage' do
    let_it_be(:stage) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream) }

    let(:params) { { id: stage.id, name: 'my new stage name', value_stream: value_stream } }

    it { expect(subject).to be_success }
    it { expect(subject.http_status).to eq(:ok) }
    it { expect(subject.payload[:stage].name).to eq(params[:name]) }

    context 'when params are invalid' do
      before do
        params[:name] = ''
      end

      it { expect(subject).to be_error }
      it { expect(subject.http_status).to eq(:unprocessable_entity) }
      it { expect(subject.payload[:errors].attribute_names).to eq([:name]) }
    end
  end

  context 'when positioning a stage' do
    let!(:first_stage) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream, relative_position: 10) }
    let!(:middle_stage) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream, relative_position: 11) }
    let!(:last_stage) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream, relative_position: 12) }

    context 'when there are stages without position' do
      let!(:unpositioned_stage1) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream) }
      let!(:unpositioned_stage2) { create(:cycle_analytics_group_stage, namespace: group, value_stream: value_stream) }

      before do
        params[:id] = first_stage.id
        params[:move_after_id] = unpositioned_stage2.id
      end

      it 'when moving the stage down' do
        subject

        expect(persisted_stages.last(3)).to eq([unpositioned_stage1, unpositioned_stage2, first_stage])
      end
    end

    context 'when moving the stage down' do
      before do
        params[:id] = first_stage.id
        params[:move_after_id] = last_stage.id
      end

      it 'changes the stage positions correctly' do
        subject

        expect(persisted_stages.last(3)).to eq([middle_stage, last_stage, first_stage])
      end
    end

    context 'when moving the stage to the middle' do
      before do
        params[:id] = last_stage.id
        params[:move_before_id] = middle_stage.id
      end

      it 'changes the stage positions correctly' do
        subject

        expect(persisted_stages.last(3)).to eq([first_stage, last_stage, middle_stage])
      end
    end

    context 'when bogus `move_before_id` is given' do
      before do
        params[:id] = last_stage.id
        params[:move_before_id] = -1
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when bogus `move_after_id` is given' do
      before do
        params[:id] = last_stage.id
        params[:move_after_id] = -1
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when `move_before_id` points to a stage within a different group' do
      before do
        params[:id] = last_stage.id
        params[:move_before_id] = create(:cycle_analytics_group_stage, namespace: create(:group), value_stream: value_stream).id
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
