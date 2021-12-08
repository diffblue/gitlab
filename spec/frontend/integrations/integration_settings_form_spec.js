import IntegrationSettingsForm from '~/integrations/integration_settings_form';
import eventHub from '~/integrations/edit/event_hub';

jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('lodash/delay', () => (callback) => callback());

const FIXTURE = 'services/edit_service.html';
const mockFormSelector = '.js-integration-settings-form';

describe('IntegrationSettingsForm', () => {
  let integrationSettingsForm;

  beforeEach(() => {
    loadFixtures(FIXTURE);

    integrationSettingsForm = new IntegrationSettingsForm(mockFormSelector);
    integrationSettingsForm.init();
  });

  afterEach(() => {
    eventHub.dispose(); // clear event hub handlers
  });

  describe('constructor', () => {
    it('should initialize form element refs on class object', () => {
      expect(integrationSettingsForm.$form).toBeDefined();
      expect(integrationSettingsForm.$form.nodeName).toBe('FORM');
      expect(integrationSettingsForm.formSelector).toBe(mockFormSelector);
    });

    it('should initialize form metadata on class object', () => {
      expect(integrationSettingsForm.testEndPoint).toBeDefined();
    });
  });
});
