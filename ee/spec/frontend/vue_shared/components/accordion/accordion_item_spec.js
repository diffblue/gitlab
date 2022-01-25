import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { uniqueId } from 'lodash';
import { AccordionItem } from 'ee/vue_shared/components/accordion';
import accordionEventBus from 'ee/vue_shared/components/accordion/accordion_event_bus';

jest.mock('ee/vue_shared/components/accordion/accordion_event_bus', () => ({
  $on: jest.fn(),
  $emit: jest.fn(),
  $off: jest.fn(),
}));

jest.mock('lodash/uniqueId', () => jest.fn().mockReturnValue('mockUniqueId'));

describe('AccordionItem component', () => {
  const mockUniqueId = 'mockUniqueId';
  const accordionId = 'accordionID';

  let wrapper;

  const factory = ({ propsData = {}, defaultSlot = `<p></p>`, titleSlot = `<p></p>` } = {}) => {
    const defaultPropsData = {
      accordionId,
      isLoading: false,
      maxHeight: '',
    };

    wrapper = shallowMount(AccordionItem, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      scopedSlots: {
        default: defaultSlot,
        title: titleSlot,
      },
    });
  };

  const loadingIndicator = () => wrapper.findComponent({ ref: 'loadingIndicator' });
  const expansionTrigger = () => wrapper.findComponent({ ref: 'expansionTrigger' });
  const contentContainer = () => wrapper.findComponent({ ref: 'contentContainer' });
  const content = () => wrapper.findComponent({ ref: 'content' });
  const namespacedCloseOtherAccordionItemsEvent = `${accordionId}.closeOtherAccordionItems`;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rendering options', () => {
    it('does not show a loading indicator if the "isLoading" prop is set to "false"', () => {
      factory({ propsData: { isLoading: false } });

      expect(loadingIndicator().exists()).toBe(false);
    });

    it('shows a loading indicator if the "isLoading" prop is set to "true"', () => {
      factory({ propsData: { isLoading: true } });

      expect(loadingIndicator().exists()).toBe(true);
    });

    it('does not limit the content height per default', () => {
      factory();

      expect(contentContainer().element.style.maxHeight).toBeFalsy();
    });

    it('has "maxHeight" prop that limits the height of the content container to the given value', () => {
      factory({ propsData: { maxHeight: '200px' } });

      expect(content().element.style.maxHeight).toBe('200px');
    });
  });

  describe('scoped slots', () => {
    it.each(['default', 'title'])("contains a '%s' slot", (slotName) => {
      const className = `${slotName}-slot-content`;

      factory({ [`${slotName}Slot`]: `<div class='${className}' />` });

      expect(wrapper.find(`.${className}`).exists()).toBe(true);
    });

    it('contains a default slot', () => {
      factory({ defaultSlot: `<div class='foo' />` });
      expect(wrapper.find(`.foo`).exists()).toBe(true);
    });

    it.each([true, false])(
      'passes the "isExpanded" and "isDisabled" state to the title slot',
      async (state) => {
        const titleSlot = jest.fn();

        factory({ propsData: { disabled: state }, titleSlot });
        wrapper.vm.isExpanded = state;

        await nextTick();
        expect(titleSlot).toHaveBeenCalledWith({
          isExpanded: state,
          isDisabled: state,
        });
      },
    );
  });

  describe('collapsing and expanding', () => {
    beforeEach(factory);

    it('is collapsed per default', () => {
      expect(contentContainer().isVisible()).toBe(false);
    });

    it('expands when the trigger-element gets clicked', async () => {
      expect(contentContainer().isVisible()).toBe(false);

      expansionTrigger().trigger('click');

      await nextTick();
      expect(contentContainer().isVisible()).toBe(true);
    });

    it('emits a namespaced "closeOtherAccordionItems" event, containing the trigger item as a payload', () => {
      expansionTrigger().trigger('click');

      expect(accordionEventBus.$emit).toHaveBeenCalledTimes(1);
      expect(accordionEventBus.$emit).toHaveBeenCalledWith(
        namespacedCloseOtherAccordionItemsEvent,
        wrapper.vm,
      );
    });

    it('subscribes "onCloseOtherAccordionItems" as handler to the namespaced "closeOtherAccordionItems" event', () => {
      expect(accordionEventBus.$on).toHaveBeenCalledTimes(1);
      expect(accordionEventBus.$on).toHaveBeenCalledWith(
        namespacedCloseOtherAccordionItemsEvent,
        wrapper.vm.onCloseOtherAccordionItems,
      );
    });

    it('collapses if "closeOtherAccordionItems" is called with the trigger not being the current item', () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isExpanded: true });
      wrapper.vm.onCloseOtherAccordionItems({});

      expect(wrapper.vm.isExpanded).toBe(false);
    });

    it('does not collapses if "closeOtherAccordionItems" is called with the trigger being the current item', () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isExpanded: true });
      wrapper.vm.onCloseOtherAccordionItems(wrapper.vm);

      expect(wrapper.vm.isExpanded).toBe(true);
    });

    it('unsubscribes from namespaced "closeOtherAccordionItems" when the component is destroyed', () => {
      wrapper.destroy();
      expect(accordionEventBus.$off).toHaveBeenCalledTimes(1);
      expect(accordionEventBus.$off).toHaveBeenCalledWith(namespacedCloseOtherAccordionItemsEvent);
    });
  });

  describe('accessibility', () => {
    beforeEach(factory);

    it('contains a expansion trigger element with a unique, namespaced id', () => {
      expect(uniqueId).toHaveBeenCalledWith('gl-accordion-item-trigger-');
      expect(expansionTrigger().attributes('id')).toBe(mockUniqueId);
    });

    it('contains a content-container element with a unique, namespaced id', () => {
      expect(uniqueId).toHaveBeenCalledWith('gl-accordion-item-content-container-');
      expect(contentContainer().attributes('id')).toBe(mockUniqueId);
    });

    it('has a trigger element that has an "aria-expanded" attribute set, to show if it is expanded or collapsed', async () => {
      expect(expansionTrigger().attributes('aria-expanded')).toBeFalsy();

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isExpanded: true });

      await nextTick();
      expect(expansionTrigger().attributes('aria-expanded')).toBe('true');
    });

    it('has a trigger element that has a "aria-controls" attribute, which points to the content element', () => {
      expect(expansionTrigger().attributes('aria-controls')).toBeTruthy();
      expect(expansionTrigger().attributes('aria-controls')).toBe(
        contentContainer().attributes('id'),
      );
    });

    it('has a content-container element that has a "aria-labelledby" attribute, which points to the trigger element', () => {
      expect(contentContainer().attributes('aria-labelledby')).toBeTruthy();
      expect(contentContainer().attributes('aria-labelledby')).toBe(
        expansionTrigger().attributes('id'),
      );
    });
  });
});
