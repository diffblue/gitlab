import Api from 'ee/api';
import { PAYMENT_FORM_ID } from 'ee/subscriptions/constants';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import Tracking from '~/tracking';
import { addExperimentContext } from '~/tracking/utils';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { s__, sprintf } from '~/locale';
import { trackCheckout, trackTransaction } from '~/google_tag_manager';
import { isInvalidPromoCodeError } from 'ee/subscriptions/new/utils';
import { ActiveModelError } from 'ee/vue_shared/purchase_flow/utils/purchase_errors';
import defaultClient from '../graphql';
import * as types from './mutation_types';

const trackConfirmOrder = (message) =>
  Tracking.event(
    'default',
    'click_button',
    addExperimentContext({
      label: 'confirm_purchase',
      property: message,
    }),
  );

export const updateSelectedPlan = ({ commit, getters }, selectedPlan) => {
  commit(types.UPDATE_SELECTED_PLAN, selectedPlan);
  commit(types.UPDATE_PROMO_CODE, null);
  trackCheckout(selectedPlan, getters.confirmOrderParams?.subscription?.quantity);
};

export const updateSelectedGroup = ({ commit }, selectedGroup) => {
  commit(types.UPDATE_SELECTED_GROUP, selectedGroup);
  commit(types.UPDATE_ORGANIZATION_NAME, null);
};

export const toggleIsSetupForCompany = ({ state, commit }) => {
  commit(types.UPDATE_IS_SETUP_FOR_COMPANY, !state.isSetupForCompany);
};

export const updateNumberOfUsers = ({ commit, getters }, numberOfUsers) => {
  commit(types.UPDATE_NUMBER_OF_USERS, numberOfUsers || 0);
  trackCheckout(getters.selectedPlanDetails?.value, numberOfUsers);
};

export const updateOrganizationName = ({ commit }, organizationName) => {
  commit(types.UPDATE_ORGANIZATION_NAME, organizationName);
};

export const updatePromoCode = ({ commit }, promoCode) => {
  commit(types.UPDATE_PROMO_CODE, promoCode);
};

export const fetchCountries = ({ dispatch }) =>
  Api.fetchCountries()
    .then(({ data }) => dispatch('fetchCountriesSuccess', data))
    .catch(() => dispatch('fetchCountriesError'));

export const fetchCountriesSuccess = ({ commit }, data = []) => {
  const countries = data.map((country) => ({ text: country[0], value: country[1] }));

  commit(types.UPDATE_COUNTRY_OPTIONS, countries);
};

export const fetchCountriesError = ({ dispatch }) => {
  dispatch(
    'confirmOrderError',
    new Error(s__('Checkout|Failed to load countries. Please try again.')),
  );
};

export const fetchStates = ({ state, dispatch }) => {
  dispatch('resetStates');

  if (!state.country) {
    return;
  }

  Api.fetchStates(state.country)
    .then(({ data }) => dispatch('fetchStatesSuccess', data))
    .catch(() => dispatch('fetchStatesError'));
};

export const fetchStatesSuccess = ({ commit }, data = {}) => {
  const states = Object.keys(data).map((state) => ({ text: state, value: data[state] }));

  commit(types.UPDATE_STATE_OPTIONS, states);
};

export const fetchStatesError = ({ dispatch }) => {
  dispatch(
    'confirmOrderError',
    new Error(s__('Checkout|Failed to load states. Please try again.')),
  );
};

export const resetStates = ({ commit }) => {
  commit(types.UPDATE_COUNTRY_STATE, null);
  commit(types.UPDATE_STATE_OPTIONS, []);
};

export const updateCountry = ({ commit }, country) => {
  commit(types.UPDATE_COUNTRY, country);
};

export const updateStreetAddressLine1 = ({ commit }, streetAddressLine1) => {
  commit(types.UPDATE_STREET_ADDRESS_LINE_ONE, streetAddressLine1);
};

export const updateStreetAddressLine2 = ({ commit }, streetAddressLine2) => {
  commit(types.UPDATE_STREET_ADDRESS_LINE_TWO, streetAddressLine2);
};

export const updateCity = ({ commit }, city) => {
  commit(types.UPDATE_CITY, city);
};

export const updateCountryState = ({ commit }, countryState) => {
  commit(types.UPDATE_COUNTRY_STATE, countryState);
};

export const updateZipCode = ({ commit }, zipCode) => {
  commit(types.UPDATE_ZIP_CODE, zipCode);
};

export const updateInvoicePreview = ({ commit }, invoicePreview) => {
  commit(types.UPDATE_INVOICE_PREVIEW, invoicePreview);
};

export const updateInvoicePreviewLoading = ({ commit }, isLoading) => {
  commit(types.UPDATE_INVOICE_PREVIEW_LOADING, isLoading);
};

