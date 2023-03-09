import { GlModal, GlLink, GlIntersperse } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import LicenseComponentLinks, {
  VISIBLE_COMPONENT_COUNT,
} from 'ee/license_compliance/components/license_component_links.vue';

describe('LicenseComponentLinks component', () => {
  // data helpers
  const createComponents = (n) =>
    [...Array(n).keys()].map((i) => ({
      name: `component ${i + 1}`,
      version: (i + 1) % 2 === 0 ? null : `${i + 1}.0.0`,
    }));

  const addUrls = (components, numComponentsWithUrls = Infinity) =>
    components.map((comp, i) => ({
      ...comp,
      ...(i < numComponentsWithUrls ? { blob_path: `component ${i + 1}` } : {}),
    }));

  // wrapper / factory
  let wrapper;
  const factory = ({ numComponents, numComponentsWithUrl = 0, title = 'test-component' } = {}) => {
    const components = addUrls(createComponents(numComponents), numComponentsWithUrl);

    wrapper = shallowMount(LicenseComponentLinks, {
      propsData: {
        components,
        title,
      },
    });
  };

  // query helpers
  const findComponentsList = () => wrapper.find('.js-component-links-component-list');
  const findComponentListItems = () => wrapper.findAll('.js-component-links-component-list-item');
  const findModal = () => wrapper.findComponent(GlModal);
  const findModalItem = () => wrapper.findAll('.js-component-links-modal-item');
  const findModalTrigger = () => wrapper.find('.js-component-links-modal-trigger');

  it("renders components' name and version", () => {
    factory({ numComponents: 2, numComponentsWithUrl: 1 });
    const text = wrapper.text();

    expect(text).toContain(`component 1 (1.0.0)`);
    expect(text).toContain(`component 2`);
    expect(text).not.toContain('component 2 (');
  });

  it('intersperses the list of licenses correctly', () => {
    factory();

    const intersperseInstance = wrapper.findComponent(GlIntersperse);

    expect(intersperseInstance.exists()).toBe(true);
    expect(intersperseInstance.attributes('lastseparator')).toBe(' and ');
  });

  it.each([3, 5, 8, 13])('limits the number of visible licenses to 2', (numComponents) => {
    factory({ numComponents });

    expect(findComponentListItems()).toHaveLength(VISIBLE_COMPONENT_COUNT);
  });

  it.each`
    numComponents | numComponentsWithUrl | expectedNumVisibleLinks | expectedNumModalLinks
    ${2}          | ${2}                 | ${2}                    | ${0}
    ${3}          | ${2}                 | ${2}                    | ${2}
    ${5}          | ${2}                 | ${2}                    | ${2}
    ${2}          | ${1}                 | ${1}                    | ${0}
    ${3}          | ${1}                 | ${1}                    | ${1}
    ${5}          | ${0}                 | ${0}                    | ${0}
  `(
    'contains the correct number of links given $numComponents components where $numComponentsWithUrl contain a url',
    ({ numComponents, numComponentsWithUrl, expectedNumVisibleLinks, expectedNumModalLinks }) => {
      factory({ numComponents, numComponentsWithUrl });

      expect(findComponentsList().findAllComponents(GlLink)).toHaveLength(expectedNumVisibleLinks);

      // findModal() is an empty wrapper if we have less than VISIBLE_COMPONENT_COUNT
      if (numComponents > VISIBLE_COMPONENT_COUNT) {
        expect(findModal().findAllComponents(GlLink)).toHaveLength(expectedNumModalLinks);
      } else {
        expect(findModal().exists()).toBe(false);
      }
    },
  );

  it('sets all links to open in new windows/tabs', () => {
    factory({ numComponents: 8, numComponentsWithUrl: 8 });

    const links = wrapper.findAllComponents(GlLink);

    links.wrappers.forEach((link) => {
      expect(link.attributes('target')).toBe('_blank');
    });
  });

  it.each`
    numComponents | expectedNumExceedingComponents
    ${3}          | ${1}
    ${5}          | ${3}
    ${8}          | ${6}
  `(
    'shows the number of licenses that are included in the modal',
    ({ numComponents, expectedNumExceedingComponents }) => {
      factory({ numComponents });

      expect(findModalTrigger().text()).toBe(`${expectedNumExceedingComponents} more`);
    },
  );

  it.each`
    numComponents | expectedNumModals
    ${0}          | ${0}
    ${1}          | ${0}
    ${2}          | ${0}
    ${3}          | ${1}
    ${5}          | ${1}
    ${8}          | ${1}
  `(
    'contains $expectedNumModals modal when $numComponents components are given',
    ({ numComponents, expectedNumModals }) => {
      factory({ numComponents, expectedNumModals });

      expect(wrapper.findAllComponents(GlModal)).toHaveLength(expectedNumModals);
    },
  );

  it('opens the modal when the trigger gets clicked', () => {
    factory({ numComponents: 3 });
    const modalId = wrapper.findComponent(GlModal).props('modalId');
    const modalTrigger = findModalTrigger();

    const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

    modalTrigger.trigger('click');
    expect(rootEmit.mock.calls[0]).toContain(modalId);
  });

  it('assigns a unique modal-id to each of its instances', () => {
    const numComponents = 4;
    const usedModalIds = [];

    while (usedModalIds.length < 10) {
      factory({ numComponents });
      const modalId = wrapper.findComponent(GlModal).props('modalId');

      expect(usedModalIds).not.toContain(modalId);
      usedModalIds.push(modalId);
    }
  });

  it('uses the title as the modal-title', () => {
    const title = 'test-component';
    factory({ numComponents: 3, title });

    expect(wrapper.findComponent(GlModal).attributes('title')).toEqual(title);
  });

  it('assigns the correct action button text to the modal', () => {
    factory({ numComponents: 3 });

    expect(wrapper.findComponent(GlModal).attributes('ok-title')).toEqual('Close');
  });

  it.each`
    numComponents | expectedComponentsInModal
    ${1}          | ${0}
    ${2}          | ${0}
    ${3}          | ${3}
    ${5}          | ${5}
    ${8}          | ${8}
  `('contains the correct modal content', ({ numComponents, expectedComponentsInModal }) => {
    factory({ numComponents });

    expect(findModalItem().wrappers).toHaveLength(expectedComponentsInModal);
  });
});
