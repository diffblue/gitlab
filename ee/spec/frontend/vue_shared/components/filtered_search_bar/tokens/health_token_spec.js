import { GlFilteredSearchTokenSegment, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import { __ } from '~/locale';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import { HEALTH_SUGGESTIONS } from 'ee/vue_shared/components/filtered_search_bar//constants';
import { mockHealthToken } from '../mock_data';

describe('HealthToken', () => {
  const healthStatus = { title: __('On track'), value: 'onTrack' };
  let wrapper;

  const createComponent = ({
    active = false,
    config = mockHealthToken,
    value = { data: '' },
  } = {}) =>
    mount(HealthToken, {
      propsData: {
        active,
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
      stubs: {
        Portal: true,
      },
    });

  it('renders health value', () => {
    wrapper = createComponent({ value: { data: healthStatus.value } });

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Health` `=` `On track`
    expect(tokenSegments.at(2).text()).toBe(healthStatus.title);
  });

  it('renders provided defaultHealthStatus as suggestions', () => {
    wrapper = createComponent({ active: true });

    const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

    expect(suggestions).toHaveLength(OPTIONS_NONE_ANY.length + HEALTH_SUGGESTIONS.length);
    OPTIONS_NONE_ANY.forEach((label, index) => {
      expect(suggestions.at(index).text()).toBe(label.title);
    });
  });
});
