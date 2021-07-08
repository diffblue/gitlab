# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FormBuilders::GitlabUiFormBuilder do
  let_it_be(:user) { build(:user) }
  let_it_be(:fake_template) do
    Object.new.tap do |template|
      template.extend ActionView::Helpers::FormHelper
      template.extend ActionView::Helpers::FormOptionsHelper
      template.extend ActionView::Helpers::TagHelper
      template.extend ActionView::Context
    end
  end

  let_it_be(:form_builder) { described_class.new(:user, user, fake_template, {}) }

  describe '#gitlab_ui_checkbox_component' do
    let(:optional_args) { {} }

    subject(:checkbox_html) { form_builder.gitlab_ui_checkbox_component(:view_diffs_file_by_file, "Show one file at a time on merge request's Changes tab", **optional_args) }

    context 'without optional arguments' do
      it 'renders correct html' do
        expected_html = <<~EOS
          <div class="gl-form-checkbox custom-control custom-checkbox">
            <input name="user[view_diffs_file_by_file]" type="hidden" value="0" />
            <input class="custom-control-input" type="checkbox" value="1" name="user[view_diffs_file_by_file]" id="user_view_diffs_file_by_file" />
            <label class="custom-control-label" for="user_view_diffs_file_by_file">
              Show one file at a time on merge request&#39;s Changes tab
            </label>
          </div>
        EOS

        expect(checkbox_html).to eq(html_strip_whitespace(expected_html))
      end
    end

    context 'with optional arguments' do
      let(:optional_args) do
        {
          help_text: 'Instead of all the files changed, show only one file at a time.',
          checkbox_options: { class: 'checkbox-foo-bar' },
          label_options: { class: 'label-foo-bar' }
        }
      end

      it 'renders help text' do
        expected_html = <<~EOS
          <div class="gl-form-checkbox custom-control custom-checkbox">
            <input name="user[view_diffs_file_by_file]" type="hidden" value="0" />
            <input class="custom-control-input checkbox-foo-bar" type="checkbox" value="1" name="user[view_diffs_file_by_file]" id="user_view_diffs_file_by_file" />
            <label class="custom-control-label label-foo-bar" for="user_view_diffs_file_by_file">
              <span>Show one file at a time on merge request&#39;s Changes tab</span>
              <p class="help-text">Instead of all the files changed, show only one file at a time.</p>
            </label>
          </div>
        EOS

        expect(checkbox_html).to eq(html_strip_whitespace(expected_html))
      end
    end
  end

  private

  def html_strip_whitespace(html)
    html.lines.map(&:strip).join('')
  end
end
