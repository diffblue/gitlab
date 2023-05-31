import NamespaceSelector, {
  CREATE_GROUP_OPTION_VALUE,
} from 'ee/trials/components/namespace_selector.vue';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('NamespaceSelector', () => {
  let wrapper;

  // Props
  const items = [{ test: 'Foo', value: 'bar' }];

  // Finders
  const findListboxInput = () => wrapper.findComponent(ListboxInput);
  const findNewGroupNameInput = () => wrapper.findByTestId('new-group-name-input');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(NamespaceSelector, {
      propsData: {
        items,
        anyTrialEligibleNamespaces: true,
        ...props,
      },
    });
  };

  describe('listbox input', () => {
    it('passes the item to the listbox input', () => {
      createComponent();

      expect(findListboxInput().props('items')).toBe(items);
    });

    it('is hidden if anyTrialEligibleNamespaces is false', () => {
      createComponent({ anyTrialEligibleNamespaces: false });

      expect(findListboxInput().exists()).toBe(false);
    });

    it('is hidden if hideNamespaceSelector is true', () => {
      createComponent({ hideNamespaceSelector: true });

      expect(findListboxInput().exists()).toBe(false);
    });
  });

  describe('"New group name" input', () => {
    it('is hidden by default', () => {
      createComponent();

      expect(findNewGroupNameInput().exists()).toBe(false);
    });

    it('is visible if the initially selected option is "Create group"', () => {
      createComponent({ initialValue: CREATE_GROUP_OPTION_VALUE });

      expect(findNewGroupNameInput().exists()).toBe(true);
    });

    it('is visible and has value if the initially selected option is "Create group"', () => {
      createComponent({ newGroupName: '_name_', initialValue: CREATE_GROUP_OPTION_VALUE });

      expect(findNewGroupNameInput().attributes('value')).toEqual('_name_');
    });

    it('is visible and has value if anyTrialEligibleNamespaces is false', () => {
      createComponent({ newGroupName: '_name_', anyTrialEligibleNamespaces: false });

      expect(findNewGroupNameInput().attributes('value')).toEqual('_name_');
    });

    it('is revealed when selecting the "Create group" option', async () => {
      createComponent();
      await findListboxInput().vm.$emit('select', CREATE_GROUP_OPTION_VALUE);

      expect(findNewGroupNameInput().exists()).toBe(true);
    });
  });
});
