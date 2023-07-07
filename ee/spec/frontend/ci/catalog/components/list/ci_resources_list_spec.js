import { GlKeysetPagination } from '@gitlab/ui';

import responseBody from 'test_fixtures/graphql/ci/catalog/ci_catalog_resources.json';
import responseBodySinglePage from 'test_fixtures/graphql/ci/catalog/ci_catalog_resources_single_page.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourcesList from 'ee/ci/catalog/components/list/ci_resources_list.vue';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';
import { ciCatalogResourcesItemsCount } from 'ee/ci/catalog/graphql/settings';

describe('CiResourcesList', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    const { nodes, pageInfo, count } = responseBody.data.ciCatalogResources;

    const defaultProps = {
      currentPage: 1,
      resources: nodes,
      pageInfo,
      totalCount: count,
    };

    wrapper = shallowMountExtended(CiResourcesList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlKeysetPagination,
      },
    });
  };

  const findPageCount = () => wrapper.findByTestId('pageCount');
  const findResourcesListItems = () => wrapper.findAllComponents(CiResourcesListItem);
  const findPrevBtn = () => wrapper.findByTestId('prevButton');
  const findNextBtn = () => wrapper.findByTestId('nextButton');

  describe('contains only one page', () => {
    const { nodes, pageInfo, count } = responseBodySinglePage.data.ciCatalogResources;

    beforeEach(async () => {
      await createComponent({
        props: { currentPage: 1, resources: nodes, pageInfo, totalCount: count },
      });
    });

    it('shows the right number of items', () => {
      expect(findResourcesListItems()).toHaveLength(nodes.length);
    });

    it('hides the keyset control for previous page', () => {
      expect(findPrevBtn().exists()).toBe(false);
    });

    it('hides the keyset control for next page', () => {
      expect(findNextBtn().exists()).toBe(false);
    });

    it('shows the correct count of current page', () => {
      expect(findPageCount().text()).toContain('1 of 1');
    });
  });

  describe.each`
    hasPreviousPage | hasNextPage | pageText    | expectedTotal                   | currentPage
    ${false}        | ${true}     | ${'1 of 3'} | ${ciCatalogResourcesItemsCount} | ${1}
    ${true}         | ${true}     | ${'2 of 3'} | ${ciCatalogResourcesItemsCount} | ${2}
    ${true}         | ${false}    | ${'3 of 3'} | ${ciCatalogResourcesItemsCount} | ${3}
  `(
    'when on page $pageText',
    ({ currentPage, expectedTotal, pageText, hasPreviousPage, hasNextPage }) => {
      const { nodes, pageInfo, count } = responseBody.data.ciCatalogResources;

      const previousPageState = hasPreviousPage ? 'enabled' : 'disabled';
      const nextPageState = hasNextPage ? 'enabled' : 'disabled';

      beforeEach(async () => {
        await createComponent({
          props: {
            currentPage,
            resources: nodes,
            pageInfo: { ...pageInfo, hasPreviousPage, hasNextPage },
            totalCount: count,
          },
        });
      });

      it('shows the right number of items', () => {
        expect(findResourcesListItems()).toHaveLength(expectedTotal);
      });

      it(`shows the keyset control for previous page as ${previousPageState}`, () => {
        const disableAttr = findPrevBtn().attributes('disabled');

        if (previousPageState === 'disabled') {
          expect(disableAttr).toBeDefined();
        } else {
          expect(disableAttr).toBeUndefined();
        }
      });

      it(`shows the keyset control for next page as ${nextPageState}`, () => {
        const disableAttr = findNextBtn().attributes('disabled');

        if (nextPageState === 'disabled') {
          expect(disableAttr).toBeDefined();
        } else {
          expect(disableAttr).toBeUndefined();
        }
      });

      it('shows the correct count of current page', () => {
        expect(findPageCount().text()).toContain(pageText);
      });
    },
  );

  describe('when there is an error getting the page count', () => {
    beforeEach(() => {
      createComponent({ props: { totalCount: 0 } });
    });

    it('hides the page count', () => {
      expect(findPageCount().exists()).toBe(false);
    });
  });

  describe('emitted events', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      btnText       | elFinder       | eventName
      ${'previous'} | ${findPrevBtn} | ${'onPrevPage'}
      ${'next'}     | ${findNextBtn} | ${'onNextPage'}
    `('emits $eventName when clicking on the $btnText button', async ({ elFinder, eventName }) => {
      await elFinder().vm.$emit('click');

      expect(wrapper.emitted(eventName)).toHaveLength(1);
    });
  });
});
