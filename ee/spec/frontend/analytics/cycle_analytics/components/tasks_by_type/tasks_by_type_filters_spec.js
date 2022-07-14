import { GlSegmentedControl, GlSprintf } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_filters.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';
import createStore from 'ee/analytics/cycle_analytics/store';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import waitForPromises from 'helpers/wait_for_promises';
import { groupLabels } from '../../mock_data';

const selectedLabelIds = [groupLabels[0].id];

const findSubjectFilters = (ctx) => ctx.findComponent(GlSegmentedControl);
const findSelectedSubjectFilters = (ctx) => findSubjectFilters(ctx).attributes('checked');

const mockGroupLabelsRequest = () => new MockAdapter(axios).onGet().reply(200, groupLabels);

let store = null;
Vue.use(Vuex);

jest.mock('~/flash');

function createComponent({ props = {}, mountFn = shallowMount } = {}) {
  store = createStore();
  return mountFn(TasksByTypeFilters, {
    store: {
      ...store,
      getters: {
        ...getters,
        currentGroupPath: 'fake',
      },
    },
    propsData: {
      selectedLabelIds,
      labels: groupLabels,
      subjectFilter: TASKS_BY_TYPE_SUBJECT_ISSUE,
      hasData: true,
      ...props,
    },
    stubs: {
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
    wrapper.destroy();
  });

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
