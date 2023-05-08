import { GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import countriesResolver from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';

import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';

import {
  I18N_PHONE_NUMBER_LENGTH_ERROR,
  I18N_PHONE_NUMBER_NAN_ERROR,
  I18N_PHONE_NUMBER_BLANK_ERROR,
} from 'ee/users/identity_verification/constants';

import { COUNTRIES, mockCountry1, mockCountry2 } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('International Phone input component', () => {
  let wrapper;
  let axiosMock;

  const SEND_CODE_PATH = '/users/identity_verification/send_phone_verification_code';

  const findForm = () => wrapper.findComponent(GlForm);

  const findCountryFormGroup = () => wrapper.findByTestId('country-form-group');
  const findCountrySelect = () => wrapper.findByTestId('country-form-select');

  const findPhoneNumberFormGroup = () => wrapper.findByTestId('phone-number-form-group');
  const findPhoneNumberInput = () => wrapper.findByTestId('phone-number-form-input');

  const expectedCountryText = (country) =>
    `${country.flag} ${country.name} +${country.internationalDialCode}`;
  const expectedCountryValue = (country) => `${country.id}+${country.internationalDialCode}`;

  const enterPhoneNumber = (value) => findPhoneNumberInput().vm.$emit('input', value);
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: jest.fn() });

  const createMockApolloProvider = () => {
    const mockResolvers = { countriesResolver };
    const mockApollo = createMockApollo([], mockResolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: countriesQuery,
      data: { countries: COUNTRIES },
    });
    return mockApollo;
  };

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(InternationalPhoneInput, {
      apolloProvider: createMockApolloProvider(),
      provide: {
        phoneNumber: {
          sendCodePath: SEND_CODE_PATH,
          ...provide,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    createAlert.mockClear();
  });

  describe('Country select field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label', () => {
      expect(findCountryFormGroup().attributes('label')).toBe(wrapper.vm.$options.i18n.dialCode);
    });

    it('should filter out options without international dial code', () => {
      expect(COUNTRIES).toHaveLength(3);

      const options = findCountrySelect().findAll('option');

      expect(options).toHaveLength(2);
      expect(options.at(0).text()).toBe(expectedCountryText(mockCountry1));
      expect(options.at(1).text()).toBe(expectedCountryText(mockCountry2));
    });

    it('should have default set to US', () => {
      expect(findCountrySelect().attributes('value')).toBe(expectedCountryValue(mockCountry1));
    });

    it('should emit the change event when a new option is selected', async () => {
      await findCountrySelect().findAll('option').at(1).setSelected();
      await nextTick();

      expect(findCountrySelect().find('option:checked').element.value).toBe(
        expectedCountryValue(mockCountry2),
      );
    });

    it('should render injected value', () => {
      createComponent({ country: 'AU', internationalDialCode: '61' });
      expect(findCountrySelect().attributes('value')).toBe(expectedCountryValue(mockCountry2));
    });
  });

  describe('Phone number input field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label', () => {
      expect(findPhoneNumberFormGroup().attributes('label')).toBe(
        wrapper.vm.$options.i18n.phoneNumber,
      );
    });

    it('should be of type tel', () => {
      expect(findPhoneNumberInput().attributes('type')).toBe('tel');
    });

    it.each`
      value              | valid    | errorMessage
      ${'1800134678'}    | ${true}  | ${''}
      ${'123456789012'}  | ${true}  | ${''}
      ${'1234567890123'} | ${false} | ${I18N_PHONE_NUMBER_LENGTH_ERROR}
      ${'1300-123-123'}  | ${false} | ${I18N_PHONE_NUMBER_NAN_ERROR}
      ${'abc'}           | ${false} | ${I18N_PHONE_NUMBER_NAN_ERROR}
      ${''}              | ${false} | ${I18N_PHONE_NUMBER_BLANK_ERROR}
    `(
      'when the input has a value of $value, then its validity should be $valid',
      async ({ value, valid, errorMessage }) => {
        enterPhoneNumber(value);

        await nextTick();

        const expectedState = valid ? 'true' : undefined;

        expect(findPhoneNumberFormGroup().attributes('invalid-feedback')).toBe(errorMessage);
        expect(findPhoneNumberFormGroup().attributes('state')).toBe(expectedState);

        expect(findPhoneNumberInput().attributes('state')).toBe(expectedState);
      },
    );

    it('should render injected value', () => {
      const number = '555';
      createComponent({ number });
      expect(findPhoneNumberInput().attributes('value')).toBe(number);
    });
  });

  describe('Sending verification code', () => {
    describe('when request is successful', () => {
      beforeEach(() => {
        axiosMock.onPost(SEND_CODE_PATH).reply(HTTP_STATUS_OK, { success: true });

        enterPhoneNumber('555');
        submitForm();
        return waitForPromises();
      });

      it('emits next event with user entered phone number', () => {
        expect(wrapper.emitted('next')).toHaveLength(1);
        expect(wrapper.emitted('next')[0]).toEqual([
          {
            country: 'US',
            internationalDialCode: '1',
            number: '555',
          },
        ]);
      });
    });

    describe('when request is unsuccessful', () => {
      const errorMessage = 'Invalid phone number';
      const reason = 'bad_request';

      beforeEach(() => {
        axiosMock
          .onPost(SEND_CODE_PATH)
          .reply(HTTP_STATUS_BAD_REQUEST, { message: errorMessage, reason });

        enterPhoneNumber('555');
        submitForm();
        return waitForPromises();
      });

      it('renders error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: errorMessage,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });

    describe('when TeleSign is down', () => {
      const errorMessage = 'Something went wrong';
      const reason = 'unknown_telesign_error';

      beforeEach(() => {
        axiosMock
          .onPost(SEND_CODE_PATH)
          .reply(HTTP_STATUS_BAD_REQUEST, { message: errorMessage, reason });

        enterPhoneNumber('555');
        submitForm();
        return waitForPromises();
      });

      it('emits the skip-verification event', () => {
        expect(wrapper.emitted('skip-verification')).toHaveLength(1);
      });
    });
  });
});
