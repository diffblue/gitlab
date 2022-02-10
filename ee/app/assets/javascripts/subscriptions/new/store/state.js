import { parseBoolean } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { TAX_RATE } from '../constants';

const parsePlanData = (planData) =>
  JSON.parse(planData).map((plan) => ({
    value: plan.id,
    text: capitalizeFirstCharacter(plan.name),
    pricePerUserPerYear: plan.price_per_year,
    code: plan.code,
  }));

const parseGroupData = (groupData) =>
  JSON.parse(groupData).map((group) => ({
    value: group.id,
    text: group.name,
    numberOfUsers: group.users,
    numberOfGuests: group.guests,
  }));

const determineSelectedPlan = (planId, plans) => {
  if (planId && plans.find((plan) => plan.value === planId)) {
    return planId;
  }
  return plans[0] && plans[0].value;
};

const determineNumberOfUsers = (groupId, groups) => {
  if (!groupId || !groups) {
    return 1;
  }

  const chosenGroup = groups.find((group) => group.value === groupId);

  if (chosenGroup?.numberOfUsers > 1) {
    return chosenGroup.numberOfUsers;
  }

  return 1;
};

export default ({
  availablePlans: plansData = '[]',
  planId,
  namespaceId,
  setupForCompany,
  fullName,
  newUser,
  groupData = '[]',
  source,
  trial,
  newTrialRegistrationPath,
}) => {
  const availablePlans = parsePlanData(plansData);
  const isNewUser = parseBoolean(newUser);
  const groupId = parseInt(namespaceId, 10) || null;
  const groups = parseGroupData(groupData);
  const isTrial = parseBoolean(trial);

  return {
    isSetupForCompany: setupForCompany === '' ? !isNewUser : parseBoolean(setupForCompany),
    availablePlans,
    selectedPlan: determineSelectedPlan(planId, availablePlans),
    isNewUser,
    fullName,
    groupData: groups,
    selectedGroup: groupId,
    organizationName: null,
    numberOfUsers: determineNumberOfUsers(groupId, groups),
    country: null,
    streetAddressLine1: null,
    streetAddressLine2: null,
    city: null,
    countryState: null,
    zipCode: null,
    countryOptions: [],
    stateOptions: [],
    paymentFormParams: {},
    paymentMethodId: null,
    creditCardDetails: {},
    isLoadingPaymentMethod: false,
    isConfirmingOrder: false,
    taxRate: TAX_RATE,
    startDate: new Date(Date.now()),
    source,
    isTrial,
    newTrialRegistrationPath,
  };
};
