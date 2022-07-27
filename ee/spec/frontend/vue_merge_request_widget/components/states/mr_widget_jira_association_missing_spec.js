import { shallowMount } from '@vue/test-utils';
import MrWidgetJiraAssociationMissing from 'ee/vue_merge_request_widget/components/states/mr_widget_jira_association_missing.vue';

describe('MrWidgetJiraAssociationMissing', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MrWidgetJiraAssociationMissing);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('shows the disabled reason', () => {
    expect(wrapper.text()).toContain(
      'To merge, a Jira issue key must be mentioned in the title or description.',
    );
  });
});
