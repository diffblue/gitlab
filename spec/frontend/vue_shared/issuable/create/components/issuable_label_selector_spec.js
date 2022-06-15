import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import IssuableLabelSelector from '~/vue_shared/issuable/create/components/issuable_label_selector.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import {
  DropdownVariant,
  LabelType,
} from '~/sidebar/components/labels/labels_select_widget/constants';
import { WorkspaceType } from '~/issues/constants';
import { __ } from '~/locale';

const allowLabelRemove = true;
const attrWorkspacePath = '/workspace-path';
const fieldName = 'field_name[]';
const fullPath = '/full-path';
const labelsFilterBasePath = '/labels-filter-base-path';
const initialLabels = [];
const issuableType = 'issue';
const labelType = LabelType.project;
const variant = DropdownVariant.Embedded;
const workspaceType = WorkspaceType.project;

const label1 = {
  __typename: 'Label',
  id: 1,
  title: 'Label 1',
  description: 'Label 1 description',
  color: '#00FF00',
  textColor: '#000000',
};

const label2 = {
  __typename: 'Label',
  id: 2,
  title: 'Label 2',
  description: 'Label 2 description',
  color: '#FF0000',
  textColor: '#FFFFFF',
};

describe('IssuableLabelSelector', () => {
  let wrapper;

  const findTitle = () => wrapper.find('label').text().replace(/\s+/, ' ');
  const findLabelIcon = () => wrapper.findComponent(GlIcon);
  const findAllHiddenInputs = () => wrapper.findAll('input[type="hidden"]');
  const findLabelSelector = () => wrapper.findComponent(LabelsSelect);

  const createComponent = (injectedProps = {}) => {
    return shallowMount(IssuableLabelSelector, {
      provide: {
        allowLabelRemove,
        attrWorkspacePath,
        fieldName,
        fullPath,
        labelsFilterBasePath,
        initialLabels,
        issuableType,
        labelType,
        variant,
        workspaceType,
        ...injectedProps,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('by default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has the selected labels count', () => {
      expect(findTitle()).toBe('Labels 0');
      expect(findLabelIcon().props('name')).toBe('labels');
    });

    it('has the label selector', () => {
      expect(findLabelSelector().props()).toMatchObject({
        allowLabelRemove,
        allowMultiselect: true,
        showEmbeddedLabelsList: true,
        fullPath,
        attrWorkspacePath,
        labelsFilterBasePath,
        dropdownButtonText: __('Select label'),
        labelsListTitle: __('Select label'),
        footerCreateLabelTitle: __('Create project label'),
        footerManageLabelTitle: __('Manage project labels'),
        variant,
        workspaceType,
        labelCreateType: labelType,
        selectedLabels: initialLabels,
      });

      expect(findLabelSelector().text()).toBe(__('None'));
    });
  });

  it('passing initial labels applies them to the form', () => {
    wrapper = createComponent({ initialLabels: [label1, label2] });

    expect(findTitle()).toBe('Labels 2');
    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([label1, label2]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${label1.id}`,
      `${label2.id}`,
    ]);
  });

  it('updates the selected labels on the `updateSelectedLabels` event', async () => {
    wrapper = createComponent();

    expect(findTitle()).toBe('Labels 0');
    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([]);
    expect(findAllHiddenInputs()).toHaveLength(0);

    await findLabelSelector().vm.$emit('updateSelectedLabels', { labels: [label1] });

    expect(findTitle()).toBe('Labels 1');
    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([label1]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${label1.id}`,
    ]);
  });

  it('updates the selected labels on the `onLabelRemove` event', async () => {
    wrapper = createComponent({ initialLabels: [label1] });

    expect(findTitle()).toBe('Labels 1');
    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([label1]);
    expect(findAllHiddenInputs().wrappers.map((input) => input.element.value)).toStrictEqual([
      `${label1.id}`,
    ]);

    await findLabelSelector().vm.$emit('onLabelRemove', 1);

    expect(findTitle()).toBe('Labels 0');
    expect(findLabelSelector().props('selectedLabels')).toStrictEqual([]);
    expect(findAllHiddenInputs()).toHaveLength(0);
  });
});
