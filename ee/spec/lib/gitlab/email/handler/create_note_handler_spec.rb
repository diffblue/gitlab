# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::CreateNoteHandler do
  include_context 'email shared context'

  before do
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
    stub_licensed_features(epics: true)
    group.add_developer(user)
  end

  let(:email_raw) { fixture_file('emails/valid_reply.eml') }
  let(:group) { create(:group) }
  let(:user) { create(:user, email: 'jake@adventuretime.ooo') }
  let(:noteable) { create(:epic, group: group) }
  let(:note) { create(:note, project: nil, noteable: noteable) }

  let!(:sent_notification) do
    SentNotification.record_note(note, user.id, mail_key)
  end

  context "when the note could not be saved" do
    before do
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56711#note_551958817
      allow_any_instance_of(Note).to receive(:persisted?).and_return(false) # rubocop:disable RSpec/AnyInstanceOf
    end

    it "raises an InvalidNoteError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::InvalidNoteError)
    end
  end

  context 'when the note contains quick actions' do
    let!(:email_raw) { fixture_file("emails/commands_in_reply.eml") }

    context 'and current user cannot update the noteable' do
      it 'only executes the commands that the user can perform' do
        expect { receiver.execute }
          .to change { noteable.notes.user.count }.by(1)
      end
    end

    context 'and current user can update noteable' do
      before do
        group.add_developer(user)
      end

      it 'posts a note and updates the noteable' do
        expect(TodoService.new.todo_exist?(noteable, user)).to be_falsy

        expect { receiver.execute }
          .to change { noteable.notes.user.count }.by(1)
      end
    end
  end

  context "when the reply is blank" do
    let!(:email_raw) { fixture_file("emails/no_content_reply.eml") }

    it "raises an EmptyEmailError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
    end
  end

  context "when everything is fine" do
    before do
      setup_attachment
    end

    it "creates a comment" do
      expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      new_note = noteable.notes.last

      expect(new_note.author).to eq(sent_notification.recipient)
      expect(new_note.position).to eq(note.position)
      expect(new_note.note).to include("I could not disagree more.")
      expect(new_note.in_reply_to?(note)).to be_truthy
    end

    it "adds all attachments" do
      expect_next_instance_of(Gitlab::Email::AttachmentUploader) do |uploader|
        expect(uploader).to receive(:execute).with(upload_parent: group, uploader_class: NamespaceFileUploader).and_return(
          [
            {
              url: "uploads/image.png",
              alt: "image",
              markdown: markdown
            }
          ]
        )
      end

      receiver.execute

      note = noteable.notes.last
      expect(note.note).to include(markdown)
    end

    context 'when sub-addressing is not supported' do
      before do
        stub_incoming_email_setting(enabled: true, address: nil)
      end

      shared_examples 'an email that contains a mail key' do |header|
        it "fetches the mail key from the #{header} header and creates a comment" do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
          new_note = noteable.notes.last

          expect(new_note.author).to eq(sent_notification.recipient)
          expect(new_note.position).to eq(note.position)
          expect(new_note.note).to include('I could not disagree more.')
        end
      end

      context 'mail key is in the References header' do
        let(:email_raw) { fixture_file('emails/reply_without_subaddressing_and_key_inside_references.eml') }

        it_behaves_like 'an email that contains a mail key', 'References'
      end

      context 'mail key is in the References header with a comma' do
        let(:email_raw) { fixture_file('emails/reply_without_subaddressing_and_key_inside_references_with_a_comma.eml') }

        it_behaves_like 'an email that contains a mail key', 'References'
      end
    end
  end
end
