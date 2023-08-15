import { shallowMount } from '@vue/test-utils';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import IssuableTypeField from '~/issues/show/components/fields/type.vue';
import FormComponent from '~/issues/show/components/form.vue';

describe('Form component', () => {
  let wrapper;

  const defaultProps = {
    endpoint: 'gitlab-org/gitlab-test/-/issues/1',
    formState: {
      title: 'b',
      description: 'a',
      lockedWarningVisible: false,
    },
    issuableType: TYPE_ISSUE,
    issueId: 1,
    markdownPreviewPath: '/',
    markdownDocsPath: '/',
    projectPath: '/',
    projectId: 1,
    projectNamespace: '/',
  };

  const createComponent = (props) => {
    window.gon = { current_user_id: '1' };
    wrapper = shallowMount(FormComponent, {
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

  describe('IssuableTypeField component', () => {
    describe.each`
      issuableType     | exists
      ${TYPE_ISSUE}    | ${true}
      ${TYPE_INCIDENT} | ${true}
      ${'unknown'}     | ${false}
      ${undefined}     | ${false}
    `('when issuableType=$issuableType', ({ issuableType, exists }) => {
      it(`${exists ? 'renders' : 'does not render'}`, () => {
        createComponent({ issuableType });

        expect(wrapper.findComponent(IssuableTypeField).exists()).toBe(exists);
      });
    });
  });
});
