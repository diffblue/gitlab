import { GlDropdown } from '@gitlab/ui';
import FeatureFlagsActions from 'ee/feature_flags/components/actions.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';

describe('ee/feature_flags/components/actions.vue', () => {
  let wrapper;

  const createWrapper = (provide = { searchPath: '/search' }) =>
    mountExtended(FeatureFlagsActions, { provide });

  it('shows a link to search for code references if provided', () => {
    wrapper = createWrapper();
    const link = wrapper.findByRole('menuitem', {
      name: s__('FeatureFlags|Search code references'),
    });

    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe('/search');
  });

  it('shows nothing if no path is provided', () => {
    wrapper = createWrapper({ searchPath: null });

    expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
  });
});
