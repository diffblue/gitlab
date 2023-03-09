import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import CountryOrRegionSelector from 'ee/trials/components/country_or_region_selector.vue';
import {
  COUNTRIES,
  STATES,
  COUNTRY_WITH_STATES,
  STATE,
} from 'ee_jest/hand_raise_leads/components/mock_data';

Vue.use(VueApollo);

describe('CountryOrRegionSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    const mockResolvers = {
      Query: {
        countries() {
          return COUNTRIES;
        },
        states() {
          return STATES;
        },
      },
    };

    return shallowMountExtended(CountryOrRegionSelector, {
      apolloProvider: createMockApollo([], mockResolvers),
      propsData: {
        country: COUNTRY_WITH_STATES,
        state: STATE,
        ...props,
      },
    });
  };

  const findFormInput = (testId) => wrapper.findByTestId(testId);

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
  });

  describe.each`
    country | display
    ${'US'} | ${true}
    ${'CA'} | ${true}
    ${'NL'} | ${false}
  `('Country & State handling', ({ country, display }) => {
    describe(`when provided country is set to ${country}`, () => {
      beforeEach(() => {
        wrapper = createComponent({ country });
      });

      it(`should${display ? '' : ' not'} render the state`, async () => {
        await nextTick();

        expect(findFormInput('state').exists()).toBe(display);
      });
    });
  });

  describe('selection change', () => {
    it('emits the change event properly when country is changed', async () => {
      wrapper = createComponent();

      await findFormInput('country').vm.$emit('change', true);

      expect(wrapper.emitted('change')[0]).toStrictEqual([
        { country: 'US', state: 'CA', stateRequired: true },
      ]);
    });

    it('emits the change event properly when country is changed with no state required', async () => {
      wrapper = createComponent({ country: 'NL' });

      await findFormInput('country').vm.$emit('change', true);

      expect(wrapper.emitted('change')[0]).toStrictEqual([
        { country: 'NL', state: '', stateRequired: false },
      ]);
    });

    it('emits the change event properly when country is changed with state required', async () => {
      wrapper = createComponent({ country: 'US', state: '' });

      await findFormInput('country').vm.$emit('change', true);

      expect(wrapper.emitted('change')[0]).toStrictEqual([
        { country: 'US', state: '', stateRequired: true },
      ]);
    });

    it('emits the change event properly when state is not required but has value', async () => {
      wrapper = createComponent({ country: 'NL', state: 'CA' });

      await findFormInput('country').vm.$emit('change', true);

      expect(wrapper.emitted('change')[0]).toStrictEqual([
        { country: 'NL', state: '', stateRequired: false },
      ]);
    });

    it('emits the change event properly when state is changed', async () => {
      wrapper = createComponent();

      await findFormInput('state').vm.$emit('change', true);

      expect(wrapper.emitted('change')[0]).toStrictEqual([
        { country: 'US', state: 'CA', stateRequired: true },
      ]);
    });
  });
});
