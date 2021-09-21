import VueApollo from 'vue-apollo';
import { writeInitialDataToApolloCache } from 'ee/subscriptions/buy_addons_shared/utils';
import plansQuery from 'ee/subscriptions/graphql/queries/plans.customer.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import { mockCiMinutesPlans, mockDefaultCache } from './mock_data';

export function createMockApolloProvider(mockResponses = {}, dataset = {}) {
  const {
    plansQueryMock = jest.fn().mockResolvedValue({ data: { plans: mockCiMinutesPlans } }),
  } = mockResponses;

  const { quantity } = dataset;

  const mockDefaultClient = createMockClient();
  const mockCustomerClient = createMockClient([[plansQuery, plansQueryMock]]);

  const apolloProvider = new VueApollo({
    defaultClient: mockDefaultClient,
    clients: { customerClient: mockCustomerClient },
  });

  writeInitialDataToApolloCache(apolloProvider, {
    ...mockDefaultCache,
    subscriptionQuantity: quantity,
  });

  return apolloProvider;
}
