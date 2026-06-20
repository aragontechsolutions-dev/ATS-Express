import { Controller, Get } from '@nestjs/common';

/**
 * Endpoint ligero de keep-alive. NO toca la base de datos, para mantener
 * "despierta" la instancia de Render sin gasto de recursos.
 * cron-job.org hace GET /health cada 10 minutos.
 */
@Controller('health')
export class HealthController {
  @Get()
  check(): { status: string; service: string; timestamp: string } {
    return {
      status: 'ok',
      service: 'ats-express-api',
      timestamp: new Date().toISOString(),
    };
  }
}
