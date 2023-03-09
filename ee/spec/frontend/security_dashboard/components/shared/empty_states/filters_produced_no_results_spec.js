import { GlEmptyState } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import FiltersProducedNoResults from 'ee/security_dashboard/components/shared/empty_states/filters_produced_no_results.vue';

describe('filters produced no results empty state', () => {
  let wrapper;
  const noVulnerabilitiesSvgPath = '/placeholder.svg';

  const createWrapper = () =>
    mount(FiltersProducedNoResults, {
      provide: {
        noVulnerabilitiesSvgPath,
      },
    });

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('contains a GlEmptyState', () => {
    expect(findGlEmptyState().exists()).toBe(true);
    expect(findGlEmptyState().props('svgPath')).toBe(noVulnerabilitiesSvgPath);
  });

  it('has the correct message', () => {
    expect(findGlEmptyState().text()).toContain(
      'To widen your search, change or remove filters above',
    );
  });

  it('has the correct title', () => {
    expect(findGlEmptyState().text()).toContain('Sorry, your filter produced no results');
  });
});
