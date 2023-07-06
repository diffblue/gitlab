# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventPresenter do
  include Gitlab::Routing.url_helpers

  let(:details) do
    {
      change: 'name',
      from: 'a',
      to: 'b',
      entity_path: 'path'
    }
  end

  let(:audit_event) do
    create(
      :audit_event,
      author_name: 'author',
      target_details: 'target name',
      ip_address: '10.2.1.1',
      details: details
    )
  end

  subject(:presenter) do
    described_class.new(audit_event)
  end

  context 'exposes the author' do
    it 'gets the event author name' do
      expect(presenter.author_name).to eq(audit_event.user.name)
    end

    context 'event authored by a user that exists' do
      it 'returns a url' do
        expect(presenter.author_url).to eq(url_for(user_path(audit_event.user)))
      end
    end

    context 'event authored by a user that no longer exists' do
      let(:audit_event) { build(:audit_event, user: build(:user), details: details) }

      context 'when `author_name` is not included in the details' do
        let(:details) do
          {
            author_name: nil,
            ip_address: '127.0.0.1',
            target_details: 'target name',
            entity_path: 'path',
            from: 'a',
            to: 'b'
          }
        end

        it 'does not return a url' do
          expect(presenter.author_url).to be_blank
        end
      end

      context 'when `author_name` is included in the details and not in the author_name column' do
        let(:audit_event) { build(:audit_event, author_name: nil, details: details) }

        it 'shows the author name as provided in the details' do
          expect(presenter.author_name).to eq(details[:author_name])
        end
      end
    end

    context 'event authored by a runner registration token user' do
      let(:author_double) { double(:author) }
      let(:audit_event) do
        build(:audit_event, ip_address: '127.0.0.1', target_type: ::Ci::Runner.name, entity_path: 'path', details: { runner_registration_token: 'abc123' })
      end

      it "returns author's full_path" do
        allow(author_double).to receive(:is_a?).with(Gitlab::Audit::NullAuthor).and_return(true)
        expect(author_double).to receive(:full_path).and_return('author path')

        expect(audit_event).to receive(:author).at_least(:once).and_return(author_double)
        expect(presenter.author_url).to eq('author path')
      end
    end
  end

  describe '#target' do
    it 'delegates to the model object' do
      expect(presenter.target).to equal(audit_event.target_details)
    end
  end

  context 'exposes the ip address' do
    it 'exposes the database value by default' do
      expect(presenter.ip_address).to eq('10.2.1.1')
    end

    it 'survives a round trip from JSON' do
      expect(Gitlab::Json.parse(presenter.ip_address.to_json)).to eq(presenter.ip_address)
    end
  end

  context 'exposes the object' do
    it 'returns the object path if it exists' do
      expect(presenter.object).to eq(audit_event.entity_path)
    end

    it 'returns the stored name if it has been deleted' do
      audit_event.entity_id = nil

      expect(presenter.object).to be_blank
    end

    it 'returns the object url if it exists' do
      expect(presenter.object_url).to eq(url_for(audit_event.entity))
    end

    it 'returns no object url if it has been deleted' do
      audit_event.entity_id = nil

      expect(presenter.object_url).to be_blank
    end

    context 'when object is of type instance scope' do
      let_it_be(:audit_event) do
        create(
          :audit_event, :instance_event
        )
      end

      it 'returns the instance admin root url' do
        expect(presenter.object_url).to eq(Gitlab::Routing.url_helpers.admin_root_url)
      end
    end

    context 'when a project in a user namespace has been deleted' do
      let(:project) { build(:project, namespace: create(:user).namespace).destroy! }
      let(:audit_event) do
        build(
          :audit_event,
          entity_type: 'Namespaces::UserNamespace',
          entity_id: project.parent.id,
          target_type: "Project"
        )
      end

      it 'returns no object url' do
        expect(presenter.object_url).to be_blank
      end
    end
  end

  it 'exposes the date' do
    expect(presenter.date).to eq(audit_event.created_at.utc)
  end

  it 'exposes the action' do
    expect(presenter.action).to eq('Changed name from a to b')
  end
end
