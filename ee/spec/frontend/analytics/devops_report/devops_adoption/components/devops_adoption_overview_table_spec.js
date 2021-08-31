import { GlButton, GlIcon, GlBadge, GlProgressBar } from '@gitlab/ui';
import DevopsAdoptionDeleteModal from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_delete_modal.vue';
import DevopsAdoptionOverviewTable from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_overview_table.vue';
import {
  TABLE_TEST_IDS_NAMESPACE,
  TABLE_TEST_IDS_ACTIONS,
  TABLE_TEST_IDS_HEADERS,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
} from 'ee/analytics/devops_report/devops_adoption/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { devopsAdoptionNamespaceData } from '../mock_data';

const DELETE_MODAL_ID = 'delete-modal-test-unique-id';

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
        GlTooltip: createMockDirective(),
        GlModal: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findCol = (testId) => wrapper.findByTestId(testId);

  const findColRowChild = (col, row, child) => wrapper.findAllByTestId(col).at(row).find(child);

  const findColSubComponent = (colTestId, childComponent) =>
    findCol(colTestId).find(childComponent);

  const findDeleteModal = () => wrapper.findComponent(DevopsAdoptionDeleteModal);

  describe('table headings', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the table headings', () => {
      const headerTexts = wrapper
        .findAllByTestId(TABLE_TEST_IDS_HEADERS)
        .wrappers.map((x) => x.text());

      expect(headerTexts).toEqual(['Group', 'Dev', 'Sec', 'Ops', '']);
    });
  });

  describe('table fields', () => {
    describe('enabled namespace name', () => {
      it('displays the correct name', () => {
        createComponent();

        expect(findCol(TABLE_TEST_IDS_NAMESPACE).text()).toBe('Group 1');
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
      await deleteButton.vm.$nextTick();
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
        expect(wrapper.emitted(event)).toBeFalsy();

        const arg = {};

        findDeleteModal().vm.$emit(event, arg);

        expect(wrapper.emitted(event)).toStrictEqual([[arg]]);
      },
    );
  });
});
