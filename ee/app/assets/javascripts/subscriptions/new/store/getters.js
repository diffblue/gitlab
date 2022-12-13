import { s__ } from '~/locale';
import { NEW_GROUP, ULTIMATE } from '../constants';

export const selectedPlanText = (state, getters) => getters.selectedPlanDetails.text;

export const selectedPlanPrice = (state, getters) =>
  getters.selectedPlanDetails.pricePerUserPerYear;

export const selectedPlanDetails = (state) =>
  state.availablePlans.find((plan) => plan.value === state.selectedPlan);

export const isUltimatePlan = (state, getters) => {
  return getters.selectedPlanDetails?.code === ULTIMATE;
};

export const confirmOrderParams = (state, getters) => ({
  setup_for_company: state.isSetupForCompany,
  selected_group: getters.selectedGroupId,
  new_user: state.isNewUser,
  customer: {
    country: state.country,
    address_1: state.streetAddressLine1,
    address_2: state.streetAddressLine2,
    city: state.city,
    state: state.countryState,
    zip_code: state.zipCode,
    company: state.organizationName,
  },
  subscription: {
    plan_id: state.selectedPlan,
    payment_method_id: state.paymentMethodId,
    quantity: state.numberOfUsers,
    source: state.source,
  },
});

export const endDate = (state) =>
  new Date(state.startDate).setFullYear(state.startDate.getFullYear() + 1);

export const totalExVat = (state, getters) => state.numberOfUsers * getters.selectedPlanPrice;

export const vat = (state, getters) => state.taxRate * getters.totalExVat;

export const totalAmount = (_, getters) => getters.totalExVat + getters.vat;

export const name = (state, getters) => {
  if (state.isSetupForCompany && state.organizationName) {
    return state.organizationName;
  } else if (getters.isGroupSelected && getters.isSelectedGroupPresent) {
    return getters.selectedGroupName;
  } else if (state.isSetupForCompany) {
    return s__('Checkout|Your organization');
  }

  return state.fullName;
};

export const usersPresent = (state) => state.numberOfUsers > 0;

export const isGroupSelected = (state) =>
  state.selectedGroup !== null && state.selectedGroup !== NEW_GROUP;

export const isSelectedGroupPresent = (state, getters) => Boolean(getters.selectedGroupData);

export const isEligibleToUsePromoCode = (_, getters) =>
  getters.selectedPlanDetails?.isEligibleToUsePromoCode;

export const selectedGroupData = (state, getters) => {
  if (!getters.isGroupSelected) {
    return null;
  }

  return state.groupData.find((group) => group.value === state.selectedGroup);
};

export const selectedGroupName = (state, getters) => {
  return getters.selectedGroupData?.text;
};

export const selectedGroupId = (state, getters) =>
  getters.isGroupSelected ? state.selectedGroup : null;
