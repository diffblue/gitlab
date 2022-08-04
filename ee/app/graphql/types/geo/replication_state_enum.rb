# frozen_string_literal: true

module Types
  module Geo
    class ReplicationStateEnum < BaseEnum
      value 'PENDING', value: 'pending', description: 'Replication process has not started.'
      value 'STARTED', value: 'started', description: 'Replication process is in progress.'
      value 'SYNCED',  value: 'synced', description: 'Replication process finished successfully.'
      value 'FAILED',  value: 'failed', description: 'Replication process finished but failed.'
    end
  end
end
