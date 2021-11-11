import {
  CUSTOMER_TYPE,
  NAMESPACE_TYPE,
  SUBSCRIPTION_TYPE,
  PAYMENT_METHOD_TYPE,
  PLAN_TYPE,
} from 'ee/subscriptions/buy_addons_shared/constants';
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
  const {
    activeSubscriptionName = '',
    groupData,
    namespaceId,
    redirectAfterSuccess,
    subscriptionQuantity,
  } = dataset;

  const eligibleNamespaces = arrayToGraphqlArray(JSON.parse(groupData), NAMESPACE_TYPE);
  const quantity = subscriptionQuantity || 1;

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: stateQuery,
    data: {
      activeSubscription: {
        name: activeSubscriptionName,
        __typename: SUBSCRIPTION_TYPE,
      },
      isNewUser: false,
      fullName: null,
      isSetupForCompany: false,
      selectedPlan: {
        id: null,
        isAddon: false,
        __typename: PLAN_TYPE,
      },
      eligibleNamespaces,
      redirectAfterSuccess,
      selectedNamespaceId: namespaceId,
      subscription: {
        quantity,
        __typename: SUBSCRIPTION_TYPE,
      },
      paymentMethod: {
        id: null,
        creditCardExpirationMonth: null,
        creditCardExpirationYear: null,
        creditCardType: null,
        creditCardMaskNumber: null,
        __typename: PAYMENT_METHOD_TYPE,
      },
      customer: {
        country: null,
        address1: null,
        address2: null,
        city: null,
        state: null,
        zipCode: null,
        company: null,
        __typename: CUSTOMER_TYPE,
      },
      activeStep: STEPS[0],
      stepList: STEPS,
    },
  });
}
