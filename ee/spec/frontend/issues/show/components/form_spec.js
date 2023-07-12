import { shallowMount } from '@vue/test-utils';
import formComponent from '~/issues/show/components/form.vue';

describe('Form', () => {
  let wrapper;
  const defaultProps = {
    endpoint: 'gitlab-org/gitlab-test/-/issues/1',
    formState: {
      title: 'b',
      description: 'a',
      lockedWarningVisible: false,
    },
    issueId: 1,
    markdownPreviewPath: '/',
    markdownDocsPath: '/',
    projectPath: '/',
    projectId: 1,
    projectNamespace: '/',
  };

  const createComponent = (props) => {
    window.gon = { current_user_id: '1' };
    wrapper = shallowMount(formComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          generateDescriptionAi: true,
        },
      },
    });
  };

  it('renders', () => {
    createComponent();

    expect(wrapper.find('form').exists()).toBe(true);
  });
});
