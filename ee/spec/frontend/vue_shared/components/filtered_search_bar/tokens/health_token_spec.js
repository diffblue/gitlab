import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { __ } from '~/locale';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import { mockHealthToken } from '../mock_data';

describe('HealthToken', () => {
  const healthStatus = { title: __('On track'), value: 'onTrack' };
  let wrapper;

  const createComponent = ({ config = mockHealthToken, value = { data: '' } } = {}) =>
    mount(HealthToken, {
      propsData: {
        active: false,
        config,
        value,
        cursorPosition: 'start',
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders health value', () => {
    wrapper = createComponent({ value: { data: healthStatus.value } });

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Health` `=` `onTrack`
    expect(tokenSegments.at(2).text()).toBe(healthStatus.value);
  });
});
