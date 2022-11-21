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

  describe '#wrap_label_html' do
    context 'when label is scoped label' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      let(:xss_label) do
        build_stubbed(:label, name: 'xss::label', project: project, color: '"><img src=x onerror=prompt(1)>')
      end

      it 'html-escapes the label color' do
        expect(wrap_label_html('xss', label: xss_label, small: false)).to include(html_escape(xss_label.color))
          .and include('color:')
      end
    end

    context 'when label is not scoped label' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      let(:xss_label) do
        build_stubbed(:label, name: 'xsslabel', project: project, color: '"><img src=x onerror=prompt(1)>')
      end

      it 'does not include the color' do
        expect(wrap_label_html('xss', label: xss_label, small: false)).not_to include('color:')
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

  describe '#labels_function_introduction' do
    subject { helper.labels_function_introduction }

    let(:group) { instance_double(Group) }

    context 'when epics is unavailable' do
      before do
        allow(group).to receive(:feature_available?).with(:epics).and_return(false)
        assign(:group, group)
      end

      it {
        expect_text = _('Labels can be applied to issues and merge requests. '\
          'Group labels are available for any project within the group.')
        is_expected.to eq(expect_text)
      }
    end

    context 'when epics is available' do
      before do
        allow(group).to receive(:feature_available?).with(:epics).and_return(true)
        assign(:group, group)
      end

      it {
        expect_text = _('Labels can be applied to issues, merge requests, and epics. '\
          'Group labels are available for any project within the group.')
        is_expected.to eq(expect_text)
      }
    end
  end
end
