import { parseBoolean } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { TAX_RATE } from '../constants';

const parsePlanData = (planData) =>
  JSON.parse(planData).map((plan) => ({
    value: plan.id,
    text: capitalizeFirstCharacter(plan.name),
    code: plan.code,
    isEligibleToUsePromoCode: plan.eligible_to_use_promo_code,
    promotionalOfferText: plan.promotional_offer_text,
  }));

const parseGroupData = (groupData) =>
  JSON.parse(groupData).map((group) => ({
    value: group.id,
    text: group.name,
    fullPath: group.full_path,
  }));

const determineSelectedPlan = (planId, plans) => {
  if (planId && plans.find((plan) => plan.value === planId)) {
    return planId;
  }
  return plans[0] && plans[0].value;
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
    numberOfUsers: 1,
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
    promoCode: null,
    creditCardDetails: {},
    isLoadingPaymentMethod: false,
    isConfirmingOrder: false,
    isInvoicePreviewLoading: false,
    invoicePreview: null,
    taxRate: TAX_RATE,
    startDate: new Date(Date.now()),
    source,
    isTrial,
    newTrialRegistrationPath,
  };
};
