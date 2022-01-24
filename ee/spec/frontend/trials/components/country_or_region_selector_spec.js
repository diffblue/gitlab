import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import CountryOrRegionSelector from 'ee/trials/components/country_or_region_selector.vue';
import { countries, states } from '../../hand_raise_leads/components/mock_data';
import { formData } from './mock_data';

Vue.use(VueApollo);

describe('CountryOrRegionSelector', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    const mockResolvers = {
      Query: {
        countries() {
          return [{ id: 'US', name: 'United States' }];
        },
        states() {
          return [{ countryId: 'US', id: 'CA', name: 'California' }];
        },
      },
    };

    return mountFunction(CountryOrRegionSelector, {
      apolloProvider: createMockApollo([], mockResolvers),
      provide: {
        user: formData,
      },
    });
  };

  const findFormInput = (testId) => wrapper.findByTestId(testId);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it.each`
      testid       | value
      ${'country'} | ${'US'}
      ${'state'}   | ${'CA'}
    `('has the default injected value for $testid', ({ testid, value }) => {
      expect(findFormInput(testid).attributes('value')).toBe(value);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = ['country', 'state'];

      visibleFields.forEach((f) => expect(wrapper.findByTestId(f).exists()).toBe(true));
    });
  });

  describe.each`
    country | display
    ${'US'} | ${true}
    ${'CA'} | ${true}
    ${'NL'} | ${false}
  `('Country & State handling', ({ country, display }) => {
    describe(`when provided country is set to ${country}`, () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it(`should${display ? '' : ' not'} render the state`, async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ countries, states, country });

        await nextTick();

        expect(findFormInput('state').exists()).toBe(display);
      });
    });
  });
});
