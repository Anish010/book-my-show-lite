import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { DatabaseService } from './database/database.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService, private readonly databaseService: DatabaseService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health/database')
  async checkDatabase() {

    const result = await this.databaseService.query<{
      current_time: string;
      database_name: string;
    }>(
      `SELECT
        NOW()::text AS current_time,
        current_database() AS database_name`
    );

    return {
      success: true,
      database: result.rows[0],
    };
  }
}
