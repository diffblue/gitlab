import { shallowMount } from '@vue/test-utils';
import formComponent from '~/issues/show/components/form.vue';
import ConvertDescriptionModal from 'ee/issues/show/components/convert_description_modal.vue';

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

  it('renders ConvertDescriptionModal', () => {
    createComponent();

    expect(wrapper.findComponent(ConvertDescriptionModal).exists()).toBe(true);
  });

  it('does not render ConvertDescriptionModal without an issueId', () => {
    createComponent({ issueId: null });

    expect(wrapper.findComponent(ConvertDescriptionModal).exists()).toBe(false);
  });
});