export const startLoadingZuoraScript = ({ commit }) =>
  commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

export const fetchPaymentFormParams = ({ dispatch }) =>
  Api.fetchPaymentFormParams(PAYMENT_FORM_ID)
    .then(({ data }) => dispatch('fetchPaymentFormParamsSuccess', data))
    .catch(() => dispatch('fetchPaymentFormParamsError'));

export const fetchPaymentFormParamsSuccess = ({ commit, dispatch }, data) => {
  if (data.errors) {
    const message = sprintf(
      s__('Checkout|Credit card form failed to load: %{message}'),
      {
        message: data.errors,
      },
      false,
    );
    dispatch('confirmOrderError', new Error(message));
  } else {
    commit(types.UPDATE_PAYMENT_FORM_PARAMS, data);
  }
};

export const fetchPaymentFormParamsError = ({ dispatch }) => {
  dispatch(
    'confirmOrderError',
    new Error(s__('Checkout|Credit card form failed to load. Please try again.')),
  );
};

export const zuoraIframeRendered = ({ commit }) =>
  commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, false);

export const paymentFormSubmitted = ({ dispatch, commit }, response) => {
  if (response.success) {
    commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

    dispatch('paymentFormSubmittedSuccess', response.refId);
  } else {
    dispatch('paymentFormSubmittedError', response);
  }
};

export const paymentFormSubmittedSuccess = ({ commit, dispatch }, paymentMethodId) => {
  commit(types.UPDATE_PAYMENT_METHOD_ID, paymentMethodId);

  dispatch('fetchPaymentMethodDetails');
};

export const paymentFormSubmittedError = ({ dispatch }, response) => {
  const message = sprintf(
    s__('Checkout|Submitting the credit card form failed with code %{errorCode}: %{errorMessage}'),
    response,
    false,
  );
  dispatch('confirmOrderError', new Error(message));
};

export const fetchPaymentMethodDetails = ({ state, dispatch, commit }) =>
  Api.fetchPaymentMethodDetails(state.paymentMethodId)
    .then(({ data }) => dispatch('fetchPaymentMethodDetailsSuccess', data))
    .catch(() => dispatch('fetchPaymentMethodDetailsError'))
    .finally(() => commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, false));

export const fetchPaymentMethodDetailsSuccess = ({ commit, dispatch }, creditCardDetails) => {
  commit(types.UPDATE_CREDIT_CARD_DETAILS, creditCardDetails);

  defaultClient
    .mutate({
      mutation: activateNextStepMutation,
    })
    .catch((error) => {
      dispatch('confirmOrderError', error);
    });
};

export const fetchPaymentMethodDetailsError = ({ dispatch }) => {
  dispatch(
    'confirmOrderError',
    new Error(s__('Checkout|Failed to register credit card. Please try again.')),
  );
};

const shouldShowErrorMessageOnly = (errors) => {
  if (!errors?.message) {
    return false;
  }

  return isInvalidPromoCodeError(errors);
};

export const confirmOrder = ({ getters, dispatch, commit }) => {
  commit(types.UPDATE_IS_CONFIRMING_ORDER, true);

  Api.confirmOrder(getters.confirmOrderParams)
    .then(({ data }) => {
      if (data.location) {
        const transactionDetails = {
          paymentOption: getters.confirmOrderParams?.subscription?.payment_method_id,
          revenue: getters.totalExVat,
          tax: getters.vat,
          selectedPlan: getters.selectedPlanDetails?.value,
          quantity: getters.confirmOrderParams?.subscription?.quantity,
        };

        trackTransaction(transactionDetails);
        trackConfirmOrder(s__('Checkout|Success: subscription'));

        dispatch('confirmOrderSuccess', {
          location: data.location,
        });
      } else {
        let errorMessage;
        if (data.name) {
          errorMessage = sprintf(
            s__('Checkout|Name: %{errorMessage}'),
            { errorMessage: data.name.join(', ') },
            false,
          );
        } else if (shouldShowErrorMessageOnly(data.errors)) {
          errorMessage = data.errors?.message;
        } else {
          errorMessage = data.errors;
        }

        trackConfirmOrder(errorMessage);
        dispatch(
          'confirmOrderError',
          new ActiveModelError(data.error_attribute_map, JSON.stringify(errorMessage)),
        );
      }
    })
    .catch((error) => {
      trackConfirmOrder(error.message);
      dispatch('confirmOrderError', error);
    });
};

export const confirmOrderSuccess = (_, { location }) => {
  redirectTo(location); // eslint-disable-line import/no-deprecated
};

export const confirmOrderError = ({ commit }) => {
  commit(types.UPDATE_IS_CONFIRMING_ORDER, false);
};
