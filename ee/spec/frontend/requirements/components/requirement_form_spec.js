import { GlDrawer, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { getByText } from '@testing-library/dom';
import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import { nextTick } from 'vue';

import RequirementForm from 'ee/requirements/components/requirement_form.vue';
import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';

import { STATE_FAILED, STATE_PASSED } from 'ee/requirements/constants';

import IssuableBody from '~/vue_shared/issuable/show/components/issuable_body.vue';
import IssuableEditForm from '~/vue_shared/issuable/show/components/issuable_edit_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import ZenMode from '~/zen_mode';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

import { mockRequirementsOpen, mockTestReport } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

const createComponent = ({
  drawerOpen = true,
  requirement = null,
  requirementRequestActive = false,
} = {}) =>
  shallowMount(RequirementForm, {
    provide: {
      descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
      descriptionHelpPath: '/help/user/markdown',
    },
    propsData: {
      drawerOpen,
      requirement,
      requirementRequestActive,
    },
    stubs: {
      GlDrawer,
      GlSprintf,
      IssuableBody,
      IssuableEditForm,
      MarkdownField,
    },
  });

describe('RequirementForm', () => {
  let documentEventSpyOn;
  let wrapper;
  let wrapperWithRequirement;

  beforeEach(() => {
    documentEventSpyOn = jest.spyOn($.prototype, 'on');
    wrapper = createComponent();
    wrapperWithRequirement = createComponent({
      requirement: mockRequirementsOpen[0],
    });
  });

  describe('computed', () => {
    describe('isCreate', () => {
      it('returns true when `requirement` prop is null', () => {
        expect(wrapper.vm.isCreate).toBe(true);
      });

      it('returns false when `requirement` prop is not null', () => {
        expect(wrapperWithRequirement.vm.isCreate).toBe(false);
      });
    });

    describe('fieldLabel', () => {
      it('returns string "New Requirement" when `requirement` prop is null', () => {
        expect(wrapper.vm.fieldLabel).toBe('New Requirement');
      });

      it('returns string "Edit Requirement" when `requirement` prop is defined', () => {
        expect(wrapperWithRequirement.vm.fieldLabel).toBe('Edit Requirement');
      });
    });

    describe('saveButtonLabel', () => {
      it('returns string "Create requirement" when `requirement` prop is null', () => {
        expect(wrapper.vm.saveButtonLabel).toBe('Create requirement');
      });

      it('returns string "Save changes" when `requirement` prop is defined', () => {
        expect(wrapperWithRequirement.vm.saveButtonLabel).toBe('Save changes');
      });
    });

    describe('requirementObject', () => {
      it('returns requirement object while in show/edit mode', async () => {
        wrapper.setProps({
          requirement: mockRequirementsOpen[0],
        });

        await nextTick();

        expect(wrapper.vm.requirementObject).toBe(mockRequirementsOpen[0]);
      });

      it('returns empty requirement object while in create mode', async () => {
        wrapper.setProps({
          requirement: null,
        });

        await nextTick();

        expect(wrapper.vm.requirementObject).toMatchObject({
          iid: '',
          title: '',
          titleHtml: '',
          description: '',
          descriptionHtml: '',
        });
      });
    });
  });

  describe('watchers', () => {
    describe('requirement', () => {
      describe('when requirement is not null', () => {
        it.each`
          requirement                | satisfied
          ${mockRequirementsOpen[0]} | ${true}
          ${mockRequirementsOpen[1]} | ${false}
        `(
          `renders the satisfied checkbox according to the value of \`requirement.satisfied\`=$satisfied`,
          async ({ requirement, satisfied }) => {
            wrapper = createComponent();
            wrapper.setProps({ requirement, enableRequirementEdit: true });

            await nextTick();

            expect(wrapper.findComponent(GlFormCheckbox).vm.$attrs.checked).toBe(satisfied);
          },
        );
      });

      describe('when requirement is null', () => {
        beforeEach(() => {
          wrapper.setProps({
            requirement: null,
            enableRequirementEdit: true,
          });
        });

        it('does not render the satisfied checkbox', async () => {
          await nextTick();
          expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(false);
        });
      });
    });

    describe('drawerOpen', () => {
      it('sets `satisfied` value to false when `drawerOpen` prop is changed to false', async () => {
        wrapper.setProps({
          drawerOpen: false,
        });

        await nextTick();

        expect(wrapper.vm.satisfied).toBe(false);
      });

      it('binds `keydown` event listener on document when `drawerOpen` prop is changed to true', async () => {
        jest.spyOn(document, 'addEventListener');

        wrapper.setProps({
          drawerOpen: false,
        });

        await nextTick();
        expect(document.addEventListener).not.toHaveBeenCalled();

        wrapper.setProps({
          drawerOpen: true,
        });

        await nextTick();

        expect(document.addEventListener).toHaveBeenCalledWith('keydown', expect.any(Function));
      });
    });
  });

  describe('mounted', () => {
    it('initializes `zenMode` prop on component', () => {
      expect(wrapper.vm.zenMode instanceof ZenMode).toBe(true);
    });

    it('calls `renderGFM` on `$refs.gfmContainer`', () => {
      expect(renderGFM).toHaveBeenCalled();
    });

    it('binds events `zen_mode:enter` & `zen_mode:leave` events on document', () => {
      expect(documentEventSpyOn).toHaveBeenCalledWith('zen_mode:enter', expect.any(Function));
      expect(documentEventSpyOn).toHaveBeenCalledWith('zen_mode:leave', expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    let documentEventSpyOff;

    it('unbinds events `zen_mode:enter` & `zen_mode:leave` events on document', () => {
      const wrapperTemp = createComponent();
      documentEventSpyOff = jest.spyOn($.prototype, 'off');

      wrapperTemp.destroy();

      expect(documentEventSpyOff).toHaveBeenCalledWith('zen_mode:enter');
      expect(documentEventSpyOff).toHaveBeenCalledWith('zen_mode:leave');
    });
  });

  describe('methods', () => {
    describe.each`
      lastTestReportState | requirement                | newLastTestReportState
      ${STATE_PASSED}     | ${mockRequirementsOpen[0]} | ${STATE_FAILED}
      ${STATE_FAILED}     | ${mockRequirementsOpen[1]} | ${STATE_PASSED}
      ${'null'}           | ${mockRequirementsOpen[2]} | ${STATE_PASSED}
    `('newLastTestReportState', ({ lastTestReportState, requirement, newLastTestReportState }) => {
      describe(`when \`lastTestReportState\` is ${lastTestReportState}`, () => {
        beforeEach(() => {
          wrapperWithRequirement = createComponent({ requirement });
        });

        it("returns null when `satisfied` hasn't changed", () => {
          expect(wrapperWithRequirement.vm.newLastTestReportState()).toBe(null);
        });

        it(`returns ${newLastTestReportState} when \`satisfied\` has changed from ${
          requirement.satisfied
        } to ${!requirement.satisfied}`, () => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapperWithRequirement.setData({
            satisfied: !requirement.satisfied,
          });

          expect(wrapperWithRequirement.vm.newLastTestReportState()).toBe(newLastTestReportState);
        });
      });
    });

    describe('handleSave', () => {
      it('emits `save` event on component with object as param containing `title` & `description` when form is in create mode', () => {
        const issuableTitle = 'foo';
        const issuableDescription = '_bar_';

        wrapper.vm.handleSave({
          issuableTitle,
          issuableDescription,
        });

        expect(wrapper.emitted('save')).toHaveLength(1);
        expect(wrapper.emitted('save')[0]).toEqual([
          {
            title: issuableTitle,
            description: issuableDescription,
          },
        ]);
      });

      it('emits `save` event on component with object as param containing `iid`, `title`, `description` & `lastTestReportState` when form is in update mode', () => {
        const { iid, title, description } = mockRequirementsOpen[0];
        wrapperWithRequirement.vm.handleSave({
          issuableTitle: title,
          issuableDescription: description,
        });

        expect(wrapperWithRequirement.emitted('save')).toHaveLength(1);
        expect(wrapperWithRequirement.emitted('save')[0]).toEqual([
          {
            iid,
            title,
            description,
            lastTestReportState: wrapperWithRequirement.vm.newLastTestReportState(),
          },
        ]);
      });
    });

    describe('handleCancel', () => {
      it('emits `drawer-close` event when form create mode', () => {
        wrapper.vm.handleCancel();

        expect(wrapper.emitted('drawer-close')).toHaveLength(1);
      });

      it('emits `disable-edit` event when form edit mode', () => {
        wrapperWithRequirement.vm.handleCancel();

        expect(wrapperWithRequirement.emitted('disable-edit')).toHaveLength(1);
      });
    });
  });

  describe('template', () => {
    it('renders gl-drawer as component container element', () => {
      expect(wrapper.findComponent(GlDrawer).exists()).toBe(true);
    });

    it('renders drawer header with `requirement.reference` and test report badge', () => {
      expect(
        getByText(wrapperWithRequirement.element, `#${mockRequirementsOpen[0].workItemIid}`),
      ).not.toBeNull();
      expect(wrapperWithRequirement.findComponent(RequirementStatusBadge).exists()).toBe(true);
      expect(wrapperWithRequirement.findComponent(RequirementStatusBadge).props('testReport')).toBe(
        mockTestReport,
      );
    });

    it('renders issuable-body component', () => {
      const issuableBody = wrapperWithRequirement.findComponent(IssuableBody);

      expect(issuableBody.exists()).toBe(true);
      expect(issuableBody.props()).toMatchObject({
        enableEdit: wrapper.vm.canEditRequirement,
        enableAutocomplete: false,
        enableAutosave: false,
        editFormVisible: false,
        showFieldTitle: true,
        descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
        descriptionHelpPath: '/help/user/markdown',
      });
    });

    it('renders edit-form-actions slot contents within issuable-body', async () => {
      wrapperWithRequirement.setProps({
        enableRequirementEdit: true,
      });

      await nextTick();

      const issuableBody = wrapperWithRequirement.findComponent(IssuableBody);

      expect(issuableBody.findComponent(GlFormCheckbox).exists()).toBe(true);
      expect(issuableBody.find('[data-testid="requirement-save"]').exists()).toBe(true);
      expect(issuableBody.find('[data-testid="requirement-cancel"]').exists()).toBe(true);
    });

    it('renders secondary-content slot contents within issuable-body', () => {
      const issuableBody = wrapperWithRequirement.findComponent(IssuableBody);

      expect(issuableBody.text()).toContain(`REQ-${mockRequirementsOpen[0].iid}`);
      expect(issuableBody.text()).toContain(`#${mockRequirementsOpen[0].workItemIid}`);
    });
  });
});
