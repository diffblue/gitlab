import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';

import countriesQuery from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import countriesResolver from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';

import InternationalPhoneInput from 'ee/users/identity_verification/components/international_phone_input.vue';

import {
  PHONE_NUMBER_LABEL,
  COUNTRY_LABEL,
  PHONE_NUMBER_LENGTH_ERROR,
  PHONE_NUMBER_NAN_ERROR,
  PHONE_NUMBER_BLANK_ERROR,
} from 'ee/users/identity_verification/constants';

import { COUNTRIES, mockCountry1, mockCountry2 } from '../mock_data';

Vue.use(VueApollo);

describe('International Phone input component', () => {
  let wrapper;

  const findCountryFormGroup = () => wrapper.findByTestId('country-form-group');
  const findCountrySelect = () => wrapper.findByTestId('country-form-select');

  const findPhoneNumberFormGroup = () => wrapper.findByTestId('phone-number-form-group');
  const findPhoneNumberInput = () => wrapper.findByTestId('phone-number-form-input');

  const expectedCountryText = (country) =>
    `${country.flag} ${country.name} +${country.internationalDialCode}`;
  const expectedCountryValue = (country) => `${country.id}+${country.internationalDialCode}`;

  const createMockApolloProvider = () => {
    const mockResolvers = { countriesResolver };
    const mockApollo = createMockApollo([], mockResolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: countriesQuery,
      data: { countries: COUNTRIES },
    });
    return mockApollo;
  };

  const createComponent = ({ props } = { props: {} }) => {
    wrapper = shallowMountExtended(InternationalPhoneInput, {
      apolloProvider: createMockApolloProvider(),
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Country select field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label', () => {
      expect(findCountryFormGroup().attributes('label')).toBe(COUNTRY_LABEL);
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
  });

  describe('Phone number input field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label', () => {
      expect(findPhoneNumberFormGroup().attributes('label')).toBe(PHONE_NUMBER_LABEL);
    });

    it('should be of type tel', () => {
      expect(findPhoneNumberInput().attributes('type')).toBe('tel');
    });

    it.each`
      value              | valid    | errorMessage
      ${'1800134678'}    | ${true}  | ${''}
      ${'123456789012'}  | ${true}  | ${''}
      ${'1234567890123'} | ${false} | ${PHONE_NUMBER_LENGTH_ERROR}
      ${'1300-123-123'}  | ${false} | ${PHONE_NUMBER_NAN_ERROR}
      ${'abc'}           | ${false} | ${PHONE_NUMBER_NAN_ERROR}
      ${''}              | ${false} | ${PHONE_NUMBER_BLANK_ERROR}
    `(
      'when the input has a value of $value, then its validity should be $valid',
      async ({ value, valid, errorMessage }) => {
        findPhoneNumberInput().vm.$emit('input', value);
        findPhoneNumberInput().vm.$emit('blur');

        await nextTick();

        const expectedState = valid ? 'true' : undefined;

        expect(findPhoneNumberFormGroup().attributes('invalid-feedback')).toBe(errorMessage);
        expect(findPhoneNumberFormGroup().attributes('state')).toBe(expectedState);

        expect(findPhoneNumberInput().attributes('state')).toBe(expectedState);
      },
    );
  });
});
