# frozen_string_literal: true

RSpec.shared_context 'exclusive labels creation' do
  def create_label(title)
    # Lock all the labels. Since it shouldn't have any effect for normal
    # issuables, this ensures that is the case
    if parent.is_a?(Group)
      create(:group_label, group: parent, title: title, lock_on_merge: true)
    else
      create(:label, project: parent, title: title, lock_on_merge: true)
    end
  end

  before do
    parent.add_developer(user)
  end
end

# `issuable` needs to be defined on the context calling this example
RSpec.shared_examples 'new issuable with scoped labels' do
  include_context 'exclusive labels creation' do
    context 'when scoped labels are available' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      let!(:label1) { create_label('label1') }
      let!(:label2) { create_label('key::label1') }
      let!(:label3) { create_label('key::label2') }
      let!(:label4) { create_label('key::label3') }

      context 'when using label_ids parameter' do
        let(:args) do
          {
            **described_class.constructor_container_arg(parent),
            current_user: user,
            params: { title: 'test', label_ids: [label1.id, label3.id, label4.id, label2.id] }
          }
        end

        it 'adds only last selected exclusive scoped label' do
          expect(issuable.labels).to match_array([label1, label2])
        end
      end

      context 'when using labels parameter' do
        let(:args) do
          {
            **described_class.constructor_container_arg(parent),
            current_user: user,
            params: { title: 'test', labels: [label1.title, label3.title, label4.title, label2.title] }
          }
        end

        it 'adds only last selected exclusive scoped label' do
          expect(issuable.labels).to match_array([label1, label2])
        end
      end
    end

    context 'when scoped labels are not available' do
      let(:args) do
        {
          **described_class.constructor_container_arg(parent),
          current_user: user,
          params: { title: 'test', label_ids: [label1.id, label3.id, label4.id, label2.id] }
        }
      end

      let!(:label1) { create_label('label1') }
      let!(:label2) { create_label('key::label1') }
      let!(:label3) { create_label('key::label2') }
      let!(:label4) { create_label('key::label3') }

      before do
        stub_licensed_features(scoped_labels: false)
      end

      it 'adds all scoped labels' do
        expect(issuable.labels).to match_array([label1, label2, label3, label4])
      end
    end
  end
end

RSpec.shared_examples 'existing issuable with scoped labels' do
  include_context 'exclusive labels creation' do
    let(:label1) { create_label('key::label1') }
    let(:label2) { create_label('key::label2') }
    let(:label3) { create_label('key::label3') }

    context 'when scoped labels are available' do
      before do
        stub_licensed_features(scoped_labels: true, epics: true)
      end

      context 'when using label_ids parameter' do
        it 'adds only last selected exclusive scoped label' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { label_ids: [label1.id, label3.id] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label3])
        end
      end

      context 'when using label_ids parameter' do
        it 'adds only last selected exclusive scoped label' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { labels: [label1.title, label3.title] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label3])
        end
      end

      context 'when only removing labels' do
        it 'preserves multiple exclusive scoped labels' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)
          create(:label_link, label: label3, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { label_ids: [label2.id, label3.id] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label2, label3])
        end
      end
    end

    context 'when scoped labels are not available' do
      before do
        stub_licensed_features(scoped_labels: false, epics: true)
      end

      it 'adds all scoped labels' do
        create(:label_link, label: label1, target: issuable)
        create(:label_link, label: label2, target: issuable)

        issuable.reload

        described_class.new(
          **described_class.constructor_container_arg(parent), current_user: user, params: { label_ids: [label1.id, label2.id, label3.id] }
        ).execute(issuable)

        expect(issuable.reload.labels).to match_array([label1, label2, label3])
      end
    end
  end
end

RSpec.shared_examples 'merged MR with scoped labels and lock_on_merge' do
  include_context 'exclusive labels creation' do
    let(:label1) { create_label('key::label1') }
    let(:label2) { create_label('key::label2') }
    let(:label3) { create_label('key::label3') }

    context 'when scoped labels are available' do
      before do
        stub_licensed_features(scoped_labels: true, epics: true)
      end

      context 'when using label_ids parameter' do
        it 'does not remove or add a label' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { label_ids: [label1.id, label3.id] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label1, label2])
        end
      end

      context 'when using label parameter' do
        it 'does not remove or add a label' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { labels: [label1.title, label3.title] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label1, label2])
        end
      end

      context 'when only removing labels' do
        it 'does not remove or add a label' do
          create(:label_link, label: label1, target: issuable)
          create(:label_link, label: label2, target: issuable)
          create(:label_link, label: label3, target: issuable)

          issuable.reload

          described_class.new(
            **described_class.constructor_container_arg(parent), current_user: user, params: { label_ids: [label2.id, label3.id] }
          ).execute(issuable)

          expect(issuable.reload.labels).to match_array([label1, label2, label3])
        end
      end
    end
  end
end
