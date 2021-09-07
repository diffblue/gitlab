import createGqClient, { fetchPolicies } from '~/lib/graphql';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);
