import { Pool } from 'pg';

let pool: Pool | null = null;

function getPool(): Pool {
    if (!pool) {
        const rawUrl = process.env.POSTGRES_URL ?? '';
        const url = new URL(rawUrl);
        url.searchParams.delete('sslmode');
        const isLocalhost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
        pool = new Pool({
            connectionString: url.toString(),
            ssl: isLocalhost ? false : { rejectUnauthorized: false },
        });
    }
    return pool;
}

function sql(strings: TemplateStringsArray, ...values: unknown[]) {
    let text = '';
    const params: unknown[] = [];
    strings.forEach((str, i) => {
        text += str;
        if (i < values.length) {
            params.push(values[i]);
            text += `$${params.length}`;
        }
    });
    return getPool().query(text, params);
}

export { sql };
export default sql;
