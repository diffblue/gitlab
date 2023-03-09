import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import AuditEventsExportButton from 'ee/audit_events/components/audit_events_export_button.vue';

const EXPORT_HREF = 'http://example.com/audit_log_reports.csv?created_after=2020-12-12';

describe('AuditEventsExportButton component', () => {
  let wrapper;

  const findExportButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}) => {
    return shallowMount(AuditEventsExportButton, {
      propsData: {
        exportHref: EXPORT_HREF,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('Audit Events CSV export button', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the Audit Events CSV export button', () => {
      expect(findExportButton().exists()).toBe(true);
    });

    it('renders the export icon', () => {
      expect(findExportButton().props('icon')).toBe('export');
    });

    it('links to the CSV download path', () => {
      expect(findExportButton().attributes('href')).toEqual(EXPORT_HREF);
    });
  });
});
