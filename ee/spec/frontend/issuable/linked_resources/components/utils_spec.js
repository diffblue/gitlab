import { displayAndLogError, getLinkIcon } from 'ee/linked_resources/components/utils';
import { createAlert } from '~/flash';

jest.mock('~/flash');

describe('resource links utils', () => {
  describe('display and log error', () => {
    it('displays and logs an error', () => {
      const error = new Error('test');
      const message = 'Something went wrong while fetching linked resources for the incident.';

      displayAndLogError(message, true, error);

      expect(createAlert).toHaveBeenCalledWith({
        message,
        error,
        captureError: true,
      });
    });
  });

  describe('get link icon', () => {
    it('should display a matching link icon name', () => {
      const name = 'zoom';
      const iconName = 'brand-zoom';

      expect(getLinkIcon(name)).toBe(iconName);
    });

    it('should return a default icon name', () => {
      expect(getLinkIcon('random-link-type')).toBe('external-link');
    });
  });
});
