import { shallowMount } from '@vue/test-utils';
import IncludedInTrialIndicator from 'ee/pages/projects/learn_gitlab/components/included_in_trial_indicator.vue';

describe('Learn GitLab Trial Card', () => {
  it('renders correctly', () => {
    const wrapper = shallowMount(IncludedInTrialIndicator);

    expect(wrapper.text()).toEqual('- Included in trial');

    wrapper.destroy();
  });
});
