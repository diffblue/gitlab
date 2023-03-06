import Api from 'ee/api';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { gitLabResolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { ERROR_FETCHING_COUNTRIES, ERROR_FETCHING_STATES } from 'ee/subscriptions/constants';
import { createAlert } from '~/alert';

jest.mock('ee/api/subscriptions_api', () => {
  return {
    createSubscription: jest.fn(),
  };
});

jest.mock('~/alert');

jest.mock('ee/api', () => {
  return {
    fetchCountries: jest.fn(),
    fetchStates: jest.fn(),
  };
});

const customer = {
  country: 'NL',
  address_1: 'Address line 1',
  address_2: 'Address line 2',
  city: 'City',
  state: 'State',
  zip_code: 'Zip code',
  company: 'My organization',
};

const subscription = {
  plan_id: 'abc',
  payment_method_id: 'payment_method_id',
  products: {
    main: {
      quantity: 1,
    },
  },
  gl_namespace_id: 1,
  gl_namespace_name: 'test',
  preview: 'false',
};

const countries = [
  ['United States of America', 'US', 'US', '1'],
  ['Uruguay', 'UY', 'UY', '598'],
];

const states = { California: 'CA' };

describe('~/subscriptions/buy_addons_shared/graphql/resolvers', () => {
  describe('Query', () => {
    describe('countries', () => {
      describe('on success', () => {
        beforeEach(() => {
          Api.fetchCountries.mockResolvedValue({ data: countries });
        });

        it('returns an array of countries with typename', async () => {
          const result = await gitLabResolvers.Query.countries();

          expect(createAlert).not.toHaveBeenCalled();
          expect(result).toStrictEqual([
            {
              name: 'United States of America',
              id: 'US',
              flag: 'US',
              internationalDialCode: '1',
              __typename: 'Country',
            },
            {
              name: 'Uruguay',
              id: 'UY',
              flag: 'UY',
              internationalDialCode: '598',
              __typename: 'Country',
            },
          ]);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          Api.fetchCountries.mockRejectedValue();
        });

        it('shows an alert message', async () => {
          await gitLabResolvers.Query.countries();

          expect(createAlert).toHaveBeenCalledWith({ message: ERROR_FETCHING_COUNTRIES });
        });
      });
    });

    describe('states', () => {
      describe('on success', () => {
        beforeEach(() => {
          Api.fetchStates.mockResolvedValue({ data: states });
        });

        it('returns an array of states with typename', async () => {
          const result = await gitLabResolvers.Query.states(null, { countryId: 1 });

          expect(createAlert).not.toHaveBeenCalled();
          expect(result).toStrictEqual([{ id: 'CA', name: 'California', __typename: 'State' }]);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          Api.fetchStates.mockRejectedValue();
        });

        it('shows an alert message', async () => {
          await gitLabResolvers.Query.states(null, { countryId: 1 });

          expect(createAlert).toHaveBeenCalledWith({ message: ERROR_FETCHING_STATES });
        });
      });
    });
  });

  describe('Mutation', () => {
    it('calls the REST api', async () => {
      const expectedArgs = { groupId: 1, customer, subscription };

      await gitLabResolvers.Mutation.purchaseMinutes(null, expectedArgs);

      expect(SubscriptionsApi.createSubscription).toHaveBeenCalledWith(1, customer, subscription);
    });

    describe('on error', () => {
      beforeAll(() => {
        SubscriptionsApi.createSubscription.mockResolvedValue({ errors: [1] });
      });

      it('returns an error array', async () => {
        const result = await gitLabResolvers.Mutation.purchaseMinutes(null, {
          groupId: 1,
          customer,
          subscription,
        });

        expect(result).toEqual({ errors: [1] });
      });
    });

    describe('on success', () => {
      beforeAll(() => {
        SubscriptionsApi.createSubscription.mockResolvedValue({ data: '/foo' });
      });

      it('returns a redirect location', async () => {
        const result = await gitLabResolvers.Mutation.purchaseMinutes(null, {
          groupId: 1,
          customer,
          subscription,
        });

        expect(result).toEqual({ data: '/foo' });
      });
    });
  });
});
