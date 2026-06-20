import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      // Busca el .env local de la app o el de la raíz del monorepo
      envFilePath: ['.env', '../../.env'],
    }),
    PrismaModule,
    HealthModule,
    // Módulos de dominio (Etapa 1+): CatalogModule, OrdersModule, ...
  ],
})
export class AppModule {}
