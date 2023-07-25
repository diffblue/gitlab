import { GlCollapsibleListbox, GlBadge } from '@gitlab/ui';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const GOOD_FILTER = 'GOOD_FILTER';
const FILTERS = [{ text: 'Good filter', value: GOOD_FILTER, tooltip: 'This is a good filter' }];

describe('ScanFilterSelector', () => {
  let wrapper;

  const createComponent = (props = { filters: FILTERS }) => {
    wrapper = shallowMountExtended(ScanFilterSelector, {
      propsData: {
        ...props,
      },
      stubs: {
        GenericBaseLayoutComponent,
        GlCollapsibleListbox,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDisabledBadge = () => wrapper.findComponent(GlBadge);

  describe('default', () => {
    it('renders options', () => {
      createComponent();
      expect(findListbox().props('items')).toEqual([FILTERS[0]]);
    });

    it('can have disabled state', () => {
      createComponent({ disabled: true });
      expect(findListbox().props('disabled')).toBe(true);
    });

    it('can have custom tooltip text', () => {
      const tooltipTitle = 'Custom tooltip';
      createComponent({ tooltipTitle });
      expect(findListbox().attributes('title')).toBe(tooltipTitle);
    });

    it('can render custom filter tooltip based on callback', () => {
      const customFilterTooltip = () => 'Custom';
      createComponent({ filters: FILTERS, selected: { [GOOD_FILTER]: [] }, customFilterTooltip });
      expect(findDisabledBadge().attributes('title')).toEqual('Custom');
    });

    it('can set filter disabled on callback', () => {
      const shouldDisableFilter = () => true;
      createComponent({ filters: FILTERS, shouldDisableFilter });
      expect(findDisabledBadge().exists()).toBe(true);
    });
  });

  describe('when filter is unselected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not disable the filter', () => {
      expect(findDisabledBadge().exists()).toBe(false);
    });

    it('emits the "select" event when it has been selected', async () => {
      expect(wrapper.emitted('select')).toBeUndefined();
      await findListbox().vm.$emit('select', GOOD_FILTER);
      expect(wrapper.emitted('select')).toEqual([[GOOD_FILTER]]);
    });
  });

  describe('when filter is selected', () => {
    beforeEach(() => {
      createComponent({ filters: FILTERS, selected: { [GOOD_FILTER]: [] } });
    });

    it('disables the filter', () => {
      expect(findDisabledBadge().exists()).toBe(true);
    });

    it('does not emit the "select" even when it has been selected', async () => {
      await findListbox().vm.$emit('select', GOOD_FILTER);
      expect(wrapper.emitted('select')).toBeUndefined();
    });
  });
});
