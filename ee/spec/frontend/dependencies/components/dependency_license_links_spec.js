import { GlModal, GlLink, GlIntersperse } from '@gitlab/ui';
import { shallowMount, createWrapper } from '@vue/test-utils';
import DependenciesLicenseLinks from 'ee/dependencies/components/dependency_license_links.vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';

describe('DependencyLicenseLinks component', () => {
  // data helpers
  const createLicenses = (n) => [...Array(n).keys()].map((i) => ({ name: `license ${i + 1}` }));
  const addUrls = (licenses, numLicensesWithUrls = Infinity) =>
    licenses.map((ls, i) => ({
      ...ls,
      ...(i < numLicensesWithUrls ? { url: `license ${i + 1}` } : {}),
    }));

  // wrapper / factory
  let wrapper;
  const factory = ({ numLicenses, numLicensesWithUrl = 0, title = 'test-dependency' } = {}) => {
    const licenses = addUrls(createLicenses(numLicenses), numLicensesWithUrl);

    wrapper = shallowMount(DependenciesLicenseLinks, {
      propsData: {
        licenses,
        title,
      },
    });
  };

  // query helpers
  const jsTestClassSelector = (name) => `.js-license-links-${name}`;
  const findLicensesList = () => wrapper.find(jsTestClassSelector('license-list'));
  const findLicenseListItems = () => wrapper.findAll(jsTestClassSelector('license-list-item'));
  const findModal = () => wrapper.find(jsTestClassSelector('modal'));
  const findModalItem = () => wrapper.findAll(jsTestClassSelector('modal-item'));
  const findModalTrigger = () => wrapper.find(jsTestClassSelector('modal-trigger'));

  it('intersperses the list of licenses correctly', () => {
    factory();

    const intersperseInstance = wrapper.findComponent(GlIntersperse);

    expect(intersperseInstance.exists()).toBe(true);
    expect(intersperseInstance.attributes('lastseparator')).toBe(' and ');
  });

  it.each([3, 5, 8, 13])('limits the number of visible licenses to 2', (numLicenses) => {
    factory({ numLicenses });

    expect(findLicenseListItems()).toHaveLength(2);
  });

  it.each`
    numLicenses | numLicensesWithUrl | expectedNumVisibleLinks | expectedNumModalLinks
    ${2}        | ${2}               | ${2}                    | ${0}
    ${3}        | ${2}               | ${2}                    | ${2}
    ${5}        | ${2}               | ${2}                    | ${2}
    ${2}        | ${1}               | ${1}                    | ${0}
    ${3}        | ${1}               | ${1}                    | ${1}
    ${5}        | ${0}               | ${0}                    | ${0}
  `(
    'contains the correct number of links given $numLicenses licenses where $numLicensesWithUrl contain a url',
    ({ numLicenses, numLicensesWithUrl, expectedNumVisibleLinks, expectedNumModalLinks }) => {
      factory({ numLicenses, numLicensesWithUrl });

      expect(findLicensesList().findAllComponents(GlLink)).toHaveLength(expectedNumVisibleLinks);

      expect(findModal().findAllComponents(GlLink)).toHaveLength(expectedNumModalLinks);
    },
  );

  it('sets all links to open in new windows/tabs', () => {
    factory({ numLicenses: 8, numLicensesWithUrl: 8 });

    const links = wrapper.findAllComponents(GlLink);

    links.wrappers.forEach((link) => {
      expect(link.attributes('target')).toBe('_blank');
    });
  });

  it.each`
    numLicenses | expectedNumExceedingLicenses
    ${3}        | ${1}
    ${5}        | ${3}
    ${8}        | ${6}
  `(
    'shows the number of licenses that are included in the modal',
    ({ numLicenses, expectedNumExceedingLicenses }) => {
      factory({ numLicenses });

      expect(findModalTrigger().text()).toBe(`${expectedNumExceedingLicenses} more`);
    },
  );

  it.each`
    numLicenses | expectedNumModals
    ${0}        | ${0}
    ${1}        | ${0}
    ${2}        | ${0}
    ${3}        | ${1}
    ${5}        | ${1}
    ${8}        | ${1}
  `(
    'contains $expectedNumModals modal when $numLicenses licenses are given',
    ({ numLicenses, expectedNumModals }) => {
      factory({ numLicenses, expectedNumModals });

      expect(wrapper.findAllComponents(GlModal)).toHaveLength(expectedNumModals);
    },
  );

  it('opens the modal when the trigger gets clicked', () => {
    factory({ numLicenses: 3 });
    const modalId = wrapper.findComponent(GlModal).props('modalId');
    const modalTrigger = findModalTrigger();

    const rootWrapper = createWrapper(wrapper.vm.$root);

    modalTrigger.trigger('click');
    expect(rootWrapper.emitted(BV_SHOW_MODAL)[0]).toContain(modalId);
  });

  it('assigns a unique modal-id to each of its instances', () => {
    const numLicenses = 4;
    const usedModalIds = [];

    while (usedModalIds.length < 10) {
      factory({ numLicenses });
      const modalId = wrapper.findComponent(GlModal).props('modalId');

      expect(usedModalIds).not.toContain(modalId);
      usedModalIds.push(modalId);
    }
  });

  it('uses the title as the modal-title', () => {
    const title = 'test-dependency';
    factory({ numLicenses: 3, title });

    expect(wrapper.findComponent(GlModal).attributes('title')).toEqual(title);
  });

  it('assigns the correct action button text to the modal', () => {
    factory({ numLicenses: 3 });

    expect(wrapper.findComponent(GlModal).attributes('ok-title')).toEqual('Close');
  });

  it.each`
    numLicenses | expectedLicensesInModal
    ${1}        | ${0}
    ${2}        | ${0}
    ${3}        | ${3}
    ${5}        | ${5}
    ${8}        | ${8}
  `('contains the correct modal content', ({ numLicenses, expectedLicensesInModal }) => {
    factory({ numLicenses });

    expect(findModalItem()).toHaveLength(expectedLicensesInModal);
  });
});
