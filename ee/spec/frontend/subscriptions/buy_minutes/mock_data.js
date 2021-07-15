import { STEPS } from 'ee/subscriptions/constants';

export const mockCiMinutesPlans = [
  {
    id: 'ciMinutesPackPlanId',
    code: 'ci_minutes',
    pricePerYear: 10,
    name: '1000 CI minutes pack',
    __typename: 'Plan',
  },
];
export const mockNamespaces =
  '[{"id":132,"name":"Gitlab Org","users":3},{"id":483,"name":"Gnuwget","users":12}]';

export const mockParsedNamespaces = [
  { __typename: 'Namespace', id: 132, name: 'Gitlab Org', users: 3 },
  { __typename: 'Namespace', id: 483, name: 'Gnuwget', users: 12 },
];

export const mockNewUser = 'false';
export const mockFullName = 'John Admin';
export const mockSetupForCompany = 'true';

export const stateData = {
  namespaces: [],
  subscription: {
    quantity: 1,
    namespaceId: null,
    __typename: 'Subscription',
  },
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
