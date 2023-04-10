# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CreateService, '#execute', feature_category: :subgroups do
  let!(:user) { create :user }
  let!(:group_params) do
    {
      name: 'GitLab',
      path: 'group_path',
      visibility_level: Gitlab::VisibilityLevel::PUBLIC
    }
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { create_group(user, group_params) }
      let(:fail_condition!) do
        allow(Gitlab::VisibilityLevel).to receive(:allowed_for?).and_return(false)
      end

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: @resource.id,
           entity_type: 'Group',
           details: {
             add: 'group',
             author_name: user.name,
             target_id: @resource.id,
             target_type: 'Group',
             target_details: @resource.full_path
           }
         }
      end
    end
  end

  context 'when created group is a sub-group' do
    let(:group) { create :group }

    subject(:execute) { create_group(user, group_params.merge(parent_id: group.id)) }

    before do
      group.add_owner(user)
    end

    include_examples 'sends streaming audit event'
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        group = create_group(admin_user, group_params.merge(opts))

        expect(group.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        group = create_group(admin_user, group_params.merge(opts))

        expect(group.repository_size_limit).to be_nil
      end
    end
  end

  context 'updating protected params' do
    let(:attrs) do
      group_params.merge(shared_runners_minutes_limit: 1000, extra_shared_runners_minutes_limit: 100, delayed_project_removal: true)
    end

    context 'as an admin' do
      let(:user) { create(:admin) }

      it 'updates the attributes' do
        group = create_group(user, attrs)

        expect(group.shared_runners_minutes_limit).to eq(1000)
        expect(group.extra_shared_runners_minutes_limit).to eq(100)
        expect(group.namespace_settings.delayed_project_removal).to be true
      end
    end

    context 'as a regular user' do
      it 'ignores the attributes' do
        group = create_group(user, attrs)

        expect(group.shared_runners_minutes_limit).to be_nil
        expect(group.extra_shared_runners_minutes_limit).to be_nil
        expect(group.namespace_settings.delayed_project_removal).to be false
      end
    end
  end

  context 'creating group push rule' do
    context 'when feature is available' do
      before do
        stub_licensed_features(push_rules: true)
      end

      context 'when there are push rules settings' do
        let!(:sample) { create(:push_rule_sample) }

        it 'uses the configured push rules settings' do
          group = create_group(user, group_params)
          group.reload

          expect(group.push_rule).to be_nil
          expect(group.predefined_push_rule).to eq(sample)
        end
      end

      context 'when there are not push rules settings' do
        it 'is not creating the group push rule' do
          group = create_group(user, group_params)

          expect(group.push_rule).to be_nil
        end
      end
    end

    context 'when feature not is available' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'ignores the group push rule' do
        group = create_group(user, group_params)

        expect(group.push_rule).to be_nil
      end
    end
  end

  context 'when create_event is true' do
    subject(:execute) { described_class.new(user, group_params.merge(create_event: true)).execute }

    it 'enqueues a create event worker' do
      expect(Groups::CreateEventWorker).to receive(:perform_async).with(anything, user.id, :created)

      execute
    end

    context 'when user can not create a group' do
      before do
        user.update_attribute(:can_create_group, false)
      end

      it "doesn't enqueue a create event worker" do
        expect(Groups::CreateEventWorker).not_to receive(:perform_async)

        execute
      end
    end
  end

  context 'when create_event is NOT true' do
    subject(:execute) { described_class.new(user, group_params).execute }

    it "doesn't enqueue a create event worker" do
      expect(Groups::CreateEventWorker).not_to receive(:perform_async)

      execute
    end
  end

  def create_group(user, opts)
    described_class.new(user, opts).execute
  end
end
