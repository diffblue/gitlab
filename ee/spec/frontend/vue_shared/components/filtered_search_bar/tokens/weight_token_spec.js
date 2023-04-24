import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';
import { mockWeightToken } from '../mock_data';

jest.mock('~/alert');

describe('WeightToken', () => {
  const weight = '3';
  let wrapper;

  const createComponent = ({ config = mockWeightToken, value = { data: '' } } = {}) =>
    mount(WeightToken, {
      propsData: {
        active: false,
        config,
        value,
        cursorPosition: 'start',
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
    });

  it('renders weight value', () => {
    wrapper = createComponent({ value: { data: weight } });

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Weight` `=` `3`
    expect(tokenSegments.at(2).text()).toBe(weight);
  });
});
