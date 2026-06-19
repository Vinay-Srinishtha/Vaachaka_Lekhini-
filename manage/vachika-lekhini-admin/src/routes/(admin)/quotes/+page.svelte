<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';
	import { toasts } from '$lib/stores/toast';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import SearchInput from '$lib/components/SearchInput.svelte';
	import { PlusCircle, Upload, Download, Pencil, Trash2, Eye, EyeOff, ImageOff } from '@lucide/svelte';
	import { patchQuery } from '$lib/url';

	let { data, form } = $props();

	const deleteId = $derived(page.url.searchParams.get('delete'));
	const target = $derived(deleteId ? data.quotes.find((q: { id: string }) => q.id === deleteId) : null);

	const q = $derived((page.url.searchParams.get('q') ?? '').toLowerCase().trim());
	const visibleQuotes = $derived(
		q ? data.quotes.filter((quote: any) =>
			[quote.text, quote.textRoman, quote.textTelugu, quote.textDevanagari, quote.textKannada,
			 quote.source, quote.sourceRoman, quote.sourceTelugu,
			 quote.mantra?.nameRoman, quote.slug]
			.some(f => (f ?? '').toLowerCase().includes(q))
		) : data.quotes
	);

	function displayText(quote: any): string {
		return quote.textRoman || quote.textTelugu || quote.textDevanagari || quote.textKannada || quote.text || '—';
	}
	function displaySource(quote: any): string {
		return quote.sourceRoman || quote.sourceTelugu || quote.sourceDevanagari || quote.sourceKannada || quote.source || '';
	}
	function langBadges(quote: any): string[] {
		const badges: string[] = [];
		if (quote.textRoman) badges.push('ROM');
		if (quote.textTelugu) badges.push('TEL');
		if (quote.textDevanagari) badges.push('DEV');
		if (quote.textKannada) badges.push('KAN');
		return badges;
	}

	let submitting = $state(false);
	const totalActive = $derived(data.quotes.filter((qt: any) => qt.isActive).length);
	const withImages = $derived(data.quotes.filter((qt: any) => qt.imageUrl).length);
	const universal = $derived(data.quotes.filter((qt: any) => !qt.mantra).length);
	let uploading = $state(false);
	let uploadError = $state('');
	let uploadResult = $state<{ created: number; skipped: number; errors: string[] } | null>(null);

	function close() {
		goto(patchQuery(page.url, { delete: null }), { keepFocus: true, noScroll: true, replaceState: true });
	}

	function downloadTemplate() {
		// Build a CSV template with all active mantra slugs listed in a reference sheet comment
		const mantraSlugs = data.mantras.map((m: { slug: string }) => m.slug).join(' | ');
		const rows = [
			['text_roman', 'source_roman', 'text_telugu', 'source_telugu', 'text_devanagari', 'source_devanagari', 'text_kannada', 'source_kannada', 'mantra_slug', 'image_url'],
			['"Be the change you wish to see"', '— Mahatma Gandhi', '', '', '', '', '', '', '', ''],
			['', '', '"ధర్మో రక్షతి రక్షితః"', '— మహాభారతం', '', '', '', '', 'rama-ashtakam', ''],
		];
		const csvContent = [
			`# mantra_slug must match one of: ${mantraSlugs}`,
			`# Leave mantra_slug blank for a universal quote shown to all users.`,
			`# image_url is optional — add images later via the edit screen.`,
			`# At least one language column (text_roman/text_telugu/text_devanagari/text_kannada) must be filled.`,
			...rows.map((r) => r.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
		].join('\n');
		const blob = new Blob([csvContent], { type: 'text/csv' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = 'quotes-upload-template.csv';
		a.click();
		URL.revokeObjectURL(url);
	}

	async function handleBulkUpload(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		uploadError = '';
		uploadResult = null;
		uploading = true;
		try {
			const formData = new FormData();
			formData.append('file', file);
			const res = await fetch('/api/admin/quotes-bulk', { method: 'POST', body: formData });
			const json = await res.json();
			if (!res.ok) { uploadError = json.error ?? 'Upload failed'; }
			else { uploadResult = json; toasts.show(`Bulk upload: ${json.created} created`); location.reload(); }
		} catch {
			uploadError = 'Network error — please try again.';
		} finally {
			uploading = false;
			input.value = '';
		}
	}
</script>

{#if form?.error}
	<div class="fixed bottom-6 right-6 z-50 max-w-md rounded-lg bg-red-50 text-red-700 border border-red-200 px-4 py-3 text-sm shadow-lg">
		{form.error}
	</div>
{/if}

<form id="quote-delete-form" method="POST" action="?/delete" use:enhance={() => {
	submitting = true;
	const txt = target ? displayText(target) : 'Quote';
	return async ({ result, update }) => {
		await update();
		submitting = false;
		if (result.type === 'redirect' || result.type === 'success') toasts.show(`"${txt.slice(0, 40)}…" deleted`);
	};
}}>
	<input type="hidden" name="id" value={deleteId ?? ''} />
</form>

<ConfirmDialog
	open={!!target}
	title="Delete Quote?"
	message={`This permanently removes "${target ? displayText(target).slice(0, 60) : ''}…".`}
	confirmLabel="Delete"
	{submitting}
	onCancel={close}
	onConfirm={() => { const f = document.getElementById('quote-delete-form') as HTMLFormElement | null; f?.requestSubmit(); }}
/>

<!-- Header -->
<div class="mb-6 flex flex-wrap items-start justify-between gap-4">
	<div>
		<h1 class="text-xl font-semibold text-slate-900">Quotes</h1>
		<p class="mt-1 text-sm text-slate-500">
			{visibleQuotes.length}{q ? ` of ${data.quotes.length}` : ''} quotes ·
			shown on the Flutter home screen · images saved to S3
		</p>
	</div>
</div>

<!-- Stats bar -->
<div class="mb-6 flex flex-wrap gap-3">
	{#each [
		{ label: 'Total', value: data.quotes.length, color: 'bg-slate-100 text-slate-700' },
		{ label: 'Active', value: totalActive, color: 'bg-green-50 text-green-700 border border-green-200' },
		{ label: 'With Images', value: withImages, color: 'bg-sky-50 text-sky-700 border border-sky-200' },
		{ label: 'Universal', value: universal, color: 'bg-indigo-50 text-indigo-700 border border-indigo-200' },
	] as stat}
		<div class="inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-semibold {stat.color}">
			<span class="text-base font-bold">{stat.value}</span>
			<span class="font-normal">{stat.label}</span>
		</div>
	{/each}
</div>

<div class="mb-6 flex flex-wrap items-center justify-end gap-2">
	<!-- Download template -->
	<button onclick={downloadTemplate} class="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors">
		<Download size={15} />
		Template
	</button>

	<!-- Bulk upload -->
	<label class="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer {uploading ? 'opacity-60 pointer-events-none' : ''}">
		<Upload size={15} />
		{uploading ? 'Uploading…' : 'Bulk Upload'}
		<input type="file" accept=".csv,.xlsx,.xls" class="sr-only" onchange={handleBulkUpload} />
	</label>

	<!-- New quote -->
	<a href="/quotes/new" class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">
		<PlusCircle size={16} />
		New Quote
	</a>
</div>

<!-- Bulk upload feedback -->
{#if uploadError}
	<div class="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">{uploadError}</div>
{/if}
{#if uploadResult}
	<div class="mb-4 rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-800 space-y-1">
		<p class="font-medium">Upload complete — {uploadResult.created} created, {uploadResult.skipped} skipped</p>
		{#if uploadResult.errors.length}
			<ul class="list-disc pl-4 space-y-0.5 text-red-700">
				{#each uploadResult.errors as e}<li>{e}</li>{/each}
			</ul>
		{/if}
	</div>
{/if}

<!-- Bulk upload format hint -->
<details class="mb-4 rounded-lg border border-slate-200 bg-slate-50 text-sm">
	<summary class="cursor-pointer px-4 py-2.5 font-medium text-slate-700 select-none">Excel / CSV format guide</summary>
	<div class="px-4 pb-3 pt-1 text-slate-600 space-y-1.5">
		<p>Upload a <strong>.xlsx</strong> or <strong>.csv</strong> file. Download the template above for a ready-to-fill example.</p>
		<table class="w-full text-xs border-collapse mt-2">
			<thead class="bg-slate-100">
				<tr>
					{#each ['Column', 'Required', 'Notes'] as h}
						<th class="border border-slate-200 px-2 py-1 text-left font-semibold text-slate-700">{h}</th>
					{/each}
				</tr>
			</thead>
			<tbody>
				{#each [
					['text_roman', 'At least one*', 'Quote in Roman/English script'],
					['source_roman', 'No', 'Attribution in Roman/English'],
					['text_telugu', 'At least one*', 'Quote in Telugu script'],
					['source_telugu', 'No', 'Attribution in Telugu'],
					['text_devanagari', 'At least one*', 'Quote in Devanagari/Sanskrit script'],
					['source_devanagari', 'No', 'Attribution in Devanagari'],
					['text_kannada', 'At least one*', 'Quote in Kannada script'],
					['source_kannada', 'No', 'Attribution in Kannada'],
					['mantra_slug', 'No', 'Slug of the target mantra (e.g. rama-ashtakam). Leave blank = show to all.'],
					['image_url', 'No', 'Public image URL. Quarantine images can be added later via Edit.'],
				] as [col, req, note]}
					<tr class="even:bg-white">
						<td class="border border-slate-200 px-2 py-1 font-mono text-slate-800">{col}</td>
						<td class="border border-slate-200 px-2 py-1">{req}</td>
						<td class="border border-slate-200 px-2 py-1">{note}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</details>

<div class="mb-4">
	<SearchInput placeholder="Search quotes, source, or mantra…" />
</div>

<!-- Table -->
<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
	{#if visibleQuotes.length === 0}
		<div class="py-16 text-center text-slate-500 text-sm">
			{q ? `No quotes match "${q}"` : 'No quotes yet — create one or bulk upload.'}
		</div>
	{:else}
		<div class="overflow-x-auto">
			<table class="w-full text-sm">
				<thead class="bg-slate-50 border-b border-slate-200">
					<tr>
						{#each ['Quote', 'Source', 'Mantra', 'Image', 'Active', ''] as h}
							<th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">{h}</th>
						{/each}
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-100">
					{#each visibleQuotes as quote (quote.id)}
						{@const badges = langBadges(quote)}
						<tr class="hover:bg-slate-50 transition-colors">
							<!-- Quote text -->
							<td class="px-4 py-3 max-w-xs">
								<p class="line-clamp-2 text-slate-900 font-medium">{displayText(quote)}</p>
								{#if badges.length > 0}
									<div class="mt-1 flex gap-1 flex-wrap">
										{#each badges as badge}
											<span class="inline-block rounded px-1 py-0.5 text-[10px] font-semibold bg-slate-100 text-slate-500">{badge}</span>
										{/each}
									</div>
								{/if}
							</td>
							<!-- Source -->
							<td class="px-4 py-3 text-slate-500 whitespace-nowrap max-w-[140px] truncate">
								{displaySource(quote) || '—'}
							</td>
							<!-- Mantra -->
							<td class="px-4 py-3">
								{#if quote.mantra}
									<span class="inline-flex items-center rounded-full bg-indigo-50 px-2.5 py-0.5 text-xs font-medium text-indigo-700 border border-indigo-200">
										{quote.mantra.nameRoman}
									</span>
								{:else}
									<span class="text-slate-400 text-xs">All users</span>
								{/if}
							</td>
							<!-- Image -->
							<td class="px-4 py-3">
								{#if quote.imageUrl}
									<a href={quote.imageUrl} target="_blank" rel="noopener noreferrer" class="block">
										<img
											src={quote.imageUrl}
											alt=""
											class="h-10 w-16 rounded object-cover border border-slate-200 hover:opacity-80 transition-opacity"
											onerror={(e) => { (e.target as HTMLImageElement).style.display='none'; (e.target as HTMLImageElement).nextElementSibling?.classList.remove('hidden'); }}
										/>
										<span class="hidden text-xs text-slate-400 italic">No preview</span>
									</a>
								{:else}
									<span class="text-slate-300"><ImageOff size={18} /></span>
								{/if}
							</td>
							<!-- Active toggle -->
							<td class="px-4 py-3">
								<form method="POST" action="?/toggleActive" use:enhance={({ cancel }) => {
									return async ({ update }) => update({ reset: false });
								}}>
									<input type="hidden" name="id" value={quote.id} />
									<button type="submit" class="rounded-full p-1 transition-colors {quote.isActive ? 'text-green-600 hover:bg-green-50' : 'text-slate-400 hover:bg-slate-100'}" title={quote.isActive ? 'Active — click to deactivate' : 'Inactive — click to activate'}>
										{#if quote.isActive}<Eye size={16} />{:else}<EyeOff size={16} />{/if}
									</button>
								</form>
							</td>
							<!-- Actions -->
							<td class="px-4 py-3">
								<div class="flex items-center gap-1">
									<a href="/quotes/{quote.id}/edit" class="rounded p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors" title="Edit">
										<Pencil size={15} />
									</a>
									<a href={patchQuery(page.url, { delete: quote.id })} class="rounded p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors" title="Delete">
										<Trash2 size={15} />
									</a>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
