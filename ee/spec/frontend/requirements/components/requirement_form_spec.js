import { GlDrawer, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { getByText } from '@testing-library/dom';
import $ from 'jquery';
import { extendedWrapper, shallowMountExtended } from 'helpers/vue_test_utils_helper';

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

describe('RequirementForm', () => {
  let documentEventSpyOn;
  let wrapper;

  const createComponent = ({
    drawerOpen = true,
    enableRequirementEdit = false,
    requirement = null,
    requirementRequestActive = false,
  } = {}) =>
    shallowMountExtended(RequirementForm, {
      provide: {
        descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
        descriptionHelpPath: '/help/user/markdown',
      },
      propsData: {
        drawerOpen,
        enableRequirementEdit,
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

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findIssuableBody = () => wrapper.findComponent(IssuableBody);
  const findSaveButton = () => wrapper.findByTestId('requirement-save');
  const findTitle = () => wrapper.findByTestId('new-requirement-title');
  const findStatusBadge = () => wrapper.findComponent(RequirementStatusBadge);

  beforeEach(() => {
    documentEventSpyOn = jest.spyOn($.prototype, 'on');
  });

  describe('new requirement', () => {
    describe('default behavior', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('displays the title for a new requirement', () => {
        expect(findTitle(wrapper).exists()).toBe(true);
        expect(findStatusBadge(wrapper).exists()).toBe(false);
      });

      it('displays the save button with text "Create requirement" when there is no requirement', () => {
        expect(findSaveButton(wrapper).text()).toBe('Create requirement');
      });

      it('returns empty requirement object while in create mode', () => {
        expect(findIssuableBody(wrapper).props('issuable')).toMatchObject({
          iid: '',
          title: '',
          titleHtml: '',
          description: '',
          descriptionHtml: '',
        });
      });

      it('does not render the satisfied checkbox', () => {
        wrapper = createComponent({ enableRequirementEdit: true, requirement: null });
        expect(findCheckbox(wrapper).exists()).toBe(false);
      });

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

      it('emits `drawer-close` event when form create mode', () => {
        wrapper.vm.handleCancel();

        expect(wrapper.emitted('drawer-close')).toHaveLength(1);
      });

      describe('drawerOpen', () => {
        it('sets `satisfied` value to false when `drawerOpen` prop is changed to false', async () => {
          await wrapper.setProps({
            drawerOpen: false,
          });
          expect(wrapper.vm.satisfied).toBe(false);
        });

        it('binds `keydown` event listener on document when `drawerOpen` prop is changed to true', async () => {
          jest.spyOn(document, 'addEventListener');

          await wrapper.setProps({
            drawerOpen: false,
          });
          expect(document.addEventListener).not.toHaveBeenCalled();

          await wrapper.setProps({
            drawerOpen: true,
          });
          expect(document.addEventListener).toHaveBeenCalledWith('keydown', expect.any(Function));
        });
      });
    });

    describe('mounted', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

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
  });

  describe('existing requirement', () => {
    describe('default behavior', () => {
      beforeEach(() => {
        wrapper = createComponent({
          requirement: mockRequirementsOpen[0],
        });
      });
      it('emits `disable-edit` event when form edit mode', () => {
        wrapper.vm.handleCancel();

        expect(wrapper.emitted('disable-edit')).toHaveLength(1);
      });

      it('emits `save` event on component with object as param containing `iid`, `title`, `description` & `lastTestReportState` when form is in update mode', () => {
        const { iid, title, description } = mockRequirementsOpen[0];
        wrapper.vm.handleSave({
          issuableTitle: title,
          issuableDescription: description,
        });

        expect(wrapper.emitted('save')).toHaveLength(1);
        expect(wrapper.emitted('save')[0]).toEqual([
          {
            iid,
            title,
            description,
            lastTestReportState: wrapper.vm.newLastTestReportState(),
          },
        ]);
      });

      it('renders drawer header with `requirement.reference` and test report badge', () => {
        expect(
          getByText(wrapper.element, `#${mockRequirementsOpen[0].workItemIid}`),
        ).not.toBeNull();
        expect(findStatusBadge(wrapper).exists()).toBe(true);
        expect(findStatusBadge(wrapper).props('testReport')).toBe(mockTestReport);
      });

      it('renders issuable-body component', () => {
        const issuableBody = findIssuableBody();

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
        await wrapper.setProps({
          enableRequirementEdit: true,
        });

        const issuableBody = extendedWrapper(findIssuableBody());

        expect(findSaveButton(wrapper).exists()).toBe(true);
        expect(findSaveButton(wrapper).text()).toBe('Save changes');
        expect(issuableBody.findByTestId('requirement-cancel').exists()).toBe(true);
      });

      it('renders secondary-content slot contents within issuable-body', () => {
        const issuableBody = findIssuableBody();

        expect(issuableBody.text()).toContain(`REQ-${mockRequirementsOpen[0].iid}`);
        expect(issuableBody.text()).toContain(`#${mockRequirementsOpen[0].workItemIid}`);
      });

      it('does not render the title for an existing requirement', () => {
        expect(findTitle(wrapper).exists()).toBe(false);
        expect(findStatusBadge(wrapper).exists()).toBe(true);
      });

      it('renders the save button with text "Saves changes" when there is a requirement', () => {
        wrapper = createComponent({
          enableRequirementEdit: true,
          requirement: mockRequirementsOpen[1],
        });
        expect(findSaveButton(wrapper).text()).toBe('Save changes');
      });

      it('returns requirement object while in show/edit mode', () => {
        expect(findIssuableBody(wrapper).props('issuable')).toBe(mockRequirementsOpen[0]);
      });

      it.each`
        requirement                | satisfied
        ${mockRequirementsOpen[0]} | ${true}
        ${mockRequirementsOpen[1]} | ${false}
      `(
        `renders the satisfied checkbox according to the value of \`requirement.satisfied\`=$satisfied`,
        ({ requirement, satisfied }) => {
          wrapper = createComponent({ enableRequirementEdit: true, requirement });

          expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
          expect(findCheckbox(wrapper).exists()).toBe(true);
          expect(findCheckbox(wrapper).vm.$attrs.checked).toBe(satisfied);
        },
      );
    });

    describe.each`
      lastTestReportState | initialRequirement         | updatedProps                                                                                      | newLastTestReportState
      ${STATE_PASSED}     | ${mockRequirementsOpen[0]} | ${{ drawerOpen: false }}                                                                          | ${STATE_FAILED}
      ${STATE_FAILED}     | ${mockRequirementsOpen[1]} | ${{ requirement: mockRequirementsOpen[0] }}                                                       | ${null}
      ${'null'}           | ${mockRequirementsOpen[2]} | ${{ requirement: { ...mockRequirementsOpen[2], satisfied: !mockRequirementsOpen[2].satisfied } }} | ${STATE_PASSED}
    `(
      'newLastTestReportState',
      ({ lastTestReportState, initialRequirement, updatedProps, newLastTestReportState }) => {
        describe(`when \`lastTestReportState\` is ${lastTestReportState}`, () => {
          beforeEach(() => {
            wrapper = createComponent({ requirement: initialRequirement });
          });

          it("returns null when `satisfied` hasn't changed", () => {
            expect(wrapper.vm.newLastTestReportState()).toBe(null);
          });

          it(`returns ${newLastTestReportState} when \`satisfied\` has changed from ${initialRequirement.satisfied} to ${updatedProps}`, async () => {
            await wrapper.setProps(updatedProps);

            expect(wrapper.vm.newLastTestReportState()).toBe(newLastTestReportState);
          });
        });
      },
    );
  });
});
