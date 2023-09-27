import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';

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

export const mockNoAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/176',
      addOnEligibleUsers: {
        edges: [],
      },
    },
  },
};

export const mockUserWithAddOnAssignment = {
  id: 'gid://gitlab/User/1',
  username: 'userone',
  name: 'User One',
  publicEmail: null,
  avatarUrl: 'path/to/img_userone',
  webUrl: 'path/to/userone',
  lastActivityOn: '2023-08-25',
  addOnAssignments: { nodes: [{ addOnPurchase: { name: 'CODE_SUGGESTIONS' } }] },
};

export const mockUserWithNoAddOnAssignment = {
  id: 'gid://gitlab/User/2',
  username: 'usertwo',
  name: 'User Two',
  publicEmail: null,
  avatarUrl: 'path/to/img_usertwo',
  webUrl: 'path/to/usertwo',
  lastActivityOn: '2023-08-22',
  addOnAssignments: { nodes: [] },
};

const eligibleUsers = [
  { node: mockUserWithAddOnAssignment },
  { node: mockUserWithNoAddOnAssignment },
];

export const mockAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      addOnEligibleUsers: {
        edges: eligibleUsers,
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
          __typename: 'PageInfo',
        },
      },
    },
  },
};

export const mockPaginatedAddOnEligibleUsers = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      addOnEligibleUsers: {
        edges: eligibleUsers,
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
          __typename: 'PageInfo',
        },
      },
    },
  },
};
