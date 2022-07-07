import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import ProjectList from 'ee/usage_quotas/pipelines/components/project_list.vue';
import { LABEL_CI_MINUTES_DISABLED, LABEL_NO_PROJECTS } from 'ee/usage_quotas/pipelines/constants';
import { defaultProvide, defaultProjectListProps } from '../mock_data';

describe('ProjectCIMinutesList', () => {
  let wrapper;

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    wrapper = mountExtended(ProjectList, {
      propsData: {
        ...defaultProjectListProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => findTable().find('tbody').findAll('tr');

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders project names and CI minutes values', () => {
    createComponent();
    const firstProjectColumns = findTableRows().at(0).findAll('td');
    expect(firstProjectColumns.at(0).text()).toContain(
      defaultProjectListProps.projects[0].project.nameWithNamespace,
    );
    expect(firstProjectColumns.at(1).text()).toContain(
      defaultProjectListProps.projects[0].ci_minutes.toString(),
    );
  });

  describe('with no projects', () => {
    beforeEach(() => {
      createComponent({ props: { projects: [] } });
    });
    it('renders the `no projects` message', () => {
      expect(wrapper.text()).toBe(LABEL_NO_PROJECTS);
    });
  });

  describe('with ciMinutesAnyProjectEnabled disabled', () => {
    beforeEach(() => {
      createComponent({ provide: { ciMinutesAnyProjectEnabled: false } });
    });
    it('renders the ci minutes disabled message', () => {
      expect(wrapper.text().replace(/\s+/g, ' ').trim()).toBe(
        sprintf(LABEL_CI_MINUTES_DISABLED, { linkStart: '', linkEnd: '' }),
      );
    });
  });
});
