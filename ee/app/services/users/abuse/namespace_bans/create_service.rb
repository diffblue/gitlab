# frozen_string_literal: true

module Users
  module Abuse
    module NamespaceBans
      class CreateService < BaseService
        attr_accessor :user, :namespace

        def initialize(user:, namespace:)
          @user = user
          @namespace = namespace
        end

        def execute
          ban = ::Namespaces::NamespaceBan.new(user: user, namespace: namespace)
          if ban.save
            success
          else
            messages = ban.errors.full_messages
            error(messages.uniq.join('. '))
          end
        end
      end
    end
  end
end
