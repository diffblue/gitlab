import { GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EpicForm from 'ee/epic/components/epic_form.vue';
import createEpic from 'ee/epic/queries/create_epic.mutation.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import setWindowLocation from 'helpers/set_window_location_helper';
import Autosave from '~/autosave';
import { visitUrl } from '~/lib/utils/url_utility';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import ColorSelectDropdown from '~/vue_shared/components/color_select_dropdown/color_select_root.vue';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { mockTracking } from 'helpers/tracking_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));
jest.mock('~/autosave');

const TEST_GROUP_PATH = 'gitlab-org';
const TEST_NEW_EPIC = { data: { createEpic: { epic: { webUrl: TEST_HOST } } } };
const TEST_FAILED = { data: { createEpic: { errors: ['mutation failed'] } } };

describe('ee/epic/components/epic_form.vue', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = ({ mutationResult = TEST_NEW_EPIC } = {}) => {
    wrapper = shallowMount(EpicForm, {
      provide: {
        iid: '1',
        groupPath: TEST_GROUP_PATH,
        groupEpicsPath: TEST_HOST,
        labelsManagePath: TEST_HOST,
        markdownPreviewPath: TEST_HOST,
        markdownDocsPath: TEST_HOST,
        glFeatures: {
          epicColorHighlight: true,
        },
      },
      mocks: {
        $apollo: {
          mutate: jest.fn().mockResolvedValue(mutationResult),
        },
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findLabels = () => wrapper.findComponent(LabelsSelectWidget);
  const findColor = () => wrapper.findComponent(ColorSelectDropdown);
  const findTitle = () => wrapper.find('[data-testid="epic-title"]');
  const findDescription = () => wrapper.find('[data-testid="epic-description"]');
  const findConfidentialityCheck = () => wrapper.find('[data-testid="epic-confidentiality"]');
  const findStartDate = () => wrapper.find('[data-testid="epic-start-date"]');
  const findStartDateReset = () => wrapper.find('[data-testid="clear-start-date"]');
  const findDueDate = () => wrapper.find('[data-testid="epic-due-date"]');
  const findDueDateReset = () => wrapper.find('[data-testid="clear-due-date"]');
  const findSaveButton = () => wrapper.find('[data-testid="save-epic"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-epic"]');

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('initializes autosave support on title field', () => {
      expect(Autosave.mock.calls).toEqual([[expect.any(Element), ['/', '', 'title']]]);
    });

    it('can be canceled', () => {
      expect(findCancelButton().attributes('href')).toBe(TEST_HOST);
    });

    it('disables submit button if no title is provided', () => {
      expect(findSaveButton().attributes('disabled')).toBeDefined();
    });

    it.each`
      field               | findInput        | findResetter
      ${'startDateFixed'} | ${findStartDate} | ${findStartDateReset}
      ${'dueDateFixed'}   | ${findDueDate}   | ${findDueDateReset}
    `('can clear $field with side control', ({ field, findInput, findResetter }) => {
      findInput().vm.$emit('input', new Date());

      expect(wrapper.vm[field]).not.toBeNull();

      findResetter().vm.$emit('click');

      return nextTick().then(() => {
        expect(wrapper.vm[field]).toBeNull();
      });
    });
  });

  describe('save', () => {
    const addLabelIds = [1];
    const title = 'Status page MVP';
    const description = '### Goal\n\n- [ ] Item';
    const confidential = true;

    it.each`
      startDateFixed  | dueDateFixed    | startDateIsFixed | dueDateIsFixed
      ${null}         | ${null}         | ${false}         | ${false}
      ${'2021-07-01'} | ${null}         | ${true}          | ${false}
      ${null}         | ${'2021-07-02'} | ${false}         | ${true}
      ${'2021-07-01'} | ${'2021-07-02'} | ${true}          | ${true}
    `(
      'requests mutation with correct data with all start and due date configurations',
      async ({ startDateFixed, dueDateFixed, startDateIsFixed, dueDateIsFixed }) => {
        const epicColor = {
          color: '#217645',
          title: 'Green',
        };

        createWrapper();

        findTitle().vm.$emit('input', title);
        findDescription().vm.$emit('input', description);
        findConfidentialityCheck().vm.$emit('input', confidential);
        findLabels().vm.$emit('updateSelectedLabels', {
          labels: [{ id: 'gid://gitlab/GroupLabel/1' }],
        });
        findColor().vm.$emit('updateSelectedColor', { color: epicColor });

        // Make sure the submitted values for start and due dates are date strings without timezone info.
        // (Datepicker emits a Date object but the submitted value must be a date string).
        findStartDate().vm.$emit('input', startDateFixed ? new Date(startDateFixed) : null);
        findDueDate().vm.$emit('input', dueDateFixed ? new Date(dueDateFixed) : null);

        findForm().vm.$emit('submit', { preventDefault: () => {} });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createEpic,
          variables: {
            input: {
              groupPath: TEST_GROUP_PATH,
              addLabelIds,
              title,
              description,
              confidential,
              startDateFixed,
              startDateIsFixed,
              dueDateFixed,
              dueDateIsFixed,
              color: epicColor.color,
            },
          },
        });

        await nextTick();

        expect(visitUrl).toHaveBeenCalled();
      },
    );

    it.each`
      status        | result           | loading
      ${'succeeds'} | ${TEST_NEW_EPIC} | ${true}
      ${'fails'}    | ${TEST_FAILED}   | ${false}
    `('resets loading indicator when $status', ({ result, loading }) => {
      createWrapper({ mutationResult: result });

      const savePromise = wrapper.vm.save();

      expect(wrapper.vm.loading).toBe(true);

      return savePromise.then(() => {
        expect(findSaveButton().props('loading')).toBe(loading);
      });
    });

    it('tracks event on submit', () => {
      createWrapper();

      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
        label: 'markdown_editor',
        property: 'Epic',
      });
    });

    it('resets automatically saved title and description when request succeeds', async () => {
      setWindowLocation('/my-group/epics/new?q=my-query');
      createWrapper();
      jest.spyOn(Autosave.prototype, 'reset');
      jest.spyOn(markdownEditorEventHub, '$emit');

      findTitle().vm.$emit('input', title);
      findDescription().vm.$emit('input', description);

      findForm().vm.$emit('submit', { preventDefault: () => {} });

      await nextTick();

      expect(Autosave.prototype.reset).toHaveBeenCalledTimes(1);
      expect(markdownEditorEventHub.$emit).toHaveBeenCalledWith(
        CLEAR_AUTOSAVE_ENTRY_EVENT,
        '/my-group/epics/new/?q=my-query/description',
      );
    });
  });
});
