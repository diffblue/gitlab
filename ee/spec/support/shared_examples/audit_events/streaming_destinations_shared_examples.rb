# frozen_string_literal: true

# It expects a variable `current_user` which will be a user who has authorization for the resource ,
# it maybe a group owner or instance admin as per the type of destination.
# It also assumes the old name and url of the destination are `Old Destination` and `https://example.com/old`
# respectively.
RSpec.shared_examples 'audits update to external streaming destination' do
  context 'when both destination url and destination name are updated' do
    let(:input) do
      {
        id: GitlabSchema.id_from_object(destination).to_s,
        destinationUrl: "https://example.com/new",
        name: "New Destination"
      }
    end

    it 'audits the update' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { AuditEvent.count }.by(2)

      audit_events = AuditEvent.last(2)
      expect(audit_events[0].details[:custom_message])
        .to match("Changed destination_url from https://example.com/old to https://example.com/new")
      expect(audit_events[1].details[:custom_message])
        .to match("Changed name from Old Destination to New Destination")
    end
  end

  context 'when only destination url is updated' do
    let(:input) do
      {
        id: GitlabSchema.id_from_object(destination).to_s,
        destinationUrl: "https://example.com/new"
      }
    end

    it 'audits the update' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { AuditEvent.count }.by(1)

      expect(AuditEvent.last.details[:custom_message])
        .to match("Changed destination_url from https://example.com/old to https://example.com/new")
    end
  end

  context 'when only destination name is updated' do
    let(:input) do
      {
        id: GitlabSchema.id_from_object(destination).to_s,
        name: "New Destination"
      }
    end

    it 'audits the update' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { AuditEvent.count }.by(1)

      expect(AuditEvent.last.details[:custom_message]).to match("Changed name from Old Destination to New Destination")
    end
  end
end
