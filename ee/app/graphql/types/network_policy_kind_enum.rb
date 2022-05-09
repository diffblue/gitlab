# frozen_string_literal: true

module Types
  class NetworkPolicyKindEnum < BaseEnum
    graphql_name 'NetworkPolicyKind'
    description 'Kind of the network policy'

    value 'CiliumNetworkPolicy', 'Policy kind of Cilium Network Policy.'
    value 'NetworkPolicy', 'Policy kind of Network Policy.'
  end
end
