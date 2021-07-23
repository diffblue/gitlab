# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventService, :request_store do
  let(:project) { build_stubbed(:project) }
  let_it_be(:user) { create(:user, current_sign_in_ip: '192.168.68.104') }
  let_it_be(:project_member) { create(:project_member, user: user, expires_at: 1.day.from_now) }

  let(:request_ip_address) { '127.0.0.1' }

  let(:details) { { action: :destroy } }
  let(:service) { described_class.new(user, project, details) }

  before do
    allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(request_ip_address)
  end

  describe '#for_member' do
    let(:event) { service.for_member(project_member).security_event }
    let(:event_details) { event[:details] }

    it 'generates event' do
      expect(event_details[:target_details]).to eq(user.name)
    end

    it 'handles deleted users' do
      expect(project_member).to receive(:user).and_return(nil)
      expect(event_details[:target_details]).to eq('Deleted User')
    end

    context 'user access expiry' do
      let(:service) { described_class.new(nil, project, { action: :expired }) }

      it 'generates a system event' do
        expect(event_details[:remove]).to eq('user_access')
        expect(event_details[:system_event]).to be_truthy
        expect(event_details[:reason]).to include('access expired on')
      end
    end

    context 'create user access' do
      let(:details) { { action: :create } }

      it 'stores author name', :aggregate_failures do
        expect(event_details[:author_name]).to eq(user.name)
        expect(event.author_name).to eq(user.name)
      end
    end

    it 'generates a system event' do
      expect(event_details[:target_type]).to eq('User')
      expect(event.target_type).to eq('User')
    end

    context 'updating membership' do
      let(:service) do
        described_class.new(user, project, {
          action: :update,
          old_access_level: 'Reporter',
          old_expiry: Date.today
        })
      end

      it 'records the change in expiry date' do
        event = service.for_member(project_member).security_event

        expect(event[:details][:change]).to eq('access_level')
        expect(event[:details][:expiry_from]).to eq(Date.today)
        expect(event[:details][:expiry_to]).to eq(1.day.from_now.to_date)
      end
    end
  end

  describe '#security_event' do
    context 'unlicensed' do
      before do
        disable_license_audit_features
      end

      it 'does not create an event' do
        expect(AuditEvent).not_to receive(:create)

        expect { service.security_event }.not_to change(AuditEvent, :count)
      end
    end

    context 'licensed' do
      it 'creates an event' do
        expect { service.security_event }.to change(AuditEvent, :count).by(1)
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'does not create an event' do
          expect { service.security_event }.not_to change(AuditEvent, :count)
        end
      end
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      context 'for an unauthenticated user' do
        let(:user) { Gitlab::Audit::UnauthenticatedAuthor.new }

        context 'when request IP address is present' do
          it 'has the request IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(request_ip_address)
            expect(event.ip_address).to eq(request_ip_address)
          end
        end

        context 'when request IP address is not present' do
          let(:request_ip_address) { nil }

          it 'has the user IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(user.current_sign_in_ip)
            expect(event.ip_address).to eq(user.current_sign_in_ip)
          end
        end
      end

      context 'for an authenticated user' do
        context 'when request IP address is present' do
          it 'has the request IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(request_ip_address)
            expect(event.ip_address).to eq(request_ip_address)
          end
        end

        context 'when request IP address is not present' do
          let(:request_ip_address) { nil }

          it 'has the user IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(user.current_sign_in_ip)
            expect(event.ip_address).to eq(user.current_sign_in_ip)
          end

          it 'tracks exceptions when the event cannot be created' do
            allow(user).to receive_messages(current_sign_in_ip: 'invalid IP')

            expect(Gitlab::ErrorTracking).to(
              receive(:track_exception)
                .with(ActiveRecord::RecordInvalid, audit_event_type: 'AuditEvent').and_call_original
            )

            service.security_event
          end
        end
      end

      context 'for an impersonated user' do
        let(:details) { {} }
        let(:impersonator) { build(:user, name: 'Donald Duck', current_sign_in_ip: '192.168.88.88') }
        let(:user) { create(:user, impersonator: impersonator) }

        context 'when request IP address is present' do
          it 'has the request IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(request_ip_address)
            expect(event.ip_address).to eq(request_ip_address)
          end
        end

        context 'when request IP address is not present' do
          let(:request_ip_address) { nil }

          it 'has the impersonator IP address' do
            event = service.security_event

            expect(event.details[:ip_address]).to eq(impersonator.current_sign_in_ip)
            expect(event.ip_address).to eq(impersonator.current_sign_in_ip)
          end
        end

        it 'has the impersonator name' do
          event = service.security_event

          expect(event.details[:impersonated_by]).to eq('Donald Duck')
        end
      end
    end
  end

  describe '#enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:admin_audit_log, :audit_events, :extended_audit_events, :result) do
      true  | false | false | true
      false | true  | false | true
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      before do
        stub_licensed_features(
          admin_audit_log: admin_audit_log,
          audit_events: audit_events,
          extended_audit_events: extended_audit_events
        )
      end

      it 'returns the correct result when feature is available' do
        expect(service.enabled?).to eq(result)
      end
    end
  end

  describe '#entity_audit_events_enabled?' do
    context 'entity is a project' do
      let(:service) { described_class.new(user, project, { action: :destroy }) }

      it 'returns false when project is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsy
      end

      it 'returns true when project is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a group' do
      let(:group) { create(:group) }
      let(:service) { described_class.new(user, group, { action: :destroy }) }

      it 'returns false when group is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsey
      end

      it 'returns true when group is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a user' do
      let(:service) { described_class.new(user, user, { action: :destroy }) }

      it 'returns false when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_falsey
      end

      it 'returns true when licensed with extended events' do
        stub_licensed_features(extended_audit_events: true)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end

    context 'auth event' do
      let(:service) { described_class.new(user, user, { with: 'auth' }) }

      it 'returns true when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end
  end

  describe '#for_failed_login' do
    let(:author_name) { 'testuser' }
    let(:service) { described_class.new(author_name, nil) }
    let(:event) { service.for_failed_login.unauth_security_event }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'has the right type' do
      expect(event.entity_type).to eq('User')
    end

    it 'has the right author' do
      expect(event.details[:author_name]).to eq(author_name)
      expect(event.author_name).to eq(author_name)
    end

    it 'has the right target_details' do
      expect(event.details[:target_details]).to eq(author_name)
    end

    it 'has the right auth method for OAUTH' do
      oauth_service = described_class.new(author_name, nil, ip_address: request_ip_address, with: 'ldap')
      event = oauth_service.for_failed_login.unauth_security_event

      expect(event.details[:failed_login]).to eq('LDAP')
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
      end

      it 'has the right IP address' do
        expect(event.ip_address).to eq(request_ip_address)
        expect(event.details[:ip_address]).to eq(request_ip_address)
      end
    end

    context 'admin audit log unlicensed' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: false)
      end

      it 'does not have the ip_address' do
        expect(event.ip_address).to be_nil
        expect(event.details).not_to have_key(:ip_address)
      end
    end

    context 'on a read-only instance' do
      before do
        allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
      end

      it 'does not create an event record in the database' do
        expect { service.for_failed_login.unauth_security_event }.not_to change(AuditEvent, :count)
      end
    end
  end

  describe '#for_project_group_link' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }
    let_it_be(:link) { create(:project_group_link, group: group, project: project) }

    let(:options) { { action: :create } }

    subject(:event) { described_class.new(current_user, project, options).for_project_group_link(link).security_event }

    it 'sets the target_type attribute' do
      expect(event.details[:target_type]).to eq('Project')
      expect(event.target_type).to eq('Project')
    end
  end

  describe '#for_user' do
    let(:author_name) { 'Administrator' }
    let(:current_user) { User.new(name: author_name) }
    let(:user) { create(:user) }
    let(:custom_message) { 'Some strange event has occurred' }
    let(:options) { { action: action, custom_message: custom_message } }
    let(:event) { service.security_event }

    before do
      stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
    end

    subject(:service) { described_class.new(current_user, user, options).for_user }

    context 'with destroy action' do
      let(:action) { :destroy }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          remove: 'user',
          author_name: author_name,
          target_id: user.id,
          target_type: 'User',
          target_details: user.username
        )
      end

      it 'sets the target_id column' do
        expect(event.target_id).to eq(user.id)
      end
    end

    context 'with create action' do
      let(:action) { :create }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          add: 'user',
          author_name: author_name,
          target_id: user.id,
          target_type: 'User',
          target_details: user.full_path
        )
      end

      it 'sets the target_id column' do
        expect(event.target_id).to eq(user.id)
      end
    end

    context 'with custom action' do
      let(:action) { :custom }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          custom_message: custom_message,
          author_name: author_name,
          target_id: user.id,
          target_type: 'User',
          target_details: user.full_path
        )
      end

      it 'sets the target_id column' do
        expect(event.target_id).to eq(user.id)
      end
    end
  end

  describe '#for_project' do
    let(:current_user) { create(:user) }
    let(:project) { create(:project) }
    let(:options) { { action: action } }

    before do
      stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
    end

    let(:event) { service.security_event }

    subject(:service) { described_class.new(current_user, project, options).for_project }

    context 'with destroy action' do
      let(:action) { :destroy }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          remove: 'project',
          author_name: current_user.name,
          target_id: project.id,
          target_type: 'Project',
          target_details: project.full_path
        )
      end

      it 'sets the target_id column' do
        expect(event.target_id).to eq(project.id)
      end
    end

    context 'with create action' do
      let(:action) { :create }

      it 'sets the details attribute' do
        expect(service.instance_variable_get(:@details)).to eq(
          add: 'project',
          author_name: current_user.name,
          target_id: project.id,
          target_type: 'Project',
          target_details: project.full_path
        )
      end

      it 'sets the target_id column' do
        expect(event.target_id).to eq(project.id)
      end
    end
  end

  describe '#for_changes' do
    let(:author_name) { 'Administrator' }
    let(:current_user) { User.new(name: author_name) }
    let(:changed_model) { ApprovalProjectRule.new(id: 6, name: 'Security') }
    let(:options) { { as: 'required approvers', from: 3, to: 4 } }

    subject(:service) { described_class.new(current_user, project, options).for_changes(changed_model) }

    it 'sets the details attribute' do
      expect(service.instance_variable_get(:@details)).to eq(
        change: 'required approvers',
        from: 3,
        to: 4,
        author_name: author_name,
        target_id: 6,
        target_type: 'ApprovalProjectRule',
        target_details: 'Security'
      )
    end
  end

  describe '#for_project' do
    let_it_be(:current_user) { create(:user, name: 'Test User') }
    let_it_be(:project) { create(:project) }

    let(:action) { :destroy }
    let(:options) { { action: action } }

    subject(:event) { described_class.new(current_user, project, options).for_project.security_event }

    it 'sets the details attribute' do
      expect(event.details).to eq(
        remove: 'project',
        author_name: 'Test User',
        target_id: project.id,
        target_type: 'Project',
        target_details: project.full_path
      )
    end

    it 'sets the target_type column' do
      expect(event.target_type).to eq('Project')
    end
  end

  describe '#for_group' do
    let_it_be(:user) { create(:user, name: 'Test User') }
    let_it_be(:group) { create(:group) }

    let(:action) { :destroy }
    let(:options) { { action: action } }
    let(:service) { described_class.new(user, group, options).for_group }

    subject(:event) { service.security_event }

    it 'sets the details attribute' do
      expect(event.details).to eq(
        remove: 'group',
        author_name: 'Test User',
        target_id: group.id,
        target_type: 'Group',
        target_details: group.full_path
      )
    end

    it 'stores target_type in a database column' do
      expect(event.target_type).to eq('Group')
    end
  end

  describe 'license' do
    let(:event) { service.for_project.security_event }

    before do
      disable_license_audit_features
    end

    describe 'has the audit_admin feature' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'has the entity_path' do
        expect(event.details[:entity_path]).to eq(project.full_path)
      end

      context 'request IP address is present' do
        it 'has the IP address in the details hash' do
          expect(event.details[:ip_address]).to eq(request_ip_address)
        end

        it 'has the IP address stored in a separate attribute' do
          expect(event.ip_address).to eq(request_ip_address)
        end
      end

      context 'request IP address is not present' do
        let(:request_ip_address) { nil }

        it 'has the IP address in the details hash' do
          expect(event.details[:ip_address]).to eq(user.current_sign_in_ip)
        end

        it 'has the IP address stored in a separate attribute' do
          expect(event.ip_address).to eq(user.current_sign_in_ip)
        end
      end
    end

    describe 'has the extended_audit_events feature' do
      before do
        stub_licensed_features(extended_audit_events: true)
      end

      it 'logs an audit event' do
        expect { event }.to change { AuditEvent.count }.by(1)
      end

      it 'does not have the entity_path' do
        expect(event.details).not_to have_key(:entity_path)
      end

      it 'does not have the ip_address' do
        expect(event.details).not_to have_key(:ip_address)
      end
    end

    describe 'entity has the audit_events feature' do
      before do
        stub_licensed_features(audit_events: true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'does not have the entity_path' do
        expect(event.details).not_to have_key(:entity_path)
      end

      it 'does not have the ip_address' do
        expect(event.details).not_to have_key(:ip_address)
      end
    end

    describe 'does not have any audit event feature' do
      it 'does not log the audit event' do
        expect { event }.not_to change(AuditEvent, :count)
      end
    end
  end

  def disable_license_audit_features
    stub_licensed_features(
      admin_audit_log: false,
      audit_events: false,
      extended_audit_events: false
    )
  end
end
