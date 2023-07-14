# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class VolumeComponentInjector
        include Messages

        # @param [Hash] value
        # @return [Hash]
        def self.inject(value)
          value => { processed_devfile: Hash => processed_devfile, volume_mounts: Hash => volume_mounts }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => { name: String => volume_name }

          component = {
            'name' => volume_name,
            'volume' => {
              'size' => '15Gi'
            }
          }

          processed_devfile['components'] << component

          value
        end
      end
    end
  end
end
