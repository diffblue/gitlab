import VueApollo from 'vue-apollo';
import { createLocalVue } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import CountryOrRegionList from 'ee/trials/components/country_or_region_selector.vue';
import { formData } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('CountryOrRegionList', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    const mockResolvers = {
      Query: {
        countries() {
          return [{ id: 'US', name: 'United States' }];
        },
      },
    };

    return mountFunction(CountryOrRegionList, {
      localVue,
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
    `('has the default injected value for $testid', ({ testid, value }) => {
      expect(findFormInput(testid).attributes('value')).toBe(value);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = ['country'];

      visibleFields.forEach((f) => expect(wrapper.findByTestId(f).exists()).toBe(true));
    });
  });
});
