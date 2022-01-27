# frozen_string_literal: true

# Needed for Geo with unified URLs, regular requests to /api/graphql get proxied to
# the primary, while these are local requests that bypass the proxy
match '/api/v4/geo/graphql', via: [:get, :post], to: 'graphql#execute'
