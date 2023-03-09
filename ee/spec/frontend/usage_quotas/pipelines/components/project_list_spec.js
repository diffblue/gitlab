import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import ProjectList from 'ee/usage_quotas/pipelines/components/project_list.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import {
  LABEL_CI_MINUTES_DISABLED,
  PROJECTS_NO_SHARED_RUNNERS,
} from 'ee/usage_quotas/pipelines/constants';
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

  describe('with projects', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders projects data', () => {
      const firstProjectColumns = findTableRows().at(0).findAll('td');

      expect(firstProjectColumns.at(0).findComponent(ProjectAvatar).props()).toMatchObject({
        projectId: defaultProjectListProps.projects[0].project.id,
        projectName: defaultProjectListProps.projects[0].project.nameWithNamespace,
        projectAvatarUrl: defaultProjectListProps.projects[0].project.avatarUrl,
      });
    });

    it('renders Shared runner duration', () => {
      const firstProjectColumns = findTableRows().at(0).findAll('td');

      expect(firstProjectColumns.at(1).text()).toBe('1.33');
    });

    it('renders CI minutes', () => {
      const firstProjectColumns = findTableRows().at(0).findAll('td');

      expect(firstProjectColumns.at(2).text()).toBe(
        defaultProjectListProps.projects[0].minutes.toString(),
      );
    });
  });

  describe('with no projects', () => {
    beforeEach(() => {
      createComponent({ props: { projects: [] } });
    });

    it('renders the `no projects` message', () => {
      expect(wrapper.text()).toContain(PROJECTS_NO_SHARED_RUNNERS);
    });
  });

  describe('with ciMinutesAnyProjectEnabled disabled', () => {
    beforeEach(() => {
      createComponent({ provide: { ciMinutesAnyProjectEnabled: false } });
    });

    it('renders the ci minutes disabled message', () => {
      expect(wrapper.text().replace(/\s+/g, ' ').trim()).toContain(
        sprintf(LABEL_CI_MINUTES_DISABLED, { linkStart: '', linkEnd: '' }),
      );
    });
  });
});
