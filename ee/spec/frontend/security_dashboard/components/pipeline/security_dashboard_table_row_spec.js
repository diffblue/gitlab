import { GlFormCheckbox, GlSkeletonLoader } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import SecurityDashboardTableRow from 'ee/security_dashboard/components/pipeline/security_dashboard_table_row.vue';
import VulnerabilityActionButtons from 'ee/security_dashboard/components/pipeline/vulnerability_action_buttons.vue';
import { setupStore } from 'ee/security_dashboard/store';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { trimText } from 'helpers/text_helper';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import mockDataVulnerabilities from '../../store/modules/vulnerabilities/data/mock_data_vulnerabilities';

Vue.use(Vuex);

describe('Security Dashboard Table Row', () => {
  let wrapper;
  let store;

  const createComponent = (mountFunc, { props = {} } = {}) => {
    wrapper = mountFunc(SecurityDashboardTableRow, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store();
    setupStore(store);
    jest.spyOn(store, 'dispatch');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findContent = (i) => wrapper.findAll('.table-mobile-content').at(i);
  const findAllIssueCreated = () => wrapper.findAll('[data-testid="issues-icon"]');
  const hasSelectedClass = () => wrapper.classes('gl-bg-blue-50');
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findSeverityBadge = () => wrapper.findComponent(SeverityBadge);

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(shallowMount, { props: { isLoading: true } });
    });

    it('should display the skeleton loader', () => {
      expect(findLoader().exists()).toBeTruthy();
    });

    it('should not render the severity', () => {
      expect(findSeverityBadge().exists()).toBe(false);
    });

    it('should render a `` for the report type and scanner', () => {
      expect(findContent(3).text()).toEqual('');
      expect(wrapper.find('vulnerability-vendor').exists()).toBeFalsy();
    });

    it('should not render action buttons', () => {
      expect(wrapper.findAll('.action-buttons button')).toHaveLength(0);
    });
  });

  describe('when loaded', () => {
    let vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not display the skeleton loader', () => {
      expect(findLoader().exists()).toBeFalsy();
    });

    it('should render the severity', () => {
      expect(findSeverityBadge().text().toLowerCase()).toBe(vulnerability.severity);
    });

    it('should render the identifier cell', () => {
      const { identifiers } = vulnerability;
      expect(findContent(2).text()).toContain(identifiers[0].name);
      expect(trimText(findContent(2).text())).toContain(`${identifiers.length - 1} more`);
    });

    it('should render the report type', () => {
      expect(findContent(3).text().toLowerCase()).toContain(
        vulnerability.report_type.toLowerCase(),
      );
    });

    it('should render the scanner vendor if the scanner does exist', () => {
      expect(findContent(3).text()).toContain(vulnerability.scanner.vendor);
    });

    describe('the project name', () => {
      it('should render the name', () => {
        expect(findContent(1).text()).toContain(vulnerability.name);
      });

      it('should render the project namespace', () => {
        expect(findContent(1).text()).toContain(vulnerability.location.file);
      });

      it('should fire the setModalData action and open the modal when clicked', () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        jest.spyOn(wrapper.vm.$root, '$emit');

        const el = wrapper.findComponent({ ref: 'vulnerability-title' });
        el.trigger('click');

        expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/setModalData', {
          vulnerability,
        });
        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_SHOW_MODAL, VULNERABILITY_MODAL_ID);
      });
    });

    describe('Non-group Security Dashboard', () => {
      beforeEach(() => {
        // eslint-disable-next-line prefer-destructuring
        vulnerability = mockDataVulnerabilities[7];

        createComponent(shallowMount, { props: { vulnerability } });
      });

      it('should contain container image as the namespace', () => {
        expect(findContent(1).text()).toContain(vulnerability.location.image);
      });
    });
  });

  describe('with a dismissed vulnerability', () => {
    const vulnerability = mockDataVulnerabilities[2];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should have a `dismissed` class', () => {
      expect(wrapper.classes()).toContain('dismissed');
    });

    it('should render a `DISMISSED` tag', () => {
      expect(wrapper.text()).toContain('dismissed');
    });
  });

  describe('with valid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[3];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(1);
    });
  });

  describe('with invalid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[6];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });
  });

  describe('with no issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should not have a `issues` icon', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });

    it('should be unselected', () => {
      expect(hasSelectedClass()).toBe(false);
      expect(findCheckbox().attributes('checked')).toBeFalsy();
    });

    describe('when checked', () => {
      beforeEach(() => {
        findCheckbox().vm.$emit('change');
      });

      it('should be selected', () => {
        expect(hasSelectedClass()).toBe(true);
        expect(findCheckbox().attributes('checked')).toBe('true');
      });

      it('should update store', () => {
        expect(store.dispatch).toHaveBeenCalledWith(
          'vulnerabilities/selectVulnerability',
          vulnerability,
        );
      });

      describe('when unchecked', () => {
        beforeEach(() => {
          findCheckbox().vm.$emit('change');
        });

        it('should be unselected', () => {
          expect(hasSelectedClass()).toBe(false);
          expect(findCheckbox().attributes('checked')).toBeFalsy();
        });

        it('should update store', () => {
          expect(store.dispatch).toHaveBeenCalledWith(
            'vulnerabilities/deselectVulnerability',
            vulnerability,
          );
        });
      });
    });
  });

  describe('with less than two identifiers', () => {
    const vulnerability = mockDataVulnerabilities[1];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should render the identifier cell', () => {
      const { identifiers } = vulnerability;
      expect(findContent(2).text()).toBe(identifiers[0].name);
    });
  });

  describe.each`
    createGitLabIssuePath | createJiraIssueUrl  | canCreateIssue
    ${''}                 | ${''}               | ${false}
    ${''}                 | ${'http://foo.bar'} | ${true}
    ${'/foo/bar'}         | ${''}               | ${true}
    ${'/foo/bar'}         | ${'http://foo.bar'} | ${true}
  `(
    'with createGitLabIssuePath set to "$createGitLabIssuePath" and createJiraIssueUrl to "$createJiraIssueUrl"',
    ({ createGitLabIssuePath, createJiraIssueUrl, canCreateIssue }) => {
      beforeEach(() => {
        const vulnerability = mockDataVulnerabilities[1];
        vulnerability.create_vulnerability_feedback_issue_path = createGitLabIssuePath;
        vulnerability.create_jira_issue_url = createJiraIssueUrl;

        createComponent(shallowMount, { props: { vulnerability } });
      });

      it(`should pass "canCreateIssue" as "${canCreateIssue}" to the action-buttons component`, () => {
        expect(wrapper.findComponent(VulnerabilityActionButtons).props('canCreateIssue')).toBe(
          canCreateIssue,
        );
      });
    },
  );
});
