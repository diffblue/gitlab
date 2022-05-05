import Tracking from '~/tracking';

describe('EnableFormTracking', () => {
  let formTrackingSpy;

  beforeEach(() => {
    formTrackingSpy = jest
      .spyOn(Tracking, 'enableFormTracking')
      .mockImplementation(() => null);
  });

  it('initialized with the correct configuration', () => {
    expect(formTrackingSpy).toHaveBeenCalledWith({
      forms: { allow: ['new_user'] },
    });
  });
});
