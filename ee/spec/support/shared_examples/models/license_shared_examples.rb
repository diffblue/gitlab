# frozen_string_literal: true

RSpec.shared_examples 'valid daily billable users count compared to limit set by license checks' do
  context 'when daily billable users count is less than the restricted user count' do
    let(:billable_users_count) { active_user_count - 5 }

    it { is_expected.to be_valid }
  end

  context 'when daily billable users count is equal to the restricted user count' do
    let(:billable_users_count) { active_user_count }

    it { is_expected.to be_valid }
  end

  context 'when daily billable users count is equal to the restricted user count with threshold' do
    let(:active_user_count) { 10 }
    let(:billable_users_count) { 11 }

    it { is_expected.to be_valid }
  end
end

RSpec.shared_examples 'invalid daily billable users count compared to limit set by license checks' do
  context 'when daily billable users count is greater than the restricted user count' do
    let(:billable_users_count) { active_user_count + 5 }

    it { is_expected.not_to be_valid }

    it 'includes the correct error message' do
      license.valid?

      overage = billable_users_count - active_user_count
      error_message = "This GitLab installation currently has #{billable_users_count} active users, " \
        "exceeding this license's limit of #{active_user_count} by #{overage} users. " \
        "Please add a license for at least #{billable_users_count} users"

      expect(license.errors.full_messages.to_sentence).to include(error_message)
    end
  end
end

RSpec.shared_examples 'valid prior historical max compared to limit set by license checks' do
  context 'when prior historical max is less than the restricted user count' do
    let(:billable_users_count) { active_user_count }
    let(:prior_active_user_count) { active_user_count - 1 }

    it { is_expected.to be_valid }
  end

  context 'when prior historical max is equal to the restricted user count' do
    let(:billable_users_count) { active_user_count }
    let(:prior_active_user_count) { active_user_count }

    it { is_expected.to be_valid }
  end

  context 'when prior historical max is equal to the restricted user count with threshold' do
    let(:active_user_count) { 10 }
    let(:billable_users_count) { active_user_count }
    let(:prior_active_user_count) { 11 }

    it { is_expected.to be_valid }
  end
end

RSpec.shared_examples 'invalid prior historical max compared to limit set by license checks' do
  context 'when prior historical max is greater than the restricted user count' do
    let(:billable_users_count) { active_user_count }
    let(:prior_active_user_count) { active_user_count + 1 }

    it { is_expected.not_to be_valid }

    it 'includes the correct error message' do
      license.valid?

      overage = prior_active_user_count - active_user_count
      error_message = "During the year before this license started, " \
        "this GitLab installation had #{prior_active_user_count} active users, " \
        "exceeding this license's limit of #{active_user_count} by #{overage} user. " \
        "Please add a license for at least #{prior_active_user_count} users"

      expect(license.errors.full_messages.to_sentence).to include(error_message)
    end
  end
end

RSpec.shared_examples 'with previous user count checks' do
  context 'when prior historical max is less than previous user count' do
    let(:prior_active_user_count) { previous_user_count - 5 }

    include_examples 'valid daily billable users count compared to limit set by license checks'
    include_examples 'invalid daily billable users count compared to limit set by license checks'
  end

  context 'when prior historical max is equal to previous user count' do
    let(:prior_active_user_count) { previous_user_count }

    include_examples 'valid daily billable users count compared to limit set by license checks'
    include_examples 'invalid daily billable users count compared to limit set by license checks'
  end

  context 'when prior historical max is greater than previous user count' do
    include_examples 'valid prior historical max compared to limit set by license checks'
    include_examples 'invalid prior historical max compared to limit set by license checks'
  end
end
