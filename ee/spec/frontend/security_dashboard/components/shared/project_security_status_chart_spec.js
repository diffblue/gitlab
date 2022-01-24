import { GlLink, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import VulnerabilitySeverity from 'ee/security_dashboard/components/shared/project_security_status_chart.vue';
import groupVulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/group_vulnerability_grades.query.graphql';
import instanceVulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import { severityGroupTypes } from 'ee/security_dashboard/store/modules/vulnerable_projects/constants';
import { Accordion, AccordionItem } from 'ee/vue_shared/components/accordion';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { trimText } from 'helpers/text_helper';
import {
  mockProjectsWithSeverityCounts,
  mockInstanceVulnerabilityGrades,
  mockGroupVulnerabilityGrades,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Vulnerability Severity component', () => {
  let wrapper;

  const helpPagePath = 'http://localhost/help-me';
  const projects = mockProjectsWithSeverityCounts();

  const findAccordionItemsText = () =>
    wrapper
      .findAll('[data-testid="vulnerability-severity-groups"]')
      .wrappers.map((item) => trimText(item.text()));

  const createComponent = ({ provide, query, mockData } = {}) => {
    return shallowMount(VulnerabilitySeverity, {
      localVue,
      apolloProvider: createMockApollo([[query, jest.fn().mockResolvedValue(mockData)]]),
      propsData: {
        query,
        helpPagePath,
      },
      provide: { groupFullPath: undefined, ...provide },
      stubs: {
        Accordion,
        AccordionItem,
      },
    });
  };

  const findHelpLink = () => wrapper.find(GlLink);
  const findHeader = () => wrapper.find('h4');
  const findDescription = () => wrapper.find('p');
  const findAccordionItemByGrade = (grade) => wrapper.find({ ref: `accordionItem${grade}` });
  const findProjectName = (accordion) => accordion.findAll(GlLink);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading the project severity component for group level dashboard', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        provide: { groupFullPath: 'gitlab-org' },
        query: groupVulnerabilityGradesQuery,
        mockData: mockGroupVulnerabilityGrades(),
      });
      await waitForPromises();
    });

    it('should process the data returned from GraphQL properly', () => {
      expect(findAccordionItemsText()).toEqual([
        'F 1 project',
        'D 1 project',
        'C 2 projects',
        'B 1 project',
        'A 2+ projects',
      ]);
    });
  });

  describe('when loading the project severity component for instance level dashboard', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        query: instanceVulnerabilityGradesQuery,
        mockData: mockInstanceVulnerabilityGrades(),
      });

      await waitForPromises();
    });

    it('should process the data returned from GraphQL properly', () => {
      expect(findAccordionItemsText()).toEqual([
        'F 1 project',
        'D 1 project',
        'C 2 projects',
        'B 1 project',
        'A 2+ projects',
      ]);
    });
  });

  describe('for all cases', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        query: instanceVulnerabilityGradesQuery,
        mockData: mockInstanceVulnerabilityGrades(),
      });

      await waitForPromises();
    });

    it('has the link to the help page', () => {
      expect(findHelpLink().attributes('href')).toBe(helpPagePath);
    });

    it('has a correct header', () => {
      expect(findHeader().text()).toBe('Project security status');
    });

    it('has a correct description', () => {
      expect(findDescription().text()).toBe(
        'Projects are graded based on the highest severity vulnerability present',
      );
    });
  });

  describe.each`
    grade                   | relatedProjects               | correspondingMostSevereVulnerability                            | levels
    ${severityGroupTypes.F} | ${[projects[0]]}              | ${['2 Critical']}                                               | ${'Critical'}
    ${severityGroupTypes.D} | ${[projects[1]]}              | ${['2 High']}                                                   | ${'High or unknown'}
    ${severityGroupTypes.C} | ${[projects[0], projects[1]]} | ${['1 Medium', '1 Medium']}                                     | ${'Medium'}
    ${severityGroupTypes.B} | ${[projects[1]]}              | ${['1 Low']}                                                    | ${'Low'}
    ${severityGroupTypes.A} | ${[projects[2], projects[3]]} | ${['No vulnerabilities present', 'No vulnerabilities present']} | ${'No'}
  `(
    'for grade $grade',
    ({ grade, relatedProjects, correspondingMostSevereVulnerability, levels }) => {
      let accordion;
      let text;

      beforeEach(async () => {
        // Here instance or group does not matter. We just need some data to test
        // common functionality.
        wrapper = createComponent({
          query: instanceVulnerabilityGradesQuery,
          mockData: mockInstanceVulnerabilityGrades(),
        });

        await waitForPromises();

        accordion = findAccordionItemByGrade(grade);
        text = trimText(accordion.text());
      });

      it('has a corresponding accordion item', () => {
        expect(accordion.exists()).toBe(true);
      });

      it('has the projects listed in the accordion item', () => {
        relatedProjects.forEach((project, i) => {
          const projectLink = findProjectName(accordion).at(i);
          expect(projectLink.text()).toBe(project.nameWithNamespace);
          expect(projectLink.attributes('href')).toBe(project.securityDashboardPath);
        });
      });

      it('states which levels belong to the group', () => {
        expect(text).toContain(`${levels} vulnerabilities present`);
      });

      it('states the most severe vulnerability', () => {
        relatedProjects.forEach((_, i) => {
          expect(text).toContain(correspondingMostSevereVulnerability[i]);
        });
      });
    },
  );

  describe('when query is loading', () => {
    it('only shows the header and loading icon', () => {
      wrapper = createComponent({
        query: instanceVulnerabilityGradesQuery,
        mockData: mockInstanceVulnerabilityGrades(),
      });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(findHeader().exists()).toBe(true);
      expect(findDescription().exists()).toBe(false);
      expect(wrapper.findComponent(Accordion).exists()).toBe(false);
    });
  });
});
