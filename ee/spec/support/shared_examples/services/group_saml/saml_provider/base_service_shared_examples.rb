# frozen_string_literal: true

RSpec.shared_examples 'base SamlProvider service' do
  let(:params) do
    {
      sso_url: 'https://test',
      certificate_fingerprint: fingerprint,
      enabled: true,
      enforced_sso: true
    }
  end

  let(:fingerprint) { '11:22:33:44:55:66:77:88:99:11:22:33:44:55:66:77:88:99' }

  before do
    stub_licensed_features(group_saml: true)
  end

  it 'updates SAML provider with given params' do
    expect(::Gitlab::Audit::Auditor)
      .to receive(:audit).with(
        hash_including(
          { name: audit_event_name,
            author: current_user,
            scope: group,
            target: group })
      ).exactly(4).times.and_call_original

    expect do
      service.execute
      group.reload
    end.to change { group.saml_provider&.sso_url }.to('https://test')
             .and change { group.saml_provider&.certificate_fingerprint }.to(fingerprint)
             .and change { group.saml_provider&.enabled? }.to(true)
             .and change { group.saml_provider&.enforced_sso? }.to(true)
             .and change { AuditEvent.count }.by(4)

    audit_event_messages = [
      %r{enabled changed([\w\s]*)to true},
      %r{certificate_fingerprint changed([\w\W\s]*)to #{fingerprint}},
      %r{sso_url changed([\w\W\s]*)to https:\/\/test},
      %r{enforced_sso changed([\w\s]*)to true}
    ]

    audit_events = AuditEvent.last(4)

    audit_event_messages.each_with_index do |expected_message, index|
      expect(audit_events[index].details[:custom_message]).to match(expected_message)
    end
  end
end

RSpec.shared_examples 'SamlProvider service toggles Group Managed Accounts' do
  context 'when enabling enforced_group_managed_accounts' do
    let(:params) do
      attributes_for(:saml_provider, :enforced_group_managed_accounts)
    end

    before do
      create(:group_saml_identity, user: current_user, saml_provider: saml_provider)
    end

    it 'updates enforced_group_managed_accounts boolean' do
      expect do
        service.execute
        group.reload
      end.to change { group.saml_provider&.enforced_group_managed_accounts? }.to(true)
    end

    context 'when owner has not linked SAML yet' do
      before do
        Identity.delete_all
      end

      it 'adds an error warning that the owner must first link SAML' do
        service.execute

        expect(service.saml_provider.errors[:base]).to eq(["Group Owner must have signed in with SAML before enabling Group Managed Accounts"])
      end
    end
  end
end
