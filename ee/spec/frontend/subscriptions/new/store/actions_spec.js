import MockAdapter from 'axios-mock-adapter';
import Api from 'ee/api';
import * as constants from 'ee/subscriptions/constants';
import defaultClient from 'ee/subscriptions/new/graphql';
import * as actions from 'ee/subscriptions/new/store/actions';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as googleTagManager from '~/google_tag_manager';

const {
  countriesPath,
  countryStatesPath,
  paymentFormPath,
  paymentMethodPath,
  confirmOrderPath,
} = Api;

jest.mock('~/flash');

describe('Subscriptions Actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(defaultClient, 'mutate');
  });

  afterEach(() => {
    mock.restore();
    defaultClient.mutate.mockClear();
  });

  describe('updateSelectedPlan', () => {
    it('updates the selected plan and updates the number of users', async () => {
      await testAction(
        actions.updateSelectedPlan,
        'planId',
        { selectedGroupUsers: 4 },
        [
          { type: 'UPDATE_SELECTED_PLAN', payload: 'planId' },
          { type: 'UPDATE_NUMBER_OF_USERS', payload: 4 },
        ],
        [],
      );
    });
  });

  describe('updateSelectedGroup', () => {
    it('updates the selected group, resets the organization name and updates the number of users', async () => {
      await testAction(
        actions.updateSelectedGroup,
        'groupId',
        { selectedGroupUsers: 3 },
        [
          { type: 'UPDATE_SELECTED_GROUP', payload: 'groupId' },
          { type: 'UPDATE_ORGANIZATION_NAME', payload: null },
          { type: 'UPDATE_NUMBER_OF_USERS', payload: 3 },
        ],
        [],
      );
    });
  });

  describe('toggleIsSetupForCompany', () => {
    it('toggles the isSetupForCompany value', async () => {
      await testAction(
        actions.toggleIsSetupForCompany,
        {},
        { isSetupForCompany: true },
        [{ type: 'UPDATE_IS_SETUP_FOR_COMPANY', payload: false }],
        [],
      );
    });
  });

  describe('updateNumberOfUsers', () => {
    it('updates numberOfUsers to 0 when no value is provided', async () => {
      await testAction(
        actions.updateNumberOfUsers,
        null,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 0 }],
        [],
      );
    });

    it('updates numberOfUsers when a value is provided', async () => {
      await testAction(
        actions.updateNumberOfUsers,
        2,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 2 }],
        [],
      );
    });
  });

  describe('updateOrganizationName', () => {
    it('updates organizationName to the provided value', async () => {
      await testAction(
        actions.updateOrganizationName,
        'name',
        {},
        [{ type: 'UPDATE_ORGANIZATION_NAME', payload: 'name' }],
        [],
      );
    });
  });

  describe('fetchCountries', () => {
    it('calls fetchCountriesSuccess with the returned data on success', async () => {
      mock.onGet(countriesPath).replyOnce(200, ['Netherlands', 'NL']);

      await testAction(
        actions.fetchCountries,
        null,
        {},
        [],
        [{ type: 'fetchCountriesSuccess', payload: ['Netherlands', 'NL'] }],
      );
    });

    it('calls fetchCountriesError on error', async () => {
      mock.onGet(countriesPath).replyOnce(500);

      await testAction(actions.fetchCountries, null, {}, [], [{ type: 'fetchCountriesError' }]);
    });
  });

  describe('fetchCountriesSuccess', () => {
    it('transforms and adds fetched countryOptions', async () => {
      await testAction(
        actions.fetchCountriesSuccess,
        [['Netherlands', 'NL']],
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [{ text: 'Netherlands', value: 'NL' }] }],
        [],
      );
    });

    it('adds an empty array when no data provided', async () => {
      await testAction(
        actions.fetchCountriesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [] }],
        [],
      );
    });
  });

  describe('fetchCountriesError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchCountriesError, null, {}, [], []);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to load countries. Please try again.',
      });
    });
  });

  describe('fetchStates', () => {
    it('calls resetStates and fetchStatesSuccess with the returned data on success', async () => {
      mock
        .onGet(countryStatesPath, { params: { country: 'NL' } })
        .replyOnce(200, { utrecht: 'UT' });

      await testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesSuccess', payload: { utrecht: 'UT' } }],
      );
    });

    it('only calls resetStates when no country selected', async () => {
      mock.onGet(countryStatesPath).replyOnce(500);

      await testAction(actions.fetchStates, null, { country: null }, [], [{ type: 'resetStates' }]);
    });

    it('calls resetStates and fetchStatesError on error', async () => {
      mock.onGet(countryStatesPath).replyOnce(500);

      await testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesError' }],
      );
    });
  });

  describe('fetchStatesSuccess', () => {
    it('transforms and adds received stateOptions', async () => {
      await testAction(
        actions.fetchStatesSuccess,
        { Utrecht: 'UT' },
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [{ text: 'Utrecht', value: 'UT' }] }],
        [],
      );
    });

    it('adds an empty array when no data provided', async () => {
      await testAction(
        actions.fetchStatesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [] }],
        [],
      );
    });
  });

  describe('fetchStatesError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchStatesError, null, {}, [], []);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to load states. Please try again.',
      });
    });
  });

  describe('resetStates', () => {
    it('resets the selected state and sets the stateOptions to the initial value', async () => {
      await testAction(
        actions.resetStates,
        null,
        {},
        [
          { type: 'UPDATE_COUNTRY_STATE', payload: null },
          { type: 'UPDATE_STATE_OPTIONS', payload: [] },
        ],
        [],
      );
    });
  });

  describe('updateCountry', () => {
    it('updates country to the provided value', async () => {
      await testAction(
        actions.updateCountry,
        'country',
        {},
        [{ type: 'UPDATE_COUNTRY', payload: 'country' }],
        [],
      );
    });
  });

  describe('updateStreetAddressLine1', () => {
    it('updates streetAddressLine1 to the provided value', async () => {
      await testAction(
        actions.updateStreetAddressLine1,
        'streetAddressLine1',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_ONE', payload: 'streetAddressLine1' }],
        [],
      );
    });
  });

  describe('updateStreetAddressLine2', () => {
    it('updates streetAddressLine2 to the provided value', async () => {
      await testAction(
        actions.updateStreetAddressLine2,
        'streetAddressLine2',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_TWO', payload: 'streetAddressLine2' }],
        [],
      );
    });
  });

  describe('updateCity', () => {
    it('updates city to the provided value', async () => {
      await testAction(
        actions.updateCity,
        'city',
        {},
        [{ type: 'UPDATE_CITY', payload: 'city' }],
        [],
      );
    });
  });

  describe('updateCountryState', () => {
    it('updates countryState to the provided value', async () => {
      await testAction(
        actions.updateCountryState,
        'countryState',
        {},
        [{ type: 'UPDATE_COUNTRY_STATE', payload: 'countryState' }],
        [],
      );
    });
  });

  describe('updateZipCode', () => {
    it('updates zipCode to the provided value', async () => {
      await testAction(
        actions.updateZipCode,
        'zipCode',
        {},
        [{ type: 'UPDATE_ZIP_CODE', payload: 'zipCode' }],
        [],
      );
    });
  });

  describe('startLoadingZuoraScript', () => {
    it('updates isLoadingPaymentMethod to true', async () => {
      await testAction(
        actions.startLoadingZuoraScript,
        undefined,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: true }],
        [],
      );
    });
  });

  describe('fetchPaymentFormParams', () => {
    it('fetches paymentFormParams and calls fetchPaymentFormParamsSuccess with the returned data on success', async () => {
      mock
        .onGet(paymentFormPath, { params: { id: constants.PAYMENT_FORM_ID } })
        .replyOnce(200, { token: 'x' });

      await testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsSuccess', payload: { token: 'x' } }],
      );
    });

    it('calls fetchPaymentFormParamsError on error', async () => {
      mock.onGet(paymentFormPath).replyOnce(500);

      await testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsError' }],
      );
    });
  });

  describe('fetchPaymentFormParamsSuccess', () => {
    it('updates paymentFormParams to the provided value when no errors are present', async () => {
      await testAction(
        actions.fetchPaymentFormParamsSuccess,
        { token: 'x' },
        {},
        [{ type: 'UPDATE_PAYMENT_FORM_PARAMS', payload: { token: 'x' } }],
        [],
      );
    });

    it('creates a flash when errors are present', async () => {
      await testAction(
        actions.fetchPaymentFormParamsSuccess,
        { errors: 'error message' },
        {},
        [],
        [],
      );
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Credit card form failed to load: error message',
      });
    });
  });

  describe('fetchPaymentFormParamsError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchPaymentFormParamsError, null, {}, [], []);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Credit card form failed to load. Please try again.',
      });
    });
  });

  describe('zuoraIframeRendered', () => {
    it('updates isLoadingPaymentMethod to false', async () => {
      await testAction(
        actions.zuoraIframeRendered,
        undefined,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [],
      );
    });
  });

  describe('paymentFormSubmitted', () => {
    describe('on success', () => {
      it('calls paymentFormSubmittedSuccess with the refID from the response and updates isLoadingPaymentMethod to true', async () => {
        await testAction(
          actions.paymentFormSubmitted,
          { success: true, refId: 'id' },
          {},
          [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: true }],
          [{ type: 'paymentFormSubmittedSuccess', payload: 'id' }],
        );
      });
    });

    describe('on failure', () => {
      it('calls paymentFormSubmittedError with the response', async () => {
        await testAction(
          actions.paymentFormSubmitted,
          { error: 'foo' },
          {},
          [],
          [{ type: 'paymentFormSubmittedError', payload: { error: 'foo' } }],
        );
      });
    });
  });

  describe('paymentFormSubmittedSuccess', () => {
    it('updates paymentMethodId to the provided value and calls fetchPaymentMethodDetails', async () => {
      await testAction(
        actions.paymentFormSubmittedSuccess,
        'id',
        {},
        [{ type: 'UPDATE_PAYMENT_METHOD_ID', payload: 'id' }],
        [{ type: 'fetchPaymentMethodDetails' }],
      );
    });
  });

  describe('paymentFormSubmittedError', () => {
    it('creates a flash', async () => {
      await testAction(
        actions.paymentFormSubmittedError,
        { errorCode: 'codeFromResponse', errorMessage: 'messageFromResponse' },
        {},
        [],
        [],
      );
      expect(createFlash).toHaveBeenCalledWith({
        message:
          'Submitting the credit card form failed with code codeFromResponse: messageFromResponse',
      });
    });
  });

  describe('fetchPaymentMethodDetails', () => {
    it('fetches paymentMethodDetails and calls fetchPaymentMethodDetailsSuccess with the returned data on success and updates isLoadingPaymentMethod to false', async () => {
      mock
        .onGet(paymentMethodPath, { params: { id: 'paymentMethodId' } })
        .replyOnce(200, { token: 'x' });

      await testAction(
        actions.fetchPaymentMethodDetails,
        null,
        { paymentMethodId: 'paymentMethodId' },
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [{ type: 'fetchPaymentMethodDetailsSuccess', payload: { token: 'x' } }],
      );
    });

    it('calls fetchPaymentMethodDetailsError on error and updates isLoadingPaymentMethod to false', async () => {
      mock.onGet(paymentMethodPath).replyOnce(500);

      await testAction(
        actions.fetchPaymentMethodDetails,
        null,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [{ type: 'fetchPaymentMethodDetailsError' }],
      );
    });
  });

  describe('fetchPaymentMethodDetailsSuccess', () => {
    const creditCardDetails = {
      credit_card_type: 'cc_type',
      credit_card_mask_number: '************4242',
      credit_card_expiration_month: 12,
      credit_card_expiration_year: 2019,
    };

    it('updates creditCardDetails to the provided data and calls defaultClient with activateNextStepMutation', async () => {
      await testAction(
        actions.fetchPaymentMethodDetailsSuccess,
        creditCardDetails,
        {},
        [
          {
            type: 'UPDATE_CREDIT_CARD_DETAILS',
            payload: creditCardDetails,
          },
        ],
        [],
      );
      expect(defaultClient.mutate).toHaveBeenCalledWith({
        mutation: activateNextStepMutation,
      });
    });

    it('displays an error if activateNextStepMutation fails', async () => {
      const error = new Error('An error happened!');
      jest.spyOn(defaultClient, 'mutate').mockRejectedValue(error);
      await testAction(
        actions.fetchPaymentMethodDetailsSuccess,
        creditCardDetails,
        {},
        [
          {
            type: 'UPDATE_CREDIT_CARD_DETAILS',
            payload: creditCardDetails,
          },
        ],
        [],
      );
      expect(createFlash).toHaveBeenCalledWith({
        message: GENERAL_ERROR_MESSAGE,
        error,
        captureError: true,
      });
    });
  });

  describe('fetchPaymentMethodDetailsError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchPaymentMethodDetailsError, null, {}, [], []);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to register credit card. Please try again.',
      });
    });
  });

  describe('confirmOrder', () => {
    it('calls confirmOrderSuccess with a redirect location on success', async () => {
      const response = { location: 'x' };
      mock.onPost(confirmOrderPath).replyOnce(200, response);

      await testAction(
        actions.confirmOrder,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
        [{ type: 'confirmOrderSuccess', payload: response }],
      );
    });

    it('calls trackTransaction on success', async () => {
      const spy = jest.spyOn(googleTagManager, 'trackTransaction');
      const response = { location: 'x' };
      mock.onPost(confirmOrderPath).replyOnce(200, response);

      await testAction(
        actions.confirmOrder,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
        [{ type: 'confirmOrderSuccess', payload: response }],
      );

      expect(spy).toHaveBeenCalled();
    });

    it('calls confirmOrderError with the errors on error', async () => {
      mock.onPost(confirmOrderPath).replyOnce(200, { errors: 'errors' });

      await testAction(
        actions.confirmOrder,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
        [{ type: 'confirmOrderError', payload: '"errors"' }],
      );
    });

    it('calls confirmOrderError on failure', async () => {
      mock.onPost(confirmOrderPath).replyOnce(500);

      await testAction(
        actions.confirmOrder,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
        [{ type: 'confirmOrderError' }],
      );
    });
  });

  describe('confirmOrderSuccess', () => {
    useMockLocationHelper();

    const params = { location: 'http://example.com', plan_id: 'x', quantity: 10 };

    it('changes the window location', async () => {
      await testAction(actions.confirmOrderSuccess, params, {}, [], []);
      expect(window.location.assign).toHaveBeenCalledWith('http://example.com');
    });
  });

  describe('confirmOrderError', () => {
    it('creates a flash with a default message when no error given', async () => {
      await testAction(
        actions.confirmOrderError,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: false }],
        [],
      );
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to confirm your order! Please try again.',
      });
    });

    it('creates a flash with a the error message when an error is given', async () => {
      await testAction(
        actions.confirmOrderError,
        '"Error"',
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: false }],
        [],
      );
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to confirm your order: "Error". Please try again.',
      });
    });
  });
});
