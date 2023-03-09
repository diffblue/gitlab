import { GlDropdownItem, GlSegmentedControl, GlSprintf } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import LabelsSelector from 'ee/analytics/cycle_analytics/components/labels_selector.vue';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_filters.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';
import createStore from 'ee/analytics/cycle_analytics/store';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_INFO } from '~/alert';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { groupLabels, groupLabelNames as selectedLabelNames } from '../../mock_data';

const findSubjectFilters = (ctx) => ctx.findComponent(GlSegmentedControl);
const findSelectedSubjectFilters = (ctx) => findSubjectFilters(ctx).attributes('checked');
const findDropdownLabels = (ctx) =>
  ctx.findComponent(LabelsSelector).findAllComponents(GlDropdownItem);

const selectLabelAtIndex = (ctx, index) => {
  findDropdownLabels(ctx).at(index).trigger('click');

  return waitForPromises();
};

const mockGroupLabelsRequest = () =>
  new MockAdapter(axios).onGet().reply(HTTP_STATUS_OK, groupLabels);

let store = null;
Vue.use(Vuex);

jest.mock('~/alert');

function createComponent({ props = {}, mountFn = shallowMount } = {}) {
  store = createStore();
  return mountFn(TasksByTypeFilters, {
    store: {
      ...store,
      state: {
        defaultGroupLabels: groupLabels,
      },
      getters: {
        ...getters,
        currentGroupPath: 'fake',
      },
    },
    propsData: {
      selectedLabelNames,
      labels: groupLabels,
      subjectFilter: TASKS_BY_TYPE_SUBJECT_ISSUE,
      hasData: true,
      ...props,
    },
    stubs: {
      LabelsSelector,
      GlSprintf,
    },
  });
}

describe('TasksByTypeFilters', () => {
  let wrapper = null;
  let mock = null;

  beforeEach(() => {
    mock = mockGroupLabelsRequest();
    wrapper = createComponent({});

    return waitForPromises();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('labels', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent();

      return waitForPromises();
    });

    it('emits the `update-filter` event when a label is selected', () => {
      expect(wrapper.emitted('update-filter')).toBeUndefined();

      wrapper.findComponent(LabelsSelector).vm.$emit('select-label', groupLabels[0].id);

      expect(wrapper.emitted('update-filter')).toBeDefined();
      expect(wrapper.emitted('update-filter')[0]).toEqual([
        { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: groupLabels[0].id },
      ]);
    });

    describe('with the warningMessageThreshold label threshold reached', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest();
        wrapper = createComponent({
          props: {
            maxLabels: 5,
            selectedLabelNames: [groupLabels[0].title, groupLabels[1].title],
            warningMessageThreshold: 2,
          },
        });

        return waitForPromises().then(() => selectLabelAtIndex(wrapper, 2));
      });

      it('should indicate how many labels are selected', () => {
        expect(wrapper.text()).toContain('2 selected (5 max)');
      });
    });

    describe('with maximum labels selected', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest();

        wrapper = createComponent({
          props: {
            maxLabels: 2,
            selectedLabelNames: [groupLabels[0].title, groupLabels[1].title],
            warningMessageThreshold: 1,
          },
        });

        return waitForPromises().then(() => {
          wrapper.findComponent(LabelsSelector).vm.$emit('select-label', groupLabels[2].id);
        });
      });

      it('should indicate how many labels are selected', () => {
        expect(wrapper.text()).toContain('2 selected (2 max)');
      });

      it('should not allow selecting another label', () => {
        expect(wrapper.emitted('update-filter')).toBeUndefined();
      });

      it('should display a message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Only 2 labels can be selected at this time',
          variant: VARIANT_INFO,
        });
      });
    });
  });

  describe('subject', () => {
    it('has the issue subject set by default', () => {
      expect(findSelectedSubjectFilters(wrapper)).toBe(TASKS_BY_TYPE_SUBJECT_ISSUE);
    });

    it('emits the `update-filter` event when a subject filter is clicked', async () => {
      wrapper = createComponent({ mountFn: mount });
      expect(wrapper.emitted('update-filter')).toBeUndefined();

      await findSubjectFilters(wrapper)
        .findAll('label:not(.active)')
        .at(0)
        .find('input')
        .trigger('change');

      expect(wrapper.emitted('update-filter')).toBeDefined();
      expect(wrapper.emitted('update-filter')[0]).toEqual([
        {
          filter: TASKS_BY_TYPE_FILTERS.SUBJECT,
          value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
        },
      ]);
    });
  });
});
