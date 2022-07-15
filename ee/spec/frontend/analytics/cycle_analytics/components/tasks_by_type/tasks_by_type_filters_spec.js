import { GlSegmentedControl } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_filters.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';

const findSubjectFilters = (ctx) => ctx.findComponent(GlSegmentedControl);
const findSelectedSubjectFilters = (ctx) => findSubjectFilters(ctx).attributes('checked');

function createComponent({ props = {} } = {}) {
  return shallowMount(TasksByTypeFilters, {
    propsData: {
      subjectFilter: TASKS_BY_TYPE_SUBJECT_ISSUE,
      ...props,
    },
  });
}

describe('TasksByTypeFilters', () => {
  let wrapper = null;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('has the issue subject set by default', () => {
    expect(findSelectedSubjectFilters(wrapper)).toBe(TASKS_BY_TYPE_SUBJECT_ISSUE);
  });

  it('emits the `update-filter` event when a subject filter is clicked', async () => {
    expect(wrapper.emitted('update-filter')).toBeUndefined();

    await findSubjectFilters(wrapper).vm.$emit('input', TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST);

    expect(wrapper.emitted('update-filter')).toBeDefined();
    expect(wrapper.emitted('update-filter')[0]).toEqual([
      {
        filter: TASKS_BY_TYPE_FILTERS.SUBJECT,
        value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
      },
    ]);
  });
});
