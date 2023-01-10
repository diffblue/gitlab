# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportHelper, feature_category: :importers do
  describe '#import_configure_github_admin_message' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.import_configure_github_admin_message }

    where(:has_ci_cd_only_params, :can_admin_all_resources, :expected_text) do
      true  | true  | /Note: As an administrator .* connecting/
      true  | false | /Note: Consider asking your GitLab administrator .* connecting/
      false | true  | /Note: As an administrator .* importing/
      false | false | /Note: Consider asking your GitLab administrator .* importing/
    end

    with_them do
      it 'returns correct note' do
        allow(helper).to receive(:has_ci_cd_only_params?).and_return(has_ci_cd_only_params)
        allow(helper).to receive(:current_user) {
                           instance_double('User', can_admin_all_resources?: can_admin_all_resources)
                         }

        is_expected.to have_text(expected_text)
      end
    end
  end
end
