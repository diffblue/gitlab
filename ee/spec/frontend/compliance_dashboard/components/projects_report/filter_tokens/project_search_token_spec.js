import { GlFilteredSearchToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import ProjectSearchToken from 'ee/compliance_dashboard/components/projects_report/filter_tokens/project_search_token.vue';

describe('ProjectSearchToken', () => {
  const config = {
    groupPath: 'my-group',
  };

  const value = {
    id: 1,
    name: 'Compliance Frameworks',
  };

  it('renders the component with the correct props', () => {
    const wrapper = mount(ProjectSearchToken, {
      propsData: {
        config,
        value,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="suggestions"></slot></div>`,
        }),
      },
    });

    expect(wrapper.findComponent(GlFilteredSearchToken).exists()).toStrictEqual(true);
    expect(wrapper.props('config')).toStrictEqual(config);
    expect(wrapper.props('value')).toStrictEqual(value);
  });
});
