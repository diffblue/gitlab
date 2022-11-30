import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';
import {
  normalizeLicense,
  getPackagesString,
  getStatusTranslationsFromLicenseStatus,
  getIssueStatusFromLicenseStatus,
  convertToOldReportFormat,
  addLicensesMatchingReportGroupStatus,
  reportGroupHasAtLeastOneLicense,
} from 'ee/vue_shared/license_compliance/store/utils';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/ci/reports/constants';
import { licenseReport } from '../mock_data';

describe('utils', () => {
  describe('normalizeLicense', () => {
    it('should convert `approval_status` to `approvalStatus`', () => {
      const src = { name: 'Foo', approval_status: 'allowed', id: 3 };
      const result = normalizeLicense(src);

      expect(result.approvalStatus).toBe(src.approval_status);
      expect(result.approval_status).toBe(undefined);
      expect(result.name).toBe(src.name);
      expect(result.id).toBe(src.id);
    });
  });

  describe('getPackagesString', () => {
    const examplePackages = licenseReport[0].packages;

    it('returns string containing name of package when packages contains only one item', () => {
      expect(getPackagesString(examplePackages.slice(0, 1), true, 3)).toBe('Used by pg');
    });

    it('returns string with comma separated names of packages up to 3 when `truncate` param is true and packages count exceeds `displayPackageCount`', () => {
      expect(getPackagesString(examplePackages, true, 3)).toBe('Used by pg, puma, foo, and ');
    });

    it('returns string with comma separated names of all the packages when `truncate` param is true and packages count does NOT exceed `displayPackageCount`', () => {
      expect(getPackagesString(examplePackages.slice(0, 3), true, 3)).toBe(
        'Used by pg, puma, and foo',
      );
    });

    it('returns string with comma separated names of all the packages when `truncate` param is false irrespective of packages count', () => {
      expect(getPackagesString(examplePackages, false, 3)).toBe(
        'Used by pg, puma, foo, bar, and baz',
      );
    });
  });

  describe('getStatusTranslationsFromLicenseStatus', () => {
    it('returns "Allowed" for allowed license status', () => {
      expect(getStatusTranslationsFromLicenseStatus(LICENSE_APPROVAL_STATUS.ALLOWED)).toBe(
        'Allowed',
      );
    });

    it('returns "Denied" status for denied license status', () => {
      expect(getStatusTranslationsFromLicenseStatus(LICENSE_APPROVAL_STATUS.DENIED)).toBe('Denied');
    });

    it('returns "" for any other status', () => {
      expect(getStatusTranslationsFromLicenseStatus()).toBe('');
    });
  });

  describe('getIssueStatusFromLicenseStatus', () => {
    it('returns SUCCESS status for allowed license status', () => {
      expect(getIssueStatusFromLicenseStatus(LICENSE_APPROVAL_STATUS.ALLOWED)).toBe(STATUS_SUCCESS);
    });

    it('returns FAILED status for denied licenses', () => {
      expect(getIssueStatusFromLicenseStatus(LICENSE_APPROVAL_STATUS.DENIED)).toBe(STATUS_FAILED);
    });

    it('returns NEUTRAL status for undefined', () => {
      expect(getIssueStatusFromLicenseStatus()).toBe(STATUS_NEUTRAL);
    });
  });

  describe('convertToOldReportFormat', () => {
    const rawLicense = {
      name: 'license',
      classification: {
        id: 1,
        approval_status: LICENSE_APPROVAL_STATUS.ALLOWED,
      },
      dependencies: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };
    let parsedLicense;

    beforeEach(() => {
      parsedLicense = convertToOldReportFormat(rawLicense);
    });

    it('should get the approval status', () => {
      expect(parsedLicense.approvalStatus).toEqual(rawLicense.classification.approval_status);
    });

    it('should get the packages', () => {
      expect(parsedLicense.packages).toEqual(rawLicense.dependencies);
    });

    it('should get the id', () => {
      expect(parsedLicense.id).toEqual(rawLicense.classification.id);
    });

    it('should get the status', () => {
      expect(parsedLicense.status).toEqual(STATUS_SUCCESS);
    });

    it('should retain the license name', () => {
      expect(parsedLicense.name).toEqual(rawLicense.name);
    });
  });

  describe('addLicensesMatchingReportGroupStatus', () => {
    describe('with matching licenses', () => {
      it(`adds a "licenses" property containing an array of licenses matching the report's status to the report object`, () => {
        const licenses = [
          { status: 'match' },
          { status: 'no-match' },
          { status: 'match' },
          { status: 'no-match' },
        ];
        const reportGroup = { description: 'description', status: 'match' };

        expect(addLicensesMatchingReportGroupStatus(licenses)(reportGroup)).toEqual({
          ...reportGroup,
          licenses: [licenses[0], licenses[2]],
        });
      });
    });

    describe('without matching licenses', () => {
      it('adds a "licenses" property containing an empty array to the report object', () => {
        const licenses = [
          { status: 'no-match' },
          { status: 'no-match' },
          { status: 'no-match' },
          { status: 'no-match' },
        ];
        const reportGroup = { description: 'description', status: 'match' };

        expect(addLicensesMatchingReportGroupStatus(licenses)(reportGroup)).toEqual({
          ...reportGroup,
          licenses: [],
        });
      });
    });
  });

  describe('reportGroupHasAtLeastOneLicense', () => {
    it.each`
      givenReportGroup                   | expected
      ${{ licenses: [{ foo: 'foo ' }] }} | ${true}
      ${{ licenses: [] }}                | ${false}
      ${{ licenses: null }}              | ${false}
      ${{ licenses: undefined }}         | ${false}
    `(
      'returns "$expected" if the given report-group contains $licenses.length licenses',
      ({ givenReportGroup, expected }) => {
        expect(reportGroupHasAtLeastOneLicense(givenReportGroup)).toBe(expected);
      },
    );
  });
});
