import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';

export const assignedAddonData = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/13',
      addOnPurchase: {
        id: 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/3',
        name: ADD_ON_CODE_SUGGESTIONS,
        assignedQuantity: 5,
        purchasedQuantity: 20,
        __typename: 'AddOnPurchase',
      },
      __typename: 'Namespace',
    },
  },
};

export const noAssignedAddonData = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/13',
      addOnPurchase: {
        id: 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/3',
        name: ADD_ON_CODE_SUGGESTIONS,
        assignedQuantity: 0,
        purchasedQuantity: 20,
        __typename: 'AddOnPurchase',
      },
      __typename: 'Namespace',
    },
  },
};

export const noPurchasedAddonData = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/13',
      addOnPurchase: null,
    },
  },
};

export const purchasedAddonFuzzyData = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/13',
      addOnPurchase: {
        id: 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/3',
        name: ADD_ON_CODE_SUGGESTIONS,
        assignedQuantity: 0,
        purchasedQuantity: undefined,
        __typename: 'AddOnPurchase',
      },
      __typename: 'Namespace',
    },
  },
};
