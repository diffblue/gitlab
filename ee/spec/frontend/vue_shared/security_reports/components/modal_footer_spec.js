import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DismissButton from 'ee/vue_shared/security_reports/components/dismiss_button.vue';
import component from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

describe('Security Reports modal footer', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mount(component, {
      propsData: {
        isCreatingIssue: false,
        isDismissingVulnerability: false,
        isCreatingMergeRequest: false,
        vulnerability: {},
        ...propsData,
      },
    });
  };

  const findActionButton = () => wrapper.find('[data-testid=create-issue-button]');

  describe('can only create issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
      };
      mountComponent(propsData);
    });

    it('does not render dismiss button', () => {
      expect(wrapper.find('.js-dismiss-btn').exists()).toBe(false);
    });

    it('only renders the create issue button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Create issue');
      expect(findActionButton().text()).toBe('Create issue');
    });

    it('emits createIssue when create issue button is clicked', async () => {
      findActionButton().trigger('click');

      await nextTick();
      expect(wrapper.emitted().createNewIssue).toHaveLength(1);
    });
  });

  describe('can only create jira issue', () => {
    const url = 'https://gitlab.atlassian.net/create-issue';

    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        vulnerability: {
          create_jira_issue_url: url,
        },
      };
      mountComponent(propsData);
    });

    it('has target property properly set', () => {
      expect(findActionButton().props('target')).toBe('_blank');
      expect(findActionButton().props('action')).toBeUndefined();
    });

    it('has href attribute properly set', () => {
      expect(findActionButton().attributes('href')).toBe(url);
    });

    it('has the correct text', () => {
      expect(findActionButton().text()).toBe('Create Jira issue');
    });

    it('has the external-link icon', () => {
      expect(findActionButton().findComponent(GlIcon).props('name')).toBe('external-link');
    });
  });

  describe('can only create merge request', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateMergeRequest: true,
      };
      mountComponent(propsData);
    });

    it('only renders the create merge request button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Resolve with merge request');
      expect(findActionButton().text()).toBe('Resolve with merge request');
    });

    it('emits createMergeRequest when create merge request button is clicked', async () => {
      findActionButton().trigger('click');

      await nextTick();
      expect(wrapper.emitted().createMergeRequest).toHaveLength(1);
    });
  });

  describe('can download download patch', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canDownloadPatch: true,
      };
      mountComponent(propsData);
    });

    it('renders the download patch button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Download patch to resolve');
      expect(findActionButton().text()).toBe('Download patch to resolve');
    });

    it('emits downloadPatch when download patch button is clicked', async () => {
      findActionButton().trigger('click');

      await nextTick();
      expect(wrapper.emitted().downloadPatch).toHaveLength(1);
    });
  });

  describe('can create merge request and issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        canCreateMergeRequest: true,
      };
      mountComponent(propsData);
    });

    it('renders create merge request and issue button as a split button', () => {
      expect(wrapper.find('.js-split-button').exists()).toBe(true);
      expect(wrapper.vm.actionButtons).toHaveLength(2);
      expect(wrapper.findComponent(SplitButton).exists()).toBe(true);
      expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
      expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
    });
  });

  describe('can create merge request, issue, and download patch', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDownloadPatch: true,
      };
      mountComponent(propsData);
    });

    it('renders the split button', () => {
      expect(wrapper.vm.actionButtons).toHaveLength(3);
      expect(wrapper.findComponent(SplitButton).exists()).toBe(true);
      expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
      expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
      expect(wrapper.find('.js-split-button').text()).toContain('Download patch to resolve');
    });
  });

  describe('with dismissable vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canDismissVulnerability: true,
      };
      mountComponent(propsData);
    });

    it('should render the dismiss button', () => {
      expect(wrapper.findComponent(DismissButton).exists()).toBe(true);
    });
  });
});
