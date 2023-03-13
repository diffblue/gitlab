import { GlSprintf } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SecurityReportsSummary from 'ee/security_dashboard/components/pipeline/security_reports_summary.vue';
import Modal from 'ee/vue_shared/security_reports/components/dast_modal.vue';
import { mockPipelineJobs } from 'ee_jest/security_dashboard/mock_data/jobs';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { trimText } from 'helpers/text_helper';
import AccessorUtilities from '~/lib/utils/accessor';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import { pipelineSecurityReportSummary } from './mock_data';

describe('Security reports summary component', () => {
  useLocalStorageSpy();

  let wrapper;

  const createWrapper = (options = {}, mountFunc = shallowMountExtended) => {
    wrapper = mountFunc(SecurityReportsSummary, {
      propsData: {
        summary: {},
        ...options?.propsData,
      },
      stubs: {
        GlSprintf,
        GlCard: { template: '<div><slot name="header" /><slot /></div>' },
        Modal,
      },
      ...options,
    });
  };

  const findToggleButton = () => wrapper.findByTestId('collapse-button');
  const findModalButton = () => wrapper.findByTestId('modal-button');
  const findDownloadDropdown = () => wrapper.findComponent(SecurityReportDownloadDropdown);
  const findDownloadDropdownForScanType = (scanType) =>
    wrapper
      .findByTestId(`artifact-download-${scanType}`)
      .findComponent(SecurityReportDownloadDropdown);

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  afterEach(() => {
    localStorage.clear();
  });

  it.each`
    dastProps                                                  | string
    ${{ vulnerabilitiesCount: 0, scannedResourcesCount: 123 }} | ${'0 vulnerabilities (123 URLs scanned)'}
    ${{ vulnerabilitiesCount: 481, scannedResourcesCount: 0 }} | ${'481 vulnerabilities (0 URLs scanned)'}
    ${{ vulnerabilitiesCount: 1, scannedResourcesCount: 1 }}   | ${'1 vulnerability (1 URL scanned)'}
    ${{ vulnerabilitiesCount: 321 }}                           | ${'321 vulnerabilities'}
    ${{ vulnerabilitiesCount: 0 }}                             | ${'0 vulnerabilities'}
  `('shows security report summary $string', ({ dastProps, string }) => {
    createWrapper({
      propsData: {
        summary: {
          dast: dastProps,
        },
      },
    });

    expect(trimText(wrapper.text())).toContain(string);
    expect(findModalButton().exists()).toBe(false);
  });

  it.each`
    dastProps
    ${{ scannedResourcesCount: 890 }}
    ${{ scannedResourcesCount: 0 }}
  `(
    'does not show the scanned resources count if there is no vulnerabilities count',
    ({ dastProps }) => {
      createWrapper({
        propsData: {
          summary: {
            dast: dastProps,
          },
        },
      });

      expect(trimText(wrapper.text())).not.toContain('URLs scanned');
    },
  );

  it.each`
    summaryProp                                                | string
    ${{ dast: { vulnerabilitiesCount: 123 } }}                 | ${'DAST'}
    ${{ sast: { vulnerabilitiesCount: 123 } }}                 | ${'SAST'}
    ${{ containerScanning: { vulnerabilitiesCount: 123 } }}    | ${'Container Scanning'}
    ${{ dependencyScanning: { vulnerabilitiesCount: 123 } }}   | ${'Dependency Scanning'}
    ${{ apiFuzzing: { vulnerabilitiesCount: 123 } }}           | ${'API Fuzzing'}
    ${{ coverageFuzzing: { vulnerabilitiesCount: 123 } }}      | ${'Coverage Fuzzing'}
    ${{ clusterImageScanning: { vulnerabilitiesCount: 123 } }} | ${'Cluster Image Scanning'}
    ${{ secretDetection: { vulnerabilitiesCount: 123 } }}      | ${'Secret Detection'}
  `('shows user-friendly scanner name for $string', ({ summaryProp, string }) => {
    createWrapper({
      propsData: {
        summary: summaryProp,
      },
    });

    expect(trimText(wrapper.text())).toContain(string);
  });

  it.each`
    summaryProp                                           | jobsProp            | hasDropdown
    ${{ coverageFuzzing: { vulnerabilitiesCount: 123 } }} | ${mockPipelineJobs} | ${true}
    ${{ coverageFuzzing: null }}                          | ${[]}               | ${false}
  `(
    'artifact download dropdown is visible $hasDropdown',
    ({ summaryProp, jobsProp, hasDropdown }) => {
      createWrapper({
        propsData: {
          summary: summaryProp,
          jobs: jobsProp,
        },
      });

      expect(findDownloadDropdown().exists()).toBe(hasDropdown);
    },
  );

  it.each`
    summaryProp                       | report
    ${{ dast: null }}                 | ${'DAST'}
    ${{ sast: null }}                 | ${'SAST'}
    ${{ containerScanning: null }}    | ${'Container Scanning'}
    ${{ dependencyScanning: null }}   | ${'Dependency Scanning'}
    ${{ apiFuzzing: null }}           | ${'API Fuzzing'}
    ${{ coverageFuzzing: null }}      | ${'Coverage Fuzzing'}
    ${{ clusterImageScanning: null }} | ${'Cluster Image Scanning'}
    ${{ secretDetection: null }}      | ${'Secret Detection'}
  `('does not show $report report if scanner did not run', ({ summaryProp, report }) => {
    createWrapper({
      propsData: {
        summary: summaryProp,
      },
    });

    expect(trimText(wrapper.text())).not.toContain(report);
  });

  describe('collapsible behavior', () => {
    const LOCAL_STORAGE_KEY = 'hide_pipelines_security_reports_summary_details';

    describe('initially visible', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('set local storage item to 1 when summary is hidden', async () => {
        await findToggleButton().vm.$emit('click');

        expect(localStorage.setItem).toHaveBeenCalledWith(LOCAL_STORAGE_KEY, '1');
      });

      it('toggle button has the correct label', () => {
        expect(findToggleButton().text()).toBe('Hide details');
      });
    });

    describe('initially hidden', () => {
      beforeEach(() => {
        localStorage.setItem(LOCAL_STORAGE_KEY, '1');
        createWrapper();
      });

      it('removes local storage item when summary is shown', async () => {
        await findToggleButton().vm.$emit('click');

        expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_KEY);
      });

      it('toggle button has the correct label', () => {
        expect(findToggleButton().text()).toBe('Show details');
      });
    });
  });

  describe('when localStorage is unavailable', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
      createWrapper();
    });

    it('does not show the collapse button', () => {
      expect(findToggleButton().exists()).toBe(false);
    });
  });

  describe('with scanned resources', () => {
    const glModalDirective = jest.fn();

    const dastProps = {
      vulnerabilitiesCount: 10,
      scannedResourcesCount: 149,
      scannedResources: {
        nodes: [
          {
            requestMethod: 'GET',
            url: 'https://weburl',
          },
        ],
      },
    };

    beforeEach(() => {
      createWrapper({
        directives: {
          glModal: {
            bind(el, { modifiers }) {
              glModalDirective(modifiers);
            },
          },
        },
        propsData: {
          summary: { dast: dastProps },
        },
      });
    });

    it('should have the modal with id dastUrl', () => {
      const modal = wrapper.findComponent(Modal);

      expect(modal.exists()).toBe(true);
      expect(modal.attributes('modalid')).toBe('dastUrl');
    });

    it('should contain a button with Scanned URLs', () => {
      expect(findModalButton().exists()).toBe(true);
      expect(findModalButton().text()).toContain('Download scanned URLs');
    });

    it('should link it to the given modal', () => {
      expect(glModalDirective).toHaveBeenCalledWith({ dastUrl: true });
    });
  });

  describe('with scanned resources download path', () => {
    const dastProps = {
      vulnerabilitiesCount: 10,
      scannedResourcesCsvPath: '/download/path',
    };

    beforeEach(() => {
      createWrapper({
        propsData: {
          summary: { dast: dastProps },
        },
      });
    });

    it('should contain a artifact download dropdown', () => {
      expect(findDownloadDropdown().exists()).toBe(true);
    });
  });

  describe('with artifact download dropdowns', () => {
    beforeEach(() => {
      createWrapper(
        {
          propsData: {
            summary: pipelineSecurityReportSummary.data.project.pipeline.securityReportSummary,
            jobs: pipelineSecurityReportSummary.data.project.pipeline.jobs.nodes,
          },
        },
        mountExtended,
      );
    });

    it.each`
      analyzer                    | downloadReportType
      ${'API Fuzzing'}            | ${'api_fuzzing'}
      ${'Cluster Image Scanning'} | ${'cluster_image_scanning'}
      ${'Coverage Fuzzing'}       | ${'coverage_fuzzing'}
      ${'DAST'}                   | ${'dast'}
      ${'Dependency Scanning'}    | ${'dependency_scanning'}
      ${'SAST'}                   | ${'sast'}
    `('renders the dropdown for the $analyzer results', ({ downloadReportType }) => {
      const artifacts = findDownloadDropdownForScanType(downloadReportType).props('artifacts');
      expect(artifacts.every((artifact) => artifact.reportType === downloadReportType)).toBe(true);
    });
  });
});
