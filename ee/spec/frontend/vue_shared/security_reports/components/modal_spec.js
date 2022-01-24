import { GlModal, GlAlert } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

describe('Security Reports modal', () => {
  let wrapper;
  let modal;

  const mountComponent = (propsData, mountFn = shallowMount) => {
    wrapper = mountFn(component, {
      attrs: {
        static: true,
        visible: true,
      },
      propsData: {
        isCreatingIssue: false,
        isDismissingVulnerability: false,
        isCreatingMergeRequest: false,
        ...propsData,
      },
    });
    modal = wrapper.find(GlModal);
  };

  describe('modal', () => {
    const findAlert = () => wrapper.findComponent(GlAlert);

    it('renders a large modal', () => {
      mountComponent({ modal: createState().modal }, mount);
      expect(modal.props('size')).toBe('lg');
    });

    it('does not render the error message the modal has no error', () => {
      mountComponent({ modal: createState().modal });
      expect(findAlert().exists()).toBe(false);
    });

    it('renders an error message when the modal has an error', () => {
      const { modal: modalData } = createState();
      modalData.error = 'Something went wront';
      mountComponent({ modal: modalData });
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toBe(modalData.error);
    });
  });

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.isDismissed = true;
        propsData.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
          created_at: new Date().toString(),
        };
        mountComponent(propsData, mount);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(modal.text().trim()).toContain('John Smith');
        expect(modal.text().trim()).toContain('@jsmith');
        expect(modal.text().trim()).toContain('#123');
      });

      it('renders the dismissal comment placeholder', () => {
        expect(modal.find('.js-comment-placeholder')).not.toBeNull();
      });
    });

    describe('with about to be dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
        };
        mountComponent(propsData, mount);
      });

      it('renders dismissal author and hides associated pipeline', () => {
        expect(modal.text().trim()).toContain('John Smith');
        expect(modal.text().trim()).toContain('@jsmith');
        expect(modal.text().trim()).not.toContain('#123');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        mountComponent(propsData, mount);
      });

      it('allows the vulnerability to be dismissed', () => {
        expect(wrapper.find({ ref: 'footer' }).props('canDismissVulnerability')).toBe(true);
      });
    });

    describe('with merge request available', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canCreateIssue: true,
          canCreateMergeRequest: true,
        };
        const summary = 'Upgrade to 123';
        const diff = 'abc123';
        propsData.modal.vulnerability.remediations = [{ summary, diff }];
        mountComponent(propsData, mount);
      });

      it('renders create merge request and issue button as a split button', () => {
        expect(wrapper.find('.js-split-button').exists()).toBe(true);
        expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
        expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
      });

      describe('with merge request created', () => {
        const findActionButton = () => wrapper.find('[data-testid=create-issue-button]');

        it('renders the issue button as a single button', async () => {
          const propsData = {
            modal: createState().modal,
            canCreateIssue: true,
            canCreateMergeRequest: true,
          };

          propsData.modal.vulnerability.hasMergeRequest = true;

          wrapper.setProps(propsData);

          await nextTick();
          expect(wrapper.find('.js-split-button').exists()).toBe(false);
          expect(findActionButton().exists()).toBe(true);
          expect(findActionButton().text()).not.toContain('Resolve with merge request');
          expect(findActionButton().text()).toContain('Create issue');
        });
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };
        propsData.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        mountComponent(propsData, mount);
      });

      it('renders title', () => {
        expect(modal.text()).toContain('Arbitrary file existence disclosure in Action Pack');
      });
    });

    describe('with a resolved issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.remediations = [{ diff: '123' }];
        propsData.modal.isResolved = true;
        mountComponent(propsData, mount);
      });

      it('disallows any actions in the footer', () => {
        expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
          canCreateIssue: false,
          canCreateMergeRequest: false,
          canDownloadPatch: false,
          canDismissVulnerability: false,
        });
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      mountComponent(propsData, mount);
    });

    it('disallows any actions in the footer', () => {
      expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDownloadPatch: false,
        canDismissVulnerability: false,
      });
    });
  });

  describe('related issue read access', () => {
    describe('with permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.issue_feedback = {
          issue_url: 'http://issue.url',
        };
        mountComponent(propsData);
      });

      it('displays a link to the issue', () => {
        expect(wrapper.find(IssueNote).exists()).toBe(true);
      });
    });

    describe('without permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.issue_feedback = {
          issue_url: null,
        };
        mountComponent(propsData);
      });

      it('hides the link to the issue', () => {
        const note = wrapper.find(IssueNote);
        expect(note.exists()).toBe(false);
      });
    });
  });

  describe('related merge request read access', () => {
    describe('with permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.merge_request_feedback = {
          merge_request_path: 'http://mr.url',
        };
        mountComponent(propsData);
      });

      it('displays a link to the merge request', () => {
        expect(wrapper.find(MergeRequestNote).exists()).toBe(true);
      });
    });

    describe('without permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.merge_request_feedback = {
          merge_request_path: null,
        };
        mountComponent(propsData);
      });

      it('hides the link to the merge request', () => {
        const note = wrapper.find(MergeRequestNote);
        expect(note.exists()).toBe(false);
      });
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.isResolved = true;
      mountComponent(propsData, mount);
    });

    it('disallows any actions in the footer', () => {
      expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDownloadPatch: false,
        canDismissVulnerability: false,
      });
    });
  });

  describe('Vulnerability Details', () => {
    const blobPath = '/group/project/blob/1ab2c3d4e5/some/file.path#L0-0';
    const namespaceValue = 'foobar';
    const fileValue = '/some/file.path';

    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.vulnerability.blob_path = blobPath;
      propsData.modal.vulnerability.location = {
        file: fileValue,
        operating_system: namespaceValue,
      };
      mountComponent(propsData, mount);
    });

    it('is rendered', () => {
      const vulnerabilityDetails = wrapper.find('.js-vulnerability-details');

      expect(vulnerabilityDetails.exists()).toBe(true);
      expect(vulnerabilityDetails.text()).toContain(namespaceValue);
      expect(vulnerabilityDetails.text()).toContain(fileValue);
    });
  });

  describe('Solution Card', () => {
    it('is rendered if the vulnerability has a solution', async () => {
      const propsData = {
        modal: createState().modal,
      };

      const solution = 'Upgrade to XYZ';
      propsData.modal.vulnerability.solution = solution;
      mountComponent(propsData, mount);
      await nextTick();

      const solutionCard = modal.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(solution);
      expect(modal.find('hr').exists()).toBe(false);
    });

    it('is rendered if the vulnerability has a remediation', async () => {
      const propsData = {
        modal: createState().modal,
      };
      const summary = 'Upgrade to 123';
      const diff = 'foo';
      propsData.modal.vulnerability.remediations = [{ summary, diff }];
      mountComponent(propsData, mount);
      await nextTick();

      const solutionCard = wrapper.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(summary);
      expect(solutionCard.props('hasDownload')).toBe(true);
      expect(wrapper.find('hr').exists()).toBe(false);
    });

    it('is rendered if the vulnerability has neither a remediation nor a solution', async () => {
      const propsData = {
        modal: createState().modal,
      };
      mountComponent(propsData, mount);
      await nextTick();

      const solutionCard = wrapper.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(wrapper.find('hr').exists()).toBe(false);
    });
  });

  describe('add dismissal comment', () => {
    const comment = "Pirates don't eat the tourists";
    let propsData;

    beforeEach(() => {
      propsData = {
        modal: createState().modal,
      };

      propsData.modal.isCommentingOnDismissal = true;
    });

    beforeAll(() => {
      // https://github.com/vuejs/vue-test-utils/issues/532#issuecomment-398449786
      Vue.config.silent = true;
    });

    afterAll(() => {
      Vue.config.silent = false;
    });

    describe('with a non-dismissed vulnerability', () => {
      beforeEach(() => {
        mountComponent(propsData);
      });

      it('creates an error when an empty comment is submitted', () => {
        const { vm } = wrapper;
        vm.handleDismissalCommentSubmission();

        expect(vm.dismissalCommentErrorMessage).toBe('Please add a comment in the text area above');
      });

      it('submits the comment and dismisses the vulnerability if text has been entered', () => {
        const { vm } = wrapper;
        vm.addCommentAndDismiss = jest.fn();
        vm.localDismissalComment = comment;
        vm.handleDismissalCommentSubmission();

        expect(vm.addCommentAndDismiss).toHaveBeenCalled();
        expect(vm.dismissalCommentErrorMessage).toBe('');
      });
    });

    describe('with a dismissed vulnerability', () => {
      beforeEach(() => {
        propsData.modal.vulnerability.dismissal_feedback = { author: {} };
        mountComponent(propsData);
      });

      it('creates an error when an empty comment is submitted', () => {
        const { vm } = wrapper;
        vm.handleDismissalCommentSubmission();

        expect(vm.dismissalCommentErrorMessage).toBe('Please add a comment in the text area above');
      });

      it('submits the comment if text is entered and the vulnerability is already dismissed', () => {
        const { vm } = wrapper;
        vm.addDismissalComment = jest.fn();
        vm.localDismissalComment = comment;
        vm.handleDismissalCommentSubmission();

        expect(vm.addDismissalComment).toHaveBeenCalled();
        expect(vm.dismissalCommentErrorMessage).toBe('');
      });
    });
  });
});
