import { sql } from '@/lib/db';
import { decrypt } from '@/lib/encryption';
import { NextRequest } from 'next/server';

export async function GET(
    _req: NextRequest,
    { params }: { params: Promise<{ slug: string }> }
) {
    const { slug } = await params;

    try {
        const result = await sql`
            SELECT url, expires_at FROM redirects WHERE id = ${slug}
        `;

        if (result.rows.length === 0) {
            return new Response('Not found', { status: 404 });
        }

        const row = result.rows[0];

        if (row.expires_at && new Date(row.expires_at) < new Date()) {
            return new Response('Link expired', { status: 410 });
        }

        const destinationUrl = decrypt(row.url);

        return Response.redirect(destinationUrl, 302);
    } catch (error) {
        console.error('Redirect error:', error);
        return new Response('Internal server error', { status: 500 });
    }
}
