import { HealthController } from './health.controller.js';

describe('HealthController', () => {
  it('returns a healthy service response', () => {
    const response = new HealthController().getHealth();

    expect(response.status).toBe('ok');
    expect(response.service).toBe('platanitos-backend');
    expect(Number.isNaN(Date.parse(response.timestamp))).toBe(false);
  });
});
