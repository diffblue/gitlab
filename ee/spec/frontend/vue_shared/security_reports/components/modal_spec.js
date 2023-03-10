import { GlModal, GlAlert } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import Modal from 'ee/vue_shared/security_reports/components/modal.vue';
import ModalFooter from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

describe('Security Reports modal', () => {
  let wrapper;
  let modal;

  const mountComponent = (
    propsData,
    mountFn = shallowMount,
    { deprecateVulnerabilitiesFeedback = true } = {},
  ) => {
    wrapper = mountFn(Modal, {
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
      provide: { glFeatures: { deprecateVulnerabilitiesFeedback } },
      stubs: { GlModal },
    });
    modal = wrapper.findComponent(GlModal);
  };

  const findModalFooter = () => wrapper.findComponent(ModalFooter);

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
        expect(wrapper.findComponent({ ref: 'footer' }).props('canDismissVulnerability')).toBe(
          true,
        );
      });
    });

    describe('with auto remediation available', () => {
      let modalData;

      beforeEach(() => {
        modalData = createState().modal;
        modalData.vulnerability.remediations = [{}];
      });

      it('can create merge request when there is no existing merge request', () => {
        mountComponent({ modal: modalData });

        expect(findModalFooter().props('canCreateMergeRequest')).toBe(true);
      });

      it(`can't create merge request when there is an existing merge request`, () => {
        modalData.vulnerability.merge_request_links = [{}];
        mountComponent({ modal: modalData });

        expect(findModalFooter().props('canCreateMergeRequest')).toBe(false);
      });

      it(`can't create merge request when there is an existing merge request - deprecateVulnerabilitiesFeedback feature flag off`, () => {
        modalData.vulnerability.merge_request_feedback = {};
        mountComponent({ modal: modalData }, shallowMount, {
          deprecateVulnerabilitiesFeedback: false,
        });

        expect(findModalFooter().props('canCreateMergeRequest')).toBe(false);
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
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.remediations = [{ diff: '123' }];
        propsData.modal.isResolved = true;
        mountComponent(propsData, mount);
      });

      it('disallows any actions in the footer', () => {
        expect(findModalFooter().props()).toMatchObject({
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
      expect(wrapper.findComponent({ ref: 'footer' }).props()).toMatchObject({
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
        expect(wrapper.findComponent(IssueNote).exists()).toBe(true);
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
        const note = wrapper.findComponent(IssueNote);
        expect(note.exists()).toBe(false);
      });
    });
  });

  describe('merge request note', () => {
    const mergeRequest = { merge_request_path: 'path' };

    it.each`
      mergeRequestLinks | isShown
      ${[mergeRequest]} | ${true}
      ${[]}             | ${false}
      ${null}           | ${false}
    `(
      'shows the merge request note? $isShown when mergeRequestLinks is $mergeRequestLinks',
      ({ mergeRequestLinks, isShown }) => {
        const modalData = createState().modal;
        modalData.vulnerability.merge_request_links = mergeRequestLinks;
        mountComponent({ modal: modalData });

        expect(wrapper.findComponent(MergeRequestNote).exists()).toBe(isShown);
      },
    );

    it.each`
      mergeRequestFeedback | isShown
      ${mergeRequest}      | ${true}
      ${{}}                | ${false}
      ${null}              | ${false}
    `(
      'shows the merge request note? $isShown when mergeRequestFeedback is $mergeRequestFeedback, deprecateVulnerabilitiesFeedback feature flag disabled',
      ({ mergeRequestFeedback, isShown }) => {
        const modalData = createState().modal;
        modalData.vulnerability.merge_request_feedback = mergeRequestFeedback;
        mountComponent({ modal: modalData }, shallowMount, {
          deprecateVulnerabilitiesFeedback: false,
        });

        expect(wrapper.findComponent(MergeRequestNote).exists()).toBe(isShown);
      },
    );
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
      expect(wrapper.findComponent({ ref: 'footer' }).props()).toMatchObject({
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

      const solutionCard = modal.findComponent(SolutionCard);

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

      const solutionCard = wrapper.findComponent(SolutionCard);

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

      const solutionCard = wrapper.findComponent(SolutionCard);

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
