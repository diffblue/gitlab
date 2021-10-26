import { GlTab } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('BaseTab', () => {
  let wrapper;

  // Finders
  const findTitle = () => wrapper.findByTestId('tab-title');
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(BaseTab, {
      propsData,
      stubs: {
        GlTab: stubComponent(GlTab, {
          template: `
            <div>
              <span data-testid="tab-title">
                <slot name="title" />
              </span>
              <slot />
            </div>
          `,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent({
      title: 'All',
      itemsCount: 12,
    });
  });

  it('renders the title with the item count', () => {
    expect(findTitle().text()).toMatchInterpolatedText('All 12');
  });

  it('renders an empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
  });
});
