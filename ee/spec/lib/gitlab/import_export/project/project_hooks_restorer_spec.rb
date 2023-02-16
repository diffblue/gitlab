# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ProjectHooksRestorer, feature_category: :source_code_management do
  random_boolean = -> { [true, false].sample }

  let_it_be(:user) { create(:admin) }
  let_it_be(:source_project) { create(:project) }
  let_it_be(:source_hooks) do
    Array.new(4).map do |_|
      create(
        :project_hook,
        :url_variables,
        enable_ssl_verification: random_boolean.call,
        note_events: random_boolean.call,
        job_events: random_boolean.call,
        releases_events: random_boolean.call,
        project: source_project,
        token: SecureRandom.hex(8),
        created_at: Time.zone.now
      )
    end
  end

  let_it_be(:importable) { create(:project) }

  subject do
    described_class.new(
      project: importable,
      shared: importable.import_export_shared,
      user: user,
      source_project: source_project
    )
  end

  context 'when project hooks are present in source project' do
    before do
      allow(user).to receive(:can_admin_all_resources?).and_return(true)
    end

    it 'has the same amount of project hooks as the source' do
      subject.restore
      importable_hook = importable.hooks.order_by(created_at: :asc)

      expect(importable_hook.count).to eq(source_hooks.count)
      expect(importable_hook.all?(&:persisted?)).to eq(true)
    end

    it 'has different encrypted values compared to source' do
      subject.restore
      importable_hooks = importable.hooks.order_by(created_at: :asc)

      source_hooks.each_with_index do |source_hook, i|
        target_hook = importable_hooks[i]

        expect(target_hook.encrypted_url).not_to eq(source_hook.encrypted_url)
        expect(target_hook.encrypted_url_variables).not_to eq(source_hook.encrypted_url_variables)
        expect(target_hook.encrypted_token).not_to eq(source_hook.encrypted_token)

        expect(target_hook.encrypted_url_iv).not_to eq(source_hook.encrypted_url_iv)
        expect(target_hook.encrypted_url_variables_iv).not_to eq(source_hook.encrypted_url_variables_iv)
        expect(target_hook.encrypted_token_iv).not_to eq(source_hook.encrypted_token_iv)
      end
    end

    it 'has equal decrypted values compared to source',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391187' do
      subject.restore
      importable_hooks = importable.hooks.order_by(created_at: :asc)

      source_hooks.each_with_index do |source_hook, i|
        target_hook = importable_hooks[i]

        expect(target_hook.url).to eq(source_hook.url)
        expect(target_hook.url_variables).to eq(source_hook.url_variables)
        expect(target_hook.token).to eq(source_hook.token)
      end
    end

    it 'has equal plain values compared to source',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391187' do
      subject.restore
      importable_hooks = importable.hooks.order_by(created_at: :asc)
      normal_attributes = ProjectHook.column_names
                                     .reject { |string| string.include?("encrypted_") }
                                     .reject { |string| string.include?("_at") }
                                     .reject { |string| string.include?("_id") }
                                     .reject { |string| string == "id" }

      source_hooks.each_with_index do |source_hook, i|
        target_hook = importable_hooks[i]

        normal_attributes.each do |attribute|
          source_value = source_hook.send(attribute)
          target_value = target_hook.send(attribute)

          expect(source_value).to eq(target_value)
        end
      end
    end
  end

  context 'when the user is unauthorized' do
    let(:user) { create(:user) }

    it 'raises an error and logs user' do
      expect { subject.restore }.to raise_exception(StandardError, 'Unauthorized service')
    end

    it 'logs the unauthorized user' do
      expect(::Gitlab::Import::Logger).to receive(:warn).once.with(
        message: "User tried to access unauthorized service",
        username: user.username,
        user_id: user.id,
        service: described_class.name,
        error: 'Unauthorized service'
      )
      expect { subject.restore }.to raise_exception(StandardError)
    end
  end

  context 'when all hooks are not duplicated' do
    before do
      allow(user).to receive(:can_admin_all_resources?).and_return(true)
      allow(subject).to receive(:duplicate_source_hooks).and_return(false)
    end

    it 'reports the failure' do
      subject.restore
      excepted_msg = 'Could not duplicate all project hooks from custom template Project'

      expect(importable.import_failures.last.exception_message).to eq(excepted_msg)
      expect(subject.restore).to eq(true)
    end

    it 'returns true' do
      expect(subject.restore).to eq(true)
    end
  end
end
