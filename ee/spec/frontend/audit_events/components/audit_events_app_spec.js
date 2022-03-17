import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import AuditEventsApp from 'ee/audit_events/components/audit_events_app.vue';

describe('AuditEventsApp', () => {
  let wrapper;
  const initComponent = (isProject = false, showStreams = false) => {
    wrapper = shallowMount(AuditEventsApp, {
      provide: {
        isProject,
        showStreams,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when initialized', () => {
    describe('renders group audit events', () => {
      it('as group owner', () => {
        initComponent(false, true);

        expect(wrapper.findComponent(GlTabs).exists()).toBe(true);
      });

      it('as group maintainer', () => {
        initComponent();

        expect(wrapper.findComponent(GlTabs).exists()).toBe(false);
      });
    });
    it('should render as project audit events', () => {
      initComponent(true);

      expect(wrapper.findComponent(GlTabs).exists()).toBe(false);
    });
  });
});
