import { shallowMount } from '@vue/test-utils';
import MrWidgetJiraAssociationMissing from 'ee/vue_merge_request_widget/components/states/mr_widget_jira_association_missing.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';

describe('MrWidgetJiraAssociationMissing', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(MrWidgetJiraAssociationMissing, {
      propsData: {
        mr: {},
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows failed status', () => {
    expect(wrapper.findComponent(StateContainer).exists()).toBe(true);
    expect(wrapper.findComponent(StateContainer).props().status).toBe('failed');
  });

  it('shows the disabled reason', () => {
    expect(wrapper.text()).toContain(
      'Merge blocked: a Jira issue key must be mentioned in the title or description.',
    );
  });
});
