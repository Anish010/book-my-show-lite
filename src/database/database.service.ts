import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { Pool, PoolClient, QueryConfig, QueryResult, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {

    private readonly logger = new Logger(DatabaseService.name);

    private readonly pool: Pool;

    constructor(private readonly configService: ConfigService) {
        this.pool = new Pool({
            connectionString: this.configService.getOrThrow<string>('DATABASE_URL'),
            max: 10,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 5000,
        });

        this.pool.on('error', (err) => {
            this.logger.error( 'Unexpected PostgreSQL pool error', err.stack);
        });
    }

    async onModuleInit() {
        await this.pool.query('SELECT 1');

        this.logger.log('PostgreSQL connection established successfully');
    }

    query<T extends QueryResultRow = QueryResultRow>(text: string, values?: QueryConfig['values']): Promise<QueryResult<T>> {
        return this.pool.query<T>(text, values);
    }

    getClient(): Promise<PoolClient> {
        return this.pool.connect();
    }

    async onModuleDestroy() {
        await this.pool.end();

        this.logger.log('PostgreSQL connection closed successfully');
    }
}
