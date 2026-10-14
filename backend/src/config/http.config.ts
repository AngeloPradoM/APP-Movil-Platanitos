import { ConfigService } from '@nestjs/config';

export function httpConfig(config: ConfigService) {
  const port = Number(config.get<string>('PORT', '3000'));
  const host = config.get<string>('HOST', '127.0.0.1');
  const allowedOrigins = config
    .get<string>('CORS_ORIGINS', 'http://localhost:8080,http://127.0.0.1:8080')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const isDevelopment = config.get<string>('NODE_ENV', 'development') !== 'production';
  const allowLocalhost = config.get<string>('CORS_ALLOW_LOCALHOST', isDevelopment ? 'true' : 'false') === 'true';

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535');
  }

  const cors = {
    origin: (origin: string | undefined, callback: (error: Error | null, allow?: boolean) => void) => {
      if (!origin) return callback(null, true);
      const isLocalFlutterOrigin = allowLocalhost && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
      callback(null, allowedOrigins.includes(origin) || isLocalFlutterOrigin);
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token'],
  };
  return { port, host, cors };
}
