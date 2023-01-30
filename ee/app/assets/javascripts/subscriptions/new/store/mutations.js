import * as types from './mutation_types';

export default {
  [types.UPDATE_SELECTED_PLAN](state, selectedPlan) {
    state.selectedPlan = selectedPlan;
  },

  [types.UPDATE_SELECTED_GROUP](state, selectedGroup) {
    state.selectedGroup = selectedGroup;
  },

  [types.UPDATE_IS_SETUP_FOR_COMPANY](state, isSetupForCompany) {
    state.isSetupForCompany = isSetupForCompany;
  },

  [types.UPDATE_NUMBER_OF_USERS](state, numberOfUsers) {
    state.numberOfUsers = numberOfUsers;
  },

  [types.UPDATE_ORGANIZATION_NAME](state, organizationName) {
    state.organizationName = organizationName;
  },

  [types.UPDATE_COUNTRY_OPTIONS](state, countryOptions) {
    state.countryOptions = countryOptions;
  },

  [types.UPDATE_STATE_OPTIONS](state, stateOptions) {
    state.stateOptions = stateOptions;
  },

  [types.UPDATE_COUNTRY](state, country) {
    state.country = country;
  },

  [types.UPDATE_STREET_ADDRESS_LINE_ONE](state, streetAddressLine1) {
    state.streetAddressLine1 = streetAddressLine1;
  },

  [types.UPDATE_STREET_ADDRESS_LINE_TWO](state, streetAddressLine2) {
    state.streetAddressLine2 = streetAddressLine2;
  },

  [types.UPDATE_CITY](state, city) {
    state.city = city;
  },

  [types.UPDATE_COUNTRY_STATE](state, countryState) {
    state.countryState = countryState;
  },

  [types.UPDATE_ZIP_CODE](state, zipCode) {
    state.zipCode = zipCode;
  },

  [types.UPDATE_PAYMENT_FORM_PARAMS](state, paymentFormParams) {
    state.paymentFormParams = paymentFormParams;
  },

  [types.UPDATE_PAYMENT_METHOD_ID](state, paymentMethodId) {
    state.paymentMethodId = paymentMethodId;
  },

  [types.UPDATE_CREDIT_CARD_DETAILS](state, creditCardDetails) {
    state.creditCardDetails = creditCardDetails;
  },

  [types.UPDATE_IS_LOADING_PAYMENT_METHOD](state, isLoadingPaymentMethod) {
    state.isLoadingPaymentMethod = isLoadingPaymentMethod;
  },

  [types.UPDATE_IS_CONFIRMING_ORDER](state, isConfirmingOrder) {
    state.isConfirmingOrder = isConfirmingOrder;
  },
};
