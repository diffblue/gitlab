# frozen_string_literal: true

module EE
  module Types
    module UserInterface
      extend ActiveSupport::Concern

      prepended do
        field :workspaces,
          description: 'Workspaces owned by the current user.',
          resolver: ::Resolvers::RemoteDevelopment::WorkspacesResolver
      end
    end
  end
end
