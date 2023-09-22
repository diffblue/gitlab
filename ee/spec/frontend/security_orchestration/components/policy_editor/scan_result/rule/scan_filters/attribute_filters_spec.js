import {
  FIX_AVAILABLE,
  FALSE_POSITIVE,
} from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/constants';
import AttributeFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/attribute_filter.vue';
import AttributeFilters from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/attribute_filters.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('AttributeFilters', () => {
  let wrapper;

  const oneFilterSelected = { [FALSE_POSITIVE]: false };
  const allFiltersSelected = {
    [FALSE_POSITIVE]: false,
    [FIX_AVAILABLE]: true,
  };
  const initialProps = {
    selected: oneFilterSelected,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(AttributeFilters, {
      propsData: {
        ...initialProps,
        ...props,
      },
    });
  };

  const findAttributeFilters = () => wrapper.findAllComponents(AttributeFilter);
  const findFirstFilter = () => findAttributeFilters().at(0);

  it.each`
    selected              | disabled | labels
    ${{}}                 | ${false} | ${[]}
    ${oneFilterSelected}  | ${false} | ${['Attribute:']}
    ${allFiltersSelected} | ${true}  | ${['Attribute:', 'and']}
  `(
    'renders filters with correct labels based on selected prop',
    ({ selected, disabled, labels }) => {
      createComponent({ selected });

      const allFilters = findAttributeFilters();

      expect(allFilters.length).toEqual(Object.keys(selected).length);

      for (let i = 0; i < allFilters.length; i += 1) {
        expect(allFilters.at(i).props('disabled')).toEqual(disabled);
        expect(allFilters.at(i).text()).toContain(labels[i]);
      }
    },
  );

  describe('emitted events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits input event on value changes', async () => {
      await findFirstFilter().vm.$emit('input', true);

      expect(wrapper.emitted('input')).toEqual([[{ [FALSE_POSITIVE]: true }]]);
    });

    it('emits input event on operator changes', async () => {
      await findFirstFilter().vm.$emit('attribute-change', FIX_AVAILABLE);

      expect(wrapper.emitted('input')).toEqual([[{ [FIX_AVAILABLE]: false }]]);
    });

    it('emits remove event', async () => {
      await findFirstFilter().vm.$emit('remove', FALSE_POSITIVE);

      expect(wrapper.emitted('remove')).toEqual([[FALSE_POSITIVE]]);
    });
  });
});
