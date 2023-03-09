import { uniqueId } from 'lodash';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { AccordionItem } from 'ee/vue_shared/components/accordion';
import accordionEventBus from 'ee/vue_shared/components/accordion/accordion_event_bus';

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

    wrapper = shallowMountExtended(AccordionItem, {
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

  const factoryMultiple = () => {
    wrapper = mountExtended({
      components: { AccordionItem },
      template: `
        <div>
          <accordion-item accordion-id="1">Content</accordion-item>
          <accordion-item accordion-id="1">Content</accordion-item>
        </div>
      `,
    });
  };

  const allExpansionTriggers = () => wrapper.findAllByTestId('expansion-trigger');
  const allContentContainers = () => wrapper.findAllByTestId('content-container');
  const loadingIndicator = () => wrapper.findByTestId('loading-indicator');
  const expansionTrigger = () => allExpansionTriggers().at(0);
  const contentContainer = () => allContentContainers().at(0);

  const content = () => wrapper.findByTestId('content');
  const namespacedCloseOtherAccordionItemsEvent = `${accordionId}.closeOtherAccordionItems`;

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

      expect(contentContainer().element.style.maxHeight).toBe('');
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

    describe('title slot', () => {
      it.each([true, false])(
        'receives the "isDisabled" state when "isDisabled" is "%s"',
        (state) => {
          const titleSlot = jest.fn();
          factory({ propsData: { disabled: state }, titleSlot });

          expect(titleSlot).toHaveBeenCalledWith(
            expect.objectContaining({
              isDisabled: state,
            }),
          );
        },
      );

      it('receives the "isExpanded" state', async () => {
        const titleSlot = jest.fn();
        factory({ propsData: { disabled: false }, titleSlot });

        expect(titleSlot).toHaveBeenLastCalledWith(
          expect.objectContaining({
            isExpanded: false,
          }),
        );

        await expansionTrigger().trigger('click');

        expect(titleSlot).toHaveBeenLastCalledWith(
          expect.objectContaining({
            isExpanded: true,
          }),
        );
      });
    });
  });

  describe('collapsing and expanding', () => {
    beforeEach(factory);

    it('is collapsed per default', () => {
      expect(contentContainer().isVisible()).toBe(false);
    });

    it('expands when the trigger-element gets clicked', async () => {
      expect(contentContainer().isVisible()).toBe(false);

      await expansionTrigger().trigger('click');

      expect(contentContainer().isVisible()).toBe(true);
    });

    it('collapses when it is already expanded', async () => {
      factory();

      await expansionTrigger().trigger('click');
      expect(contentContainer().isVisible()).toBe(true);

      await expansionTrigger().trigger('click');
      expect(contentContainer().isVisible()).toBe(false);
    });

    it('collapses when another accordion item is expanded', async () => {
      factoryMultiple();
      const firstItemContentContainer = allContentContainers().at(0);

      await allExpansionTriggers().at(0).trigger('click');
      expect(firstItemContentContainer.isVisible()).toBe(true);

      await allExpansionTriggers().at(1).trigger('click');
      expect(firstItemContentContainer.isVisible()).toBe(false);
    });

    it('unsubscribes from namespaced "closeOtherAccordionItems" when the component is destroyed', () => {
      jest.spyOn(accordionEventBus, '$off');
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
      expect(expansionTrigger().attributes('aria-expanded')).toBeUndefined();

      await expansionTrigger().trigger('click');

      expect(expansionTrigger().attributes('aria-expanded')).toBe('true');
    });

    it('has a trigger element that has a "aria-controls" attribute, which points to the content element', () => {
      expect(expansionTrigger().attributes('aria-controls')).toBe(mockUniqueId);
      expect(expansionTrigger().attributes('aria-controls')).toBe(
        contentContainer().attributes('id'),
      );
    });

    it('has a content-container element that has a "aria-labelledby" attribute, which points to the trigger element', () => {
      expect(contentContainer().attributes('aria-labelledby')).toBe(mockUniqueId);
      expect(contentContainer().attributes('aria-labelledby')).toBe(
        expansionTrigger().attributes('id'),
      );
    });
  });
});
