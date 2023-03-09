import ServiceLevelAgreement from 'ee_component/vue_shared/components/incidents/service_level_agreement.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IncidentsList from '~/incidents/components/incidents_list.vue';
import mockIncidents from './mocks/incidents.json';

const defaultProvide = {
  projectPath: '/project/path',
  newIssuePath: 'namespace/project/-/issues/new',
  incidentTemplateName: 'incident',
  incidentType: 'incident',
  issuePath: '/project/issues',
  publishedAvailable: true,
  emptyListSvgPath: '/assets/empty.svg',
  textQuery: '',
  authorUsernameQuery: '',
  assigneeUsernameQuery: '',
  slaFeatureAvailable: true,
  canCreateIncident: true,
};

describe('Incidents Service Level Agreement', () => {
  let wrapper;

  const findIncidentSlaHeader = () => wrapper.findByTestId('incident-management-sla');
  const findIncidentSLAs = () => wrapper.findAllComponents(ServiceLevelAgreement);

  function mountComponent(provide = {}) {
    wrapper = mountExtended(IncidentsList, {
      data() {
        return {
          incidents: { list: mockIncidents },
          incidentsCount: {},
        };
      },
      mocks: {
        $apollo: {
          queries: {
            incidents: {
              loading: false,
            },
          },
        },
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  }

  describe('Incident SLA field', () => {
    it('displays the column when the feature is available', () => {
      mountComponent({ slaFeatureAvailable: true });

      expect(findIncidentSlaHeader().text()).toContain('Time to SLA');
    });

    it('does not display the column when the feature is not available', () => {
      mountComponent({ slaFeatureAvailable: false });

      expect(findIncidentSlaHeader().exists()).toBe(false);
    });

    it('renders an SLA for each incident with an SLA', () => {
      mountComponent({ slaFeatureAvailable: true });

      expect(findIncidentSLAs()).toHaveLength(2);
    });
  });
});
