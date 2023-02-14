import * as constants from 'ee/subscriptions/new/constants';
import * as getters from 'ee/subscriptions/new/store/getters';
import { mockChargeItem, mockInvoicePreviewBronze } from 'ee_jest/subscriptions/mock_data';

const state = {
  isSetupForCompany: true,
  isNewUser: true,
  availablePlans: [
    {
      value: 'firstPlan',
      text: 'first plan',
    },
  ],
  selectedPlan: 'firstPlan',
  country: 'Country',
  streetAddressLine1: 'Street address line 1',
  streetAddressLine2: 'Street address line 2',
  city: 'City',
  countryState: 'State',
  zipCode: 'Zip code',
  organizationName: 'Organization name',
  paymentMethodId: 'Payment method ID',
  numberOfUsers: 1,
  source: 'some_source',
};

describe('Subscriptions Getters', () => {
  describe('selectedPlanText', () => {
    it('returns the text for selectedPlan', () => {
      expect(
        getters.selectedPlanText(state, { selectedPlanDetails: { text: 'selected plan' } }),
      ).toBe('selected plan');
    });
  });

  describe('selectedPlanDetails', () => {
    it('returns the details for the selected plan', () => {
      expect(getters.selectedPlanDetails(state)).toEqual({
        value: 'firstPlan',
        text: 'first plan',
      });
    });
  });

  describe('isUltimatePlan', () => {
    it('returns true if plan code is ultimate', () => {
      expect(getters.isUltimatePlan(state, { selectedPlanDetails: { code: 'ultimate' } })).toBe(
        true,
      );
    });

    it('returns false if plan code is not ultimate', () => {
      expect(getters.isUltimatePlan(state, { selectedPlanDetails: { code: 'not-ultimate' } })).toBe(
        false,
      );
    });
  });

  describe('endDate', () => {
    it('returns a date 1 year after the startDate', () => {
      expect(getters.endDate({ startDate: new Date('2020-01-07') })).toBe(
        new Date('2021-01-07').getTime(),
      );
    });
  });

  describe('totalExVat', () => {
    it('returns the total value excluding vat', () => {
      expect(
        getters.totalExVat(
          { numberOfUsers: 5 },
          { chargeItem: mockChargeItem, hideAmount: false, selectedPlanPrice: 10 },
        ),
      ).toBe(48);
    });

    it('returns 0 if hideAmount is true', () => {
      expect(
        getters.totalExVat(
          { numberOfUsers: 5 },
          { chargeItem: mockChargeItem, hideAmount: true, selectedPlanPrice: 10 },
        ),
      ).toBe(0);
    });

    it(`returns 0 if charge item doesn't exist`, () => {
      expect(
        getters.totalExVat({ numberOfUsers: 5 }, { hideAmount: false, selectedPlanPrice: 10 }),
      ).toBe(0);
    });
  });

  describe('vat', () => {
    it('returns the tax rate times the total ex vat', () => {
      expect(getters.vat({ taxRate: 0.08 }, { totalExVat: 100 })).toBe(8);
    });
  });

  describe('totalAmount', () => {
    it('returns the total ex vat plus the vat', () => {
      expect(
        getters.totalAmount(
          { invoicePreview: mockInvoicePreviewBronze.data.invoicePreview },
          { hideAmount: false, vat: 8 },
        ),
      ).toBe(56);
    });

    it('returns 0 if hideAmount is true', () => {
      expect(
        getters.totalExVat(
          { invoicePreview: mockInvoicePreviewBronze.data.invoicePreview },
          { hideAmount: false, vat: 8 },
        ),
      ).toBe(0);
    });
  });

  describe('hideAmount', () => {
    it('returns true if no users are present', () => {
      expect(getters.hideAmount({}, { usersPresent: false })).toBe(true);
    });

    it('returns false if users are present and not using invoice preview api', () => {
      gon.features = { useInvoicePreviewApiInSaasPurchase: false };

      expect(getters.hideAmount({}, { usersPresent: true })).toBe(false);
    });

    it('returns true if users are present when using invoice preview api and when loading', () => {
      gon.features = { useInvoicePreviewApiInSaasPurchase: true };

      expect(getters.hideAmount({ isInvoicePreviewLoading: true }, { usersPresent: true })).toBe(
        true,
      );
    });

    it('returns true if users are present when using invoice preview api and invoice preview is not valid', () => {
      gon.features = { useInvoicePreviewApiInSaasPurchase: true };

      expect(getters.hideAmount({}, { usersPresent: true, hasValidPriceDetails: false })).toBe(
        true,
      );
    });

    it('returns false if users are present when using invoice preview api and invoice preview is valid', () => {
      gon.features = { useInvoicePreviewApiInSaasPurchase: true };

      expect(getters.hideAmount({}, { usersPresent: true, hasValidPriceDetails: true })).toBe(
        false,
      );
    });
  });

  describe('hasValidPriceDetails', () => {
    it('returns true if invoice preview data exists', () => {
      expect(
        getters.hasValidPriceDetails({
          invoicePreview: mockInvoicePreviewBronze.data.invoicePreview,
        }),
      ).toBe(true);
    });

    it(`returns false if invoice preview data doesn't exist`, () => {
      expect(getters.hasValidPriceDetails({ invoicePreview: null })).toBe(false);
    });
  });

  describe('chargeItem', () => {
    it('returns charge item when present', () => {
      const invoicePreview = { invoiceItem: [mockChargeItem] };
      expect(getters.chargeItem({ invoicePreview })).toBe(mockChargeItem);
    });

    it(`returns false if invoice preview data doesn't exist`, () => {
      expect(getters.chargeItem({ invoicePreview: null })).toBe(undefined);
    });
  });

  describe('name', () => {
    it('returns the organization name when setting up for a company and when it is present', () => {
      expect(
        getters.name({ isSetupForCompany: true, organizationName: 'My organization' }, getters),
      ).toBe('My organization');
    });

    it('returns the organization name when a group is selected but does not exist', () => {
      expect(
        getters.name(
          { isSetupForCompany: true },
          {
            isGroupSelected: true,
            isSelectedGroupPresent: false,
            selectedGroupName: 'Selected group',
          },
        ),
      ).toBe('Your organization');
    });

    it('returns the selected group name a group is selected', () => {
      expect(
        getters.name(
          { isSetupForCompany: true },
          {
            isGroupSelected: true,
            isSelectedGroupPresent: true,
            selectedGroupName: 'Selected group',
          },
        ),
      ).toBe('Selected group');
    });

    it('returns the default text when setting up for a company and the organization name is not present', () => {
      expect(getters.name({ isSetupForCompany: true }, { isGroupSelected: false })).toBe(
        'Your organization',
      );
    });

    it('returns the full name when not setting up for a company', () => {
      expect(
        getters.name({ isSetupForCompany: false, fullName: 'My name' }, { isGroupSelected: false }),
      ).toBe('My name');
    });
  });

  describe('usersPresent', () => {
    it('returns true when the number of users is greater than zero', () => {
      expect(getters.usersPresent({ numberOfUsers: 1 })).toBe(true);
    });

    it('returns false when the number of users is zero', () => {
      expect(getters.usersPresent({ numberOfUsers: 0 })).toBe(false);
    });
  });

  describe('isGroupSelected', () => {
    it('returns true when the selectedGroup is not null and does not equal "true"', () => {
      expect(getters.isGroupSelected({ selectedGroup: 1 })).toBe(true);
    });

    it('returns false when the selectedGroup is null', () => {
      expect(getters.isGroupSelected({ selectedGroup: null })).toBe(false);
    });

    it('returns false when the selectedGroup equals "new"', () => {
      expect(getters.isGroupSelected({ selectedGroup: constants.NEW_GROUP })).toBe(false);
    });
  });

  describe('isSelectedGroupPresent', () => {
    it('returns true when known group is selected', () => {
      expect(getters.isSelectedGroupPresent({}, { selectedGroupData: {} })).toBe(true);
    });

    it('returns false when no group is selected', () => {
      expect(getters.isSelectedGroupPresent({}, { selectedGroupData: undefined })).toBe(false);
    });
  });

  describe('selectedGroupData', () => {
    it('returns null when no group is selected', () => {
      expect(
        getters.selectedGroupData(
          {
            groupData: [
              { text: 'Not selected group', value: 'not-selected-group' },
              { text: 'Selected group', value: 'selected-group' },
            ],
          },
          { isGroupSelected: false },
        ),
      ).toBe(null);
    });

    it('returns the selected group when a group is selected', () => {
      expect(
        getters.selectedGroupData(
          {
            selectedGroup: 'selected-group',
            groupData: [
              { text: 'Not selected group', value: 'not-selected-group' },
              { text: 'Selected group', value: 'selected-group' },
            ],
          },
          { isGroupSelected: true },
        ),
      ).toEqual({ text: 'Selected group', value: 'selected-group' });
    });
  });

  describe('selectedGroupName', () => {
    it('returns null when no group is selected', () => {
      expect(getters.selectedGroupName({}, { selectedGroupData: undefined })).toBe(undefined);
    });

    it('returns the text attribute of the selected group when a group is selected', () => {
      expect(getters.selectedGroupName({}, { selectedGroupData: { text: 'Selected group' } })).toBe(
        'Selected group',
      );
    });
  });

  describe('selectedGroupId', () => {
    it('returns null when no group is selected', () => {
      expect(getters.selectedGroupId({ selectedGroup: 123 }, { isGroupSelected: false })).toBe(
        null,
      );
    });

    it('returns the id of the selected group when a group is selected', () => {
      expect(getters.selectedGroupId({ selectedGroup: 123 }, { isGroupSelected: true })).toBe(123);
    });
  });

  describe('confirmOrderParams', () => {
    it('returns the params to confirm the order', () => {
      expect(getters.confirmOrderParams(state, { selectedGroupId: 11 })).toEqual({
        setup_for_company: true,
        selected_group: 11,
        new_user: true,
        customer: {
          country: 'Country',
          address_1: 'Street address line 1',
          address_2: 'Street address line 2',
          city: 'City',
          state: 'State',
          zip_code: 'Zip code',
          company: 'Organization name',
        },
        subscription: {
          plan_id: 'firstPlan',
          payment_method_id: 'Payment method ID',
          quantity: 1,
          source: 'some_source',
        },
      });
    });
  });

  describe('isEligibleToUsePromoCode', () => {
    it('returns true if plan is eligible to use promo code', () => {
      expect(
        getters.isEligibleToUsePromoCode(state, {
          selectedPlanDetails: { isEligibleToUsePromoCode: true },
        }),
      ).toBe(true);
    });

    it('returns false if plan is eligible to use promo code', () => {
      expect(
        getters.isEligibleToUsePromoCode(state, {
          selectedPlanDetails: { isEligibleToUsePromoCode: false },
        }),
      ).toBe(false);
    });
  });
});
