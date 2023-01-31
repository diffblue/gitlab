import createClient from '~/lib/graphql';

export const createCustomersDotClient = (resolvers = {}, config = {}) =>
  createClient(resolvers, {
    path: '/-/customers_dot/proxy/graphql',
    useGet: true,
    ...config,
  });
