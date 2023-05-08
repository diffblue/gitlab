import * as constants from 'ee/subscriptions/new/constants';
import createState from 'ee/subscriptions/new/store/state';

constants.TAX_RATE = 0;

describe('projectsSelector default state', () => {
  const availablePlans = [
    {
      id: 'firstPlanId',
      code: 'bronze',
      price_per_year: 48,
      name: 'Bronze Plan',
      eligible_to_use_promo_code: false,
    },
    {
      id: 'secondPlanId',
      code: 'premium',
      price_per_year: 228,
      name: 'Premium Plan',
      eligible_to_use_promo_code: true,
    },
    {
      id: 'thirdPlanId',
      code: 'ultimate',
      price_per_year: 350,
      name: 'Ultimate Plan',
      eligible_to_use_promo_code: false,
    },
  ];

  const groupData = [
    { id: 132, name: 'My first group', full_path: 'my-first-group' },
    { id: 483, name: 'My second group', full_path: 'my-second-group' },
  ];

  const initialData = {
    availablePlans: JSON.stringify(availablePlans),
    groupData: JSON.stringify(groupData),
    planId: 'secondPlanId',
    namespaceId: null,
    setupForCompany: 'true',
    fullName: 'Full Name',
    newUser: 'true',
    source: 'some_source',
    isTrial: false,
    newTrialRegistrationPath: 'newTrialRegistrationPath',
  };

  const currentDate = new Date('2020-01-07T12:44:08.135Z');

  jest.spyOn(global.Date, 'now').mockImplementationOnce(() => currentDate.valueOf());

  const state = createState(initialData);

  describe('availablePlans', () => {
    it('sets the availablePlans to the provided parsed availablePlans', () => {
      expect(state.availablePlans).toEqual([
        {
          value: 'firstPlanId',
          text: 'Bronze Plan',
          code: 'bronze',
          isEligibleToUsePromoCode: false,
        },
        {
          value: 'secondPlanId',
          text: 'Premium Plan',
          code: 'premium',
          isEligibleToUsePromoCode: true,
        },
        {
          value: 'thirdPlanId',
          text: 'Ultimate Plan',
          code: 'ultimate',
          isEligibleToUsePromoCode: false,
        },
      ]);
    });

    it('sets the availablePlans to an empty array when no availablePlans provided', () => {
      const modifiedState = createState({ ...initialData, ...{ availablePlans: undefined } });

      expect(modifiedState.availablePlans).toEqual([]);
    });
  });

  describe('selectedPlan', () => {
    it('sets the selectedPlan to the provided planId if it is present in the provided availablePlans', () => {
      expect(state.selectedPlan).toEqual('secondPlanId');
    });

    it('sets the selectedPlan to the first value of availablePlans if planId is not provided', () => {
      const modifiedState = createState({ ...initialData, ...{ planId: undefined } });

      expect(modifiedState.selectedPlan).toEqual('firstPlanId');
    });

    it('sets the selectedPlan to the first value of availablePlans if planId is not present in the availablePlans', () => {
      const modifiedState = createState({ ...initialData, ...{ planId: 'invalidPlanId' } });

      expect(modifiedState.selectedPlan).toEqual('firstPlanId');
    });

    it('sets the selectedPlan to an empty string if availablePlans are not present', () => {
      const modifiedState = createState({ ...initialData, ...{ availablePlans: '[]' } });

      expect(modifiedState.selectedPlan).toBeUndefined();
    });
  });

  describe.each`
    setupForCompanyValue | newUserValue | expectedValue
    ${''}                | ${'true'}    | ${false}
    ${''}                | ${'false'}   | ${true}
    ${'false'}           | ${'true'}    | ${false}
    ${'false'}           | ${'false'}   | ${false}
    ${'true'}            | ${'true'}    | ${true}
    ${'true'}            | ${'false'}   | ${true}
  `('isSetupForCompany', ({ setupForCompanyValue, newUserValue, expectedValue }) => {
    it(`sets the isSetupForCompany to ${expectedValue} if provided setupForCompany is "${setupForCompanyValue}" and newUser is "${newUserValue}"`, () => {
      const modifiedState = createState({
        ...initialData,
        ...{ setupForCompany: setupForCompanyValue, newUser: newUserValue },
      });

      expect(modifiedState.isSetupForCompany).toEqual(expectedValue);
    });
  });

  it('sets the fullName to the provided fullName', () => {
    expect(state.fullName).toEqual('Full Name');
  });

  describe('groupData', () => {
    it('sets the groupData to the provided parsed groupData', () => {
      expect(state.groupData).toEqual([
        { value: 132, text: 'My first group', fullPath: 'my-first-group' },
        { value: 483, text: 'My second group', fullPath: 'my-second-group' },
      ]);
    });

    it('sets the availablePlans to an empty array when no groupData is provided', () => {
      const modifiedState = createState({ ...initialData, ...{ groupData: undefined } });

      expect(modifiedState.groupData).toEqual([]);
    });
  });

  it('sets the selectedGroup to null', () => {
    expect(state.selectedGroup).toBeNull();
  });

  it('sets the organizationName to null', () => {
    expect(state.organizationName).toBeNull();
  });

  it('sets the promoCode to null', () => {
    expect(state.promoCode).toBeNull();
  });

  it('sets the numberOfUsers to 1', () => {
    expect(state.numberOfUsers).toEqual(1);
  });

  it('sets the country to null', () => {
    expect(state.country).toBeNull();
  });

  it('sets the streetAddressLine1 to null', () => {
    expect(state.streetAddressLine1).toBeNull();
  });

  it('sets the streetAddressLine2 to null', () => {
    expect(state.streetAddressLine2).toBeNull();
  });

  it('sets the city to null', () => {
    expect(state.city).toBeNull();
  });

  it('sets the countryState to null', () => {
    expect(state.countryState).toBeNull();
  });

  it('sets the zipCode to null', () => {
    expect(state.zipCode).toBeNull();
  });

  it('sets the isInvoicePreviewLoading to false', () => {
    expect(state.isInvoicePreviewLoading).toBe(false);
  });

  it('sets the invoicePreview to null', () => {
    expect(state.invoicePreview).toBe(null);
  });

  it('sets the countryOptions to an empty array', () => {
    expect(state.countryOptions).toEqual([]);
  });

  it('sets the stateOptions to an empty array', () => {
    expect(state.stateOptions).toEqual([]);
  });

  it('sets the taxRate to the TAX_RATE constant', () => {
    expect(state.taxRate).toEqual(0);
  });

  it('sets the startDate to the current date', () => {
    expect(state.startDate).toEqual(currentDate);
  });

  it('sets the source to the initial value', () => {
    expect(state.source).toEqual('some_source');
  });

  it('sets the paymentFormParams to an empty object', () => {
    expect(state.paymentFormParams).toEqual({});
  });

  it('sets the paymentMethodId to null', () => {
    expect(state.paymentMethodId).toBeNull();
  });

  it('sets the creditCardDetails to an empty object', () => {
    expect(state.creditCardDetails).toEqual({});
  });

  it('sets isLoadingPaymentMethod to false', () => {
    expect(state.isLoadingPaymentMethod).toEqual(false);
  });

  it('sets isConfirmingOrder to false', () => {
    expect(state.isConfirmingOrder).toBe(false);
  });

  it('sets trial to the initial value', () => {
    expect(state.isTrial).toBe(false);
  });

  it('sets newTrialRegistrationPath to the initial value', () => {
    expect(state.newTrialRegistrationPath).toBe('newTrialRegistrationPath');
  });
});
