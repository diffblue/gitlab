import { GlFormInput, GlForm, GlFormGroup } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import MergeCommitsExportButton from 'ee/compliance_dashboard/components/violations_report/shared/merge_commits_export_button.vue';
import { INPUT_DEBOUNCE, CUSTODY_REPORT_PARAMETER } from 'ee/compliance_dashboard/constants';

const CSV_EXPORT_PATH = '/merge_commit_reports';

describe('MergeCommitsExportButton component', () => {
  let wrapper;

  const findCommitForm = () => wrapper.findComponent(GlForm);
  const findCommitInput = () => wrapper.findComponent(GlFormInput);
  const findCommitInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findCommitInputFeedback = () => wrapper.find('.invalid-feedback');
  const findCommitExportButton = () => wrapper.find('[data-test-id="merge-commit-submit-button"]');
  const findCsvExportButton = () => wrapper.findComponent({ ref: 'listMergeCommitsButton' });

  const createComponent = ({ mountFn = shallowMount, data = {}, provide = {} } = {}) => {
    return mountFn(MergeCommitsExportButton, {
      propsData: {
        mergeCommitsCsvExportPath: CSV_EXPORT_PATH,
      },
      provide: () => provide,
      data: () => data,
    });
  };

  describe('Merge commit CSV export all button', () => {
    beforeEach(() => {
      wrapper = createComponent({ mountFn: mount });
    });

    it('renders the button', () => {
      expect(findCsvExportButton().exists()).toBe(true);
    });

    it('renders the correct button text', () => {
      expect(findCsvExportButton().text()).toEqual('List of all commits');
    });

    it('renders the export icon', () => {
      expect(findCsvExportButton().props('icon')).toBe('export');
    });

    it('links to the csv download path', () => {
      expect(findCsvExportButton().attributes('href')).toEqual(CSV_EXPORT_PATH);
    });
  });

  describe('Merge commit custody report', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the input label', () => {
      expect(findCommitInputGroup().attributes('label')).toBe('Commit SHA');
    });

    it('sets the input debounce time', () => {
      expect(findCommitInput().attributes('debounce')).toEqual(INPUT_DEBOUNCE.toString());
    });

    it('sets the input name', () => {
      expect(findCommitInput().attributes('name')).toEqual(CUSTODY_REPORT_PARAMETER);
    });

    it('sets the form action to the csv download path', () => {
      expect(findCommitForm().attributes('action')).toEqual(CSV_EXPORT_PATH);
    });

    it('sets the invalid input feedback message', () => {
      wrapper = createComponent({ mountFn: mount });

      expect(findCommitInputFeedback().text()).toBe('Invalid hash');
    });

    describe('when the commit input is valid', () => {
      beforeEach(() => {
        wrapper = createComponent({
          mountFn: mount,
          data: { validMergeCommitHash: true },
        });
      });

      it('shows that the input is valid', () => {
        expect(findCommitInputGroup().classes('is-invalid')).toBe(false);
      });

      it('enables the submit button', () => {
        expect(findCommitExportButton().props('disabled')).toBe(false);
      });
    });

    describe('when the commit input is invalid', () => {
      beforeEach(() => {
        wrapper = createComponent({
          mountFn: mount,
          data: { validMergeCommitHash: false },
        });
      });

      it('shows that the input is invalid', () => {
        expect(findCommitInputGroup().classes('is-invalid')).toBe(true);
      });

      it('disables the submit button', () => {
        expect(findCommitExportButton().props('disabled')).toBe(true);
      });
    });
  });
});
