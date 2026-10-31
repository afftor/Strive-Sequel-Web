// Counts unique players: the loading page (web/web_loading_shell.html) posts
// the browser's anonymous ID once per page load, and each ID is stored at most
// once per day (see ../../schema.sql).

const ID_PATTERN = /^[0-9a-f-]{36}$/;

export async function onRequestPost({ request, env }) {
	const text = await request.text();
	if (text.length > 1024) {
		return new Response(null, { status: 413 });
	}
	let body;
	try {
		body = JSON.parse(text);
	} catch {
		return new Response(null, { status: 400 });
	}
	const player = String(body && body.player);
	if (!ID_PATTERN.test(player) || !env.STATS) {
		return new Response(null, { status: 400 });
	}
	const source = String(body.source || "direct").toLowerCase().replace(/[^a-z0-9.-]/g, "").slice(0, 100) || "direct";
	const country = (request.cf && request.cf.country) || null;
	const day = new Date().toISOString().slice(0, 10);
	await env.STATS.prepare("INSERT OR IGNORE INTO visits (day, player_id, country, source) VALUES (?1, ?2, ?3, ?4)")
		.bind(day, player, country, source)
		.run();
	return new Response(null, { status: 204 });
}
