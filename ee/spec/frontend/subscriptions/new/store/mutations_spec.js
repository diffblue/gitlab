import * as types from 'ee/subscriptions/new/store/mutation_types';
import mutations from 'ee/subscriptions/new/store/mutations';

const state = () => ({
  selectedPlan: 'firstPlan',
  isSetupForCompany: true,
  numberOfUsers: 1,
  organizationName: 'name',
  countryOptions: [],
  stateOptions: [],
  isLoadingPaymentMethod: false,
  isConfirmingOrder: false,
});

let stateCopy;

beforeEach(() => {
  stateCopy = state();
});

describe('ee/subscriptions/new/store/mutation', () => {
  describe.each`
    mutation                                  | value                                 | stateProp
    ${types.UPDATE_SELECTED_PLAN}             | ${'secondPlan'}                       | ${'selectedPlan'}
    ${types.UPDATE_SELECTED_GROUP}            | ${'selectedGroup'}                    | ${'selectedGroup'}
    ${types.UPDATE_IS_SETUP_FOR_COMPANY}      | ${false}                              | ${'isSetupForCompany'}
    ${types.UPDATE_NUMBER_OF_USERS}           | ${2}                                  | ${'numberOfUsers'}
    ${types.UPDATE_ORGANIZATION_NAME}         | ${'new name'}                         | ${'organizationName'}
    ${types.UPDATE_COUNTRY_OPTIONS}           | ${[{ text: 'country', value: 'id' }]} | ${'countryOptions'}
    ${types.UPDATE_STATE_OPTIONS}             | ${[{ text: 'state', value: 'id' }]}   | ${'stateOptions'}
    ${types.UPDATE_COUNTRY}                   | ${'NL'}                               | ${'country'}
    ${types.UPDATE_STREET_ADDRESS_LINE_ONE}   | ${'streetAddressLine1'}               | ${'streetAddressLine1'}
    ${types.UPDATE_STREET_ADDRESS_LINE_TWO}   | ${'streetAddressLine2'}               | ${'streetAddressLine2'}
    ${types.UPDATE_CITY}                      | ${'city'}                             | ${'city'}
    ${types.UPDATE_COUNTRY_STATE}             | ${'countryState'}                     | ${'countryState'}
    ${types.UPDATE_ZIP_CODE}                  | ${'zipCode'}                          | ${'zipCode'}
    ${types.UPDATE_PAYMENT_FORM_PARAMS}       | ${{ token: 'x' }}                     | ${'paymentFormParams'}
    ${types.UPDATE_PAYMENT_METHOD_ID}         | ${'paymentMethodId'}                  | ${'paymentMethodId'}
    ${types.UPDATE_CREDIT_CARD_DETAILS}       | ${{ type: 'x' }}                      | ${'creditCardDetails'}
    ${types.UPDATE_IS_LOADING_PAYMENT_METHOD} | ${true}                               | ${'isLoadingPaymentMethod'}
    ${types.UPDATE_IS_CONFIRMING_ORDER}       | ${true}                               | ${'isConfirmingOrder'}
  `('$mutation', ({ mutation, value, stateProp }) => {
    it(`should set the ${stateProp} to the given value`, () => {
      expect(stateCopy[stateProp]).not.toEqual(value);

      mutations[mutation](stateCopy, value);

      expect(stateCopy[stateProp]).toEqual(value);
    });
  });
});
