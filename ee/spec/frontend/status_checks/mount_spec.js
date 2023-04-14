import { createWrapper } from '@vue/test-utils';
import mountStatusChecks from 'ee/status_checks/mount';
import createStore from 'ee/status_checks/store';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

jest.mock('ee/status_checks/store');
jest.mock('~/alert');

describe('mountStatusChecks', () => {
  const projectId = '12345';
  const statusChecksPath = '/api/v4/projects/1/external_status_checks';
  const dispatch = jest.fn();
  let el;

  const setUpDocument = () => {
    el = document.createElement('div');
    el.dataset.projectId = projectId;
    el.dataset.statusChecksPath = statusChecksPath;

    document.body.appendChild(el);

    return el;
  };

  beforeEach(() => {
    createStore.mockReturnValue({ dispatch, state: { settings: {}, statusChecks: [] } });
    setUpDocument();
  });

  afterEach(() => {
    el.remove();
    el = null;
  });

  it('returns null if no element is given', () => {
    expect(mountStatusChecks()).toBeNull();
  });

  it('returns the Vue component', () => {
    dispatch.mockResolvedValue({});
    const wrapper = createWrapper(mountStatusChecks(el));

    expect(dispatch).toHaveBeenCalledWith('setSettings', { projectId, statusChecksPath });
    expect(dispatch).toHaveBeenCalledWith('fetchStatusChecks');
    expect(wrapper.exists()).toBe(true);
  });

  it('returns the Vue component with an error if fetchStatusChecks fails', async () => {
    const error = new Error('Something went wrong');
    dispatch.mockResolvedValueOnce({});
    dispatch.mockRejectedValueOnce(error);

    const wrapper = createWrapper(mountStatusChecks(el));
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred fetching the status checks.',
      captureError: true,
      error,
    });
    expect(wrapper.exists()).toBe(true);
  });
});
