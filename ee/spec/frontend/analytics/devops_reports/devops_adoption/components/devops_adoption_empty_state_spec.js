import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DevopsAdoptionEmptyState from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_empty_state.vue';
import {
  I18N_EMPTY_STATE_TITLE,
  I18N_EMPTY_STATE_DESCRIPTION,
} from 'ee/analytics/devops_reports/devops_adoption/constants';

const emptyStateSvgPath = 'illustrations/monitoring/getting_started.svg';

describe('DevopsAdoptionEmptyState', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const { stubs = {}, props = {} } = options;

    return shallowMount(DevopsAdoptionEmptyState, {
      provide: {
        emptyStateSvgPath,
      },
      propsData: {
        hasGroupsData: true,
        ...props,
      },
      stubs,
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  it('contains the correct svg', () => {
    wrapper = createComponent();

    expect(findEmptyState().props('svgPath')).toBe(emptyStateSvgPath);
  });

  it('contains the correct text', () => {
    wrapper = createComponent();

    const emptyState = findEmptyState();

    expect(emptyState.props('title')).toBe(I18N_EMPTY_STATE_TITLE);
    expect(emptyState.props('description')).toBe(I18N_EMPTY_STATE_DESCRIPTION);
  });
});
