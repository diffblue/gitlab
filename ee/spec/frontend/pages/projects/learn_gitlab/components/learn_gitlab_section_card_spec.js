import { GlCard } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LearnGitlabSectionCard from 'ee/pages/projects/learn_gitlab/components/learn_gitlab_section_card.vue';
import { testActions } from './mock_data';

const defaultSection = 'workspace';
const testImage = 'workspace.svg';

describe('Learn GitLab Section Card', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(LearnGitlabSectionCard, {
      propsData: { section: defaultSection, actions: testActions, svg: testImage },
      stubs: {
        GlCard,
      },
    });
  };

  it('renders correctly', () => {
    createWrapper({ completed: false });

    expect(wrapper.element).toMatchSnapshot();
  });
});
