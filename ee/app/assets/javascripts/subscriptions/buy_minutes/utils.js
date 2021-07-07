import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

function arrayToGraphqlArray(arr, typename) {
  return Array.from(arr, (item) => {
    return Object.assign(convertObjectPropsToCamelCase(item, { deep: true }), {
      __typename: typename,
    });
  });
}

export function writeInitialDataToApolloCache(apolloProvider, dataset) {
  const { groupData, namespaceId, planId = null } = dataset;
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const namespaces = arrayToGraphqlArray(JSON.parse(groupData), 'Namespace');

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: stateQuery,
    data: {
      isNewUser: false,
      fullName: null,
      isSetupForCompany: false,
      selectedPlanId: planId,
      namespaces,
      subscription: {
        quantity: 1,
        namespaceId,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        __typename: 'Subscription',
      },
      paymentMethod: {
        id: null,
        creditCardExpirationMonth: null,
        creditCardExpirationYear: null,
        creditCardType: null,
        creditCardMaskNumber: null,
        __typename: 'PaymentMethod',
      },
      customer: {
        country: null,
        address1: null,
        address2: null,
        city: null,
        state: null,
        zipCode: null,
        company: null,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        __typename: 'Customer',
      },
      activeStep: STEPS[0],
      stepList: STEPS,
    },
  });
}
