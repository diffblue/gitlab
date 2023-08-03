import { shallowMount } from '@vue/test-utils';
import { GlToggle, GlTooltip } from '@gitlab/ui';
import CodeSuggestionsAddonAssignment from 'ee/usage_quotas/seats/components/code_suggestions_addon_assignment.vue';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/seats/constants';

describe('CodeSuggestionsAddonAssignment', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CodeSuggestionsAddonAssignment, {
      propsData: {
        userId: 1,
        addOns: {},
        ...props,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const codeSuggestionsAddOn = { name: ADD_ON_CODE_SUGGESTIONS };

  const assignableAddOns = { assignable: [codeSuggestionsAddOn], assigned: [] };
  const assignedAddOns = { assignable: [codeSuggestionsAddOn], assigned: [codeSuggestionsAddOn] };
  const noAddOns = { assignable: [], assigned: [] };

  describe.each([
    {
      title: 'when there are assignable addons',
      addOns: assignableAddOns,
      toggleProps: { disabled: false, value: false },
      tooltipExists: false,
    },
    {
      title: 'when there are assigned addons',
      addOns: assignedAddOns,
      toggleProps: { disabled: false, value: true },
      tooltipExists: false,
    },
    {
      title: 'when there are no assignable addons',
      addOns: noAddOns,
      toggleProps: { disabled: true, value: false },
      tooltipExists: true,
    },
    {
      title: 'when addons is not provided',
      addOns: undefined,
      toggleProps: { disabled: true, value: false },
      tooltipExists: true,
    },
  ])('$title', ({ addOns, toggleProps, tooltipExists }) => {
    beforeEach(() => {
      createComponent({ addOns });
    });

    it('renders addon toggle with appropriate props', () => {
      expect(findToggle().props()).toEqual(expect.objectContaining(toggleProps));
    });

    it(`shows addon unavailable tooltip: ${tooltipExists}`, () => {
      expect(findTooltip().exists()).toBe(tooltipExists);
    });
  });
});
