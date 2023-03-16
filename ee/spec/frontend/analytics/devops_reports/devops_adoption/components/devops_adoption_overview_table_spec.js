import { GlButton, GlIcon, GlBadge, GlProgressBar, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import DevopsAdoptionDeleteModal from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_delete_modal.vue';
import DevopsAdoptionOverviewTable from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview_table.vue';
import { DEVOPS_ADOPTION_TABLE_CONFIGURATION } from 'ee/analytics/devops_reports/devops_adoption/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { devopsAdoptionNamespaceData } from '../mock_data';

const DELETE_MODAL_ID = 'delete-modal-test-unique-id';
const TABLE_TEST_IDS_HEADERS = 'headers';
const TABLE_TEST_IDS_NAMESPACE = 'namespace';
const TABLE_TEST_IDS_ACTIONS = 'actions';

jest.mock('lodash/uniqueId', () => (x) => `${x}test-unique-id`);

describe('DevopsAdoptionOverviewTable', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const { provide = {} } = options;

    wrapper = mountExtended(DevopsAdoptionOverviewTable, {
      propsData: {
        data: devopsAdoptionNamespaceData,
      },
      provide,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        GlModal: createMockDirective('gl-modal'),
      },
    });
  };

  beforeEach(() => {
    localStorage.clear();
  });

  const findCol = (testId) => wrapper.findByTestId(testId);

  const findColRowChild = (col, row, child) =>
    wrapper.findAllByTestId(col).at(row).findComponent(child);

  const findColSubComponent = (colTestId, childComponent) =>
    findCol(colTestId).findComponent(childComponent);

  const findDeleteModal = () => wrapper.findComponent(DevopsAdoptionDeleteModal);

  const findSortByLocalStorageSync = () => wrapper.findAllComponents(LocalStorageSync).at(0);
  const findSortDescLocalStorageSync = () => wrapper.findAllComponents(LocalStorageSync).at(1);

  describe('table headings', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the table headings', () => {
      const headerTexts = wrapper
        .findAllByTestId(TABLE_TEST_IDS_HEADERS)
        .wrappers.map((x) => x.text().split('\n')[0]);

      headerTexts.pop(); // Remove the blank entry at the end used for the actions

      expect(headerTexts).toEqual(['Group', 'Dev', 'Sec', 'Ops']);
    });
  });

  describe('table fields', () => {
    describe('enabled namespace name', () => {
      const groupLink = `/groups/${devopsAdoptionNamespaceData.nodes[0].namespace.fullPath}/-/analytics/devops_adoption`;

      it('displays the correct name', () => {
        createComponent();

        expect(findCol(TABLE_TEST_IDS_NAMESPACE).text()).toBe(
          devopsAdoptionNamespaceData.nodes[0].namespace.fullName,
        );
      });

      it('includes a link to the group DevOps page', () => {
        createComponent();

        const link = findColSubComponent(TABLE_TEST_IDS_NAMESPACE, GlLink);

        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe(groupLink);
      });

      describe('with a relative URL', () => {
        beforeEach(() => {
          gon.relative_url_root = '/fake';
        });

        it('includes a link to the group DevOps page', () => {
          createComponent();

          const link = findColSubComponent(TABLE_TEST_IDS_NAMESPACE, GlLink);

          expect(link.exists()).toBe(true);
          expect(link.attributes('href')).toBe(`/fake${groupLink}`);
        });
      });

      describe('"This group" badge', () => {
        const thisGroupGid = devopsAdoptionNamespaceData.nodes[0].namespace.id;

        it.each`
          scenario                            | expected | provide
          ${'is not shown by default'}        | ${false} | ${null}
          ${'is not shown for other groups'}  | ${false} | ${{ groupGid: 'anotherGroupGid' }}
          ${'is shown for the current group'} | ${true}  | ${{ groupGid: thisGroupGid }}
        `('$scenario', ({ expected, provide }) => {
          createComponent({ provide });

          const badge = findColSubComponent(TABLE_TEST_IDS_NAMESPACE, GlBadge);

          expect(badge.exists()).toBe(expected);
        });
      });

      describe('pending state (no snapshot data available)', () => {
        beforeEach(() => {
          createComponent();
        });

        it('grays the text out', () => {
          const name = findColRowChild(TABLE_TEST_IDS_NAMESPACE, 1, 'span');

          expect(name.classes()).toStrictEqual(['gl-text-gray-400']);
        });

        it('does not include a link to the group DevOps page', () => {
          const link = findColRowChild(TABLE_TEST_IDS_NAMESPACE, 1, GlLink);

          expect(link.exists()).toBe(false);
        });

        describe('hourglass icon', () => {
          let icon;

          beforeEach(() => {
            icon = findColRowChild(TABLE_TEST_IDS_NAMESPACE, 1, GlIcon);
          });

          it('displays the icon', () => {
            expect(icon.exists()).toBe(true);
            expect(icon.props('name')).toBe('hourglass');
          });
        });
      });
    });

    const testCols = DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((col) => [col.title, col.testId]);

    it.each(testCols)('displays the progress bar for %s', (title, testId) => {
      createComponent();

      const progressBar = findColSubComponent(testId, GlProgressBar);

      expect(progressBar.exists()).toBe(true);
    });

    describe.each`
      scenario              | tooltipText                                            | provide                                                            | disabled
      ${'not active group'} | ${'Remove Group from the table.'}                      | ${{}}                                                              | ${false}
      ${'active group'}     | ${'You cannot remove the group you are currently in.'} | ${{ groupGid: devopsAdoptionNamespaceData.nodes[0].namespace.id }} | ${true}
    `('actions column when $scenario', ({ tooltipText, provide, disabled }) => {
      beforeEach(() => {
        createComponent({ provide });
      });

      it('displays the actions icon', () => {
        const button = findColSubComponent(TABLE_TEST_IDS_ACTIONS, GlButton);
        const buttonModalId = getBinding(button.element, 'gl-modal').value;

        expect(button.exists()).toBe(true);
        expect(button.props('disabled')).toBe(disabled);
        expect(button.props('icon')).toBe('remove');
        expect(button.props('category')).toBe('tertiary');
        expect(buttonModalId).toBe(DELETE_MODAL_ID);
      });

      it('wraps the icon in an element with a tooltip', () => {
        const iconWrapper = findCol(TABLE_TEST_IDS_ACTIONS);
        const tooltip = getBinding(iconWrapper.element, 'gl-tooltip');

        expect(iconWrapper.exists()).toBe(true);
        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe(tooltipText);
      });
    });
  });

  describe('when delete button is clicked', () => {
    beforeEach(async () => {
      createComponent();

      const deleteButton = findColSubComponent(TABLE_TEST_IDS_ACTIONS, GlButton);
      deleteButton.vm.$emit('click');
      await nextTick();
    });

    it('renders delete modal', () => {
      expect(findDeleteModal().props()).toEqual({
        modalId: DELETE_MODAL_ID,
        namespace: expect.objectContaining(devopsAdoptionNamespaceData.nodes[0]),
      });
    });

    it.each(['trackModalOpenState', 'enabledNamespacesRemoved'])(
      're emits %s with the given value',
      (event) => {
        expect(wrapper.emitted(event)).toBeUndefined();

        const arg = {};

        findDeleteModal().vm.$emit(event, arg);

        expect(wrapper.emitted(event)).toStrictEqual([[arg]]);
      },
    );
  });

  describe('sorting', () => {
    let headers;

    beforeEach(() => {
      createComponent();
      headers = wrapper.findAllByTestId(TABLE_TEST_IDS_HEADERS);
    });

    it.each`
      column    | index
      ${'name'} | ${0}
      ${'dev'}  | ${1}
    `('sorts correctly $column column', async ({ index }) => {
      expect(findCol(TABLE_TEST_IDS_NAMESPACE).text()).toBe(
        devopsAdoptionNamespaceData.nodes[0].namespace.fullName,
      );

      await headers.at(index).trigger('click');

      expect(findCol(TABLE_TEST_IDS_NAMESPACE).text()).toBe(
        devopsAdoptionNamespaceData.nodes[1].namespace.fullName,
      );
    });

    it('should update local storage when the sort column changes', async () => {
      expect(findSortByLocalStorageSync().props('value')).toBe('name');

      await headers.at(1).trigger('click');

      expect(findSortByLocalStorageSync().props('value')).toBe('dev');
    });

    it('should update local storage when the sort direction changes', async () => {
      expect(findSortDescLocalStorageSync().props('value')).toBe(false);

      await headers.at(0).trigger('click');

      expect(findSortDescLocalStorageSync().props('value')).toBe(true);
    });
  });
});
