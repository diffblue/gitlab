# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelsHelper do
  let(:project) { create(:project) }
  let(:label) { build_stubbed(:label, project: project).present(issuable_subject: nil) }
  let(:scoped_label) { build_stubbed(:label, name: 'key::value', project: project).present(issuable_subject: nil) }

  describe '#render_label' do
    context 'with scoped labels disabled' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      it 'does not include link to scoped documentation' do
        expect(render_label(scoped_label)).to match(%r(<span.+><span.+>#{scoped_label.name}</span></span>$)m)
      end
    end
  end

  describe '#label_dropdown_data' do
    subject { label_dropdown_data(edit_context, opts) }

    let(:opts) { { default_label: "Labels" } }
    let(:data) do
      {
        toggle: "dropdown",
        field_name: opts[:field_name] || "label_name[]",
        show_no: "true",
        show_any: "true",
        default_label: "Labels",
        scoped_labels: "false"
      }
    end

    context 'when edit_context is a project' do
      let(:edit_context) { create(:project) }
      let(:label) { create(:label, project: edit_context, title: 'bug') }

      before do
        data.merge!({
          project_id: edit_context.id,
          namespace_path: edit_context.namespace.full_path,
          project_path: edit_context.path
        })
      end

      it { is_expected.to eq(data) }
    end

    context 'when edit_context is a group' do
      let(:edit_context) { create(:group) }
      let(:label) { create(:group_label, group: edit_context, title: 'bug') }

      before do
        data.merge!(group_id: edit_context.id)
      end

      it { is_expected.to eq(data) }
    end
  end
end
