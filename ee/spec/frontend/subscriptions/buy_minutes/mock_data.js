import { STEPS } from 'ee/subscriptions/constants';

export const accountId = '111111111111';

export const mockCiMinutesPlans = [
  {
    id: 'ciMinutesPackPlanId',
    code: 'ci_minutes',
    pricePerYear: 10,
    name: 'CI minutes pack',
    __typename: 'Plan',
  },
];

export const mockNamespaces = `
  [{"id":132,"accountId":"${accountId}","name":"Gitlab Org","users":3},
  {"id":483,"accountId":null,"name":"Gnuwget","users":12}]
`;

export const mockParsedNamespaces = JSON.parse(mockNamespaces).map((namespace) => ({
  ...namespace,
  __typename: 'Namespace',
}));

export const mockNewUser = 'false';
export const mockSetupForCompany = 'true';

export const mockDefaultCache = {
  groupData: mockNamespaces,
  namespaceId: 132,
  redirectAfterSuccess: '/',
};

export const stateData = {
  eligibleNamespaces: [],
  subscription: {
    quantity: 1,
    __typename: 'Subscription',
  },
  redirectAfterSuccess: '/path/to/redirect/',
  selectedNamespaceId: '30',
  selectedPlanId: null,
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
    __typename: 'Customer',
  },
  fullName: 'Full Name',
  isNewUser: false,
  isSetupForCompany: true,
  stepList: STEPS,
  activeStep: STEPS[0],
};
