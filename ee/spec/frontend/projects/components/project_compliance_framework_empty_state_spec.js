import { shallowMount } from '@vue/test-utils';
import { GlSprintf, GlEmptyState } from '@gitlab/ui';
import ProjectComplianceFrameworkEmptyState from 'ee/projects/components/project_compliance_framework_empty_state.vue';

describe('Project compliance framework empty state', () => {
  let wrapper;

  const defaultProps = {
    groupName: 'group-name',
    groupPath: '/group-path',
    emptyStateSvgPath: '/image.svg',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectComplianceFrameworkEmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        GlEmptyState,
      },
    });
  };

  it.each`
    addFrameworkPath | description
    ${undefined}     | ${'undefined'}
    ${'/edit-group'} | ${'a string path'}
  `('matches the snapshot when "addFrameworkPath" is $description', ({ addFrameworkPath }) => {
    createComponent({ addFrameworkPath });

    expect(wrapper.element).toMatchSnapshot();
  });
});
