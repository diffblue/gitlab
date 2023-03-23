import { GlModal, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import Modal from 'ee/vue_shared/security_reports/components/modal.vue';
import ModalFooter from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import DismissalNote from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import DismissalCommentBoxToggle from 'ee/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

const transition = {
  comment: 'abc',
  author: {},
  created_at: new Date().toISOString(),
  to_state: 'dismissed',
};

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
  const findIssueNote = () => wrapper.findComponent(IssueNote);
  const findDismissalNote = () => wrapper.findComponent(DismissalNote);
  const findDismissalCommentBoxToggle = () => wrapper.findComponent(DismissalCommentBoxToggle);

  describe('modal', () => {
    const findAlert = () => wrapper.findComponent(GlAlert);
    const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

    it('renders a large modal', () => {
      mountComponent({ modal: createState().modal }, mount);
      expect(modal.props('size')).toBe('lg');
    });

    it.each([true, false])(
      'shows/hides loading icon when isLoadingAdditionalInfo prop is %s',
      (isLoadingAdditionalInfo) => {
        mountComponent({ modal: createState().modal, isLoadingAdditionalInfo }, shallowMount);
        expect(findLoadingIcon().exists()).toBe(isLoadingAdditionalInfo);
      },
    );

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
      let propsData;

      beforeEach(() => {
        propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
      });

      it('renders dismissal note', () => {
        propsData.modal.vulnerability.state_transitions = [transition];
        mountComponent(propsData);

        expect(findDismissalNote().props('feedback')).toMatchObject({
          comment_details: { comment: transition.comment },
          author: transition.author,
          created_at: transition.created_at,
        });
      });

      it('renders dismissal note - deprecateVulnerabilitiesFeedback feature flag disabled', () => {
        const feedback = {};
        propsData.modal.vulnerability.dismissalFeedback = feedback;
        mountComponent(propsData, shallowMount, { deprecateVulnerabilitiesFeedback: false });

        expect(findDismissalNote().props('feedback')).toBe(feedback);
      });
    });

    describe('with about to be dismissed finding', () => {
      let propsData;

      beforeEach(() => {
        propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
      });

      it('renders dismissal note', () => {
        propsData.modal.vulnerability.state_transitions = [transition];
        mountComponent(propsData);

        expect(findDismissalNote().props('feedback')).toMatchObject({
          comment_details: { comment: transition.comment },
          author: transition.author,
          created_at: transition.created_at,
        });
      });

      it('renders dismissal note - deprecateVulnerabilitiesFeedback feature flag disabled', () => {
        const feedback = {};
        propsData.modal.vulnerability.dismissalFeedback = feedback;
        mountComponent(propsData, shallowMount, { deprecateVulnerabilitiesFeedback: false });

        expect(findDismissalNote().props('feedback')).toBe(feedback);
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

  describe('issue note', () => {
    const modalData = createState().modal;
    modalData.vulnerability.project = {};

    it('shows issue note with expected props', () => {
      modalData.vulnerability.issue_links = [
        {
          link_type: 'created',
          issue_iid: 1,
          issue_url: 'url',
        },
      ];
      mountComponent({ modal: modalData });

      expect(findIssueNote().props()).toMatchObject({
        feedback: modalData.vulnerability.issue_links[0],
        project: modalData.vulnerability.project,
      });
    });

    it.each`
      issue                                                         | isShown
      ${null}                                                       | ${false}
      ${[{ link_type: 'created' }]}                                 | ${false}
      ${[{ link_type: 'created', issue_iid: 1, issue_url: 'url' }]} | ${true}
    `('shows issue note? $isShown when issue is $issue', ({ issue, isShown }) => {
      modalData.vulnerability.issue_links = issue;
      mountComponent({ modal: modalData });

      expect(findIssueNote().exists()).toBe(isShown);
    });
  });

  describe('issue note - deprecateVulnerabilitiesFeedback feature flag disabled', () => {
    const modalData = createState().modal;
    modalData.vulnerability.project = {};

    it('shows issue note with expected props', () => {
      modalData.vulnerability.issue_feedback = { issue_iid: 1, issue_url: 'url' };
      mountComponent({ modal: modalData }, shallowMount, {
        deprecateVulnerabilitiesFeedback: false,
      });

      expect(findIssueNote().props()).toMatchObject({
        feedback: modalData.vulnerability.issue_feedback,
        project: modalData.vulnerability.project,
      });
    });

    it.each`
      issue                                 | isShown
      ${null}                               | ${false}
      ${{}}                                 | ${false}
      ${{ issue_iid: 1, issue_url: 'url' }} | ${true}
    `('shows issue note? $isShown when issue is $issue', ({ issue, isShown }) => {
      modalData.vulnerability.issue_feedback = issue;
      mountComponent({ modal: modalData }, shallowMount, {
        deprecateVulnerabilitiesFeedback: false,
      });

      expect(findIssueNote().exists()).toBe(isShown);
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

    const addCommentAndSubmit = async (newComment) => {
      findDismissalCommentBoxToggle().vm.$emit('input', newComment);
      findDismissalCommentBoxToggle().vm.$emit('submit');
      await nextTick();
    };

    beforeEach(() => {
      propsData = {
        modal: {
          ...createState().modal,
          isCommentingOnDismissal: true,
        },
      };
    });

    it('shows an error when an empty comment is submitted', async () => {
      mountComponent(propsData);
      await addCommentAndSubmit('');

      expect(findDismissalCommentBoxToggle().props('errorMessage')).toBe(
        'Please add a comment in the text area above',
      );
    });

    it('dismisses the finding with the comment if the finding is not already dismissed', async () => {
      mountComponent(propsData);
      await addCommentAndSubmit(comment);

      expect(wrapper.emitted('dismissVulnerability')[0][0]).toBe(comment);
      expect(findDismissalCommentBoxToggle().props('errorMessage')).toBe('');
    });

    it('adds the dismissal comment if the finding is already dismissed', async () => {
      propsData.modal.vulnerability.state_transitions = [transition];
      mountComponent(propsData);
      await addCommentAndSubmit(comment);

      expect(wrapper.emitted('addDismissalComment')[0][0]).toBe(comment);
      expect(findDismissalCommentBoxToggle().props('errorMessage')).toBe('');
    });

    it('adds the dismissal comment if the finding is already dismissed - deprecateVulnerabilitiesFeedback feature flag disabled', async () => {
      propsData.modal.vulnerability.dismissal_feedback = {};
      mountComponent(propsData, shallowMount, { deprecateVulnerabilitiesFeedback: false });
      await addCommentAndSubmit(comment);

      expect(wrapper.emitted('addDismissalComment')[0][0]).toBe(comment);
      expect(findDismissalCommentBoxToggle().props('errorMessage')).toBe('');
    });
  });
});
