# frozen_string_literal: true

RSpec.shared_context 'with all password complexity rules enabled' do
  before do
    stub_licensed_features(password_complexity: true)
    stub_application_setting(password_number_required: true)
    stub_application_setting(password_lowercase_required: true)
    stub_application_setting(password_uppercase_required: true)
    stub_application_setting(password_symbol_required: true)
  end
end
