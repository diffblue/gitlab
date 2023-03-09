import { GlForm, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import EpicsListBulkEditSidebar from 'ee/epics_list/components/epics_list_bulk_edit_sidebar.vue';
import { mockFormattedEpic, mockFormattedEpic2 } from 'ee_jest/roadmap/mock_data';
import {
  mockLabels,
  mockRegularLabel,
  mockScopedLabel,
} from 'jest/sidebar/components/labels/labels_select_vue/mock_data';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';

const mockEpic1 = {
  ...mockFormattedEpic,
  id: 'gid://gitlab/Epic/1',
  labels: {
    nodes: [mockRegularLabel],
  },
};

const mockEpic2 = {
  ...mockFormattedEpic2,
  id: 'gid://gitlab/Epic/2',
  labels: {
    nodes: [mockRegularLabel, mockScopedLabel],
  },
};

const labelsFetchPath = '/gitlab-org/my-project/-/labels.json';
const labelsManagePath = '/gitlab-org/my-project/-/labels';

const createComponent = ({ checkedEpics = [mockEpic1, mockEpic2] } = {}) =>
  shallowMount(EpicsListBulkEditSidebar, {
    propsData: {
      checkedEpics,
    },
    provide: {
      labelsFetchPath,
      labelsManagePath,
    },
  });

describe('EpicsListBulkEditSidebar', () => {
  let wrapper;
  const findLabelsSelect = () => wrapper.findComponent(LabelsSelectWidget);
  const checkedLabels = mockLabels.slice(0, 2).map((label) => ({ ...label, set: true }));
  const removedLabels = mockLabels.slice(2).map((label) => ({ ...label, set: false }));

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders gl-form with labels-select-widget', () => {
    expect(wrapper.findComponent(GlForm).attributes('id')).toBe('epics-list-bulk-edit');
    expect(wrapper.findComponent(GlFormGroup).attributes('label')).toBe('Labels');

    expect(findLabelsSelect().exists()).toBe(true);
    expect(findLabelsSelect().props()).toMatchObject({
      allowLabelEdit: true,
      allowMultiselect: true,
      allowScopedLabels: true,
      selectedLabels: [
        { ...mockRegularLabel, set: true },
        { ...mockScopedLabel, indeterminate: true },
      ],
      labelsFetchPath,
      labelsManagePath,
      variant: 'embedded',
    });
  });

  it.each`
    case         | touchedLabels    | addLabelIds | removeLabelIds
    ${'added'}   | ${checkedLabels} | ${[29, 28]} | ${[]}
    ${'removed'} | ${removedLabels} | ${[]}       | ${[26, 27]}
  `(
    'emits `bulk-update` event with request payload object on component after labels are $case',
    async ({ touchedLabels, addLabelIds, removeLabelIds }) => {
      findLabelsSelect().vm.$emit('onDropdownClose', touchedLabels);

      await nextTick();

      wrapper.findComponent(GlForm).vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      expect(wrapper.emitted('bulk-update')).toBeDefined();
      expect(wrapper.emitted('bulk-update')[0]).toEqual([
        {
          issuable_ids: '1,2',
          add_label_ids: addLabelIds,
          remove_label_ids: removeLabelIds,
        },
      ]);
    },
  );
});
