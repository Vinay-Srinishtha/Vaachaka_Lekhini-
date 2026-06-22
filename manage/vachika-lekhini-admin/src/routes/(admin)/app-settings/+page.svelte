<script lang="ts">
	import { enhance } from '$app/forms';
	import MediaUploadField from '$lib/components/MediaUploadField.svelte';

	let { data, form } = $props();

	const s = $derived(form?.settings ?? data.settings);
	const saved = $derived(form?.ok === true);
	const error = $derived(form?.error ?? null);

	const logoUrl = $derived(s.app_logo_url ?? '');
	const hasLogo = $derived(logoUrl.length > 0);

	let shareQuoteImageUrl = $state<string>(s.share_quote_image_url ?? '');
	$effect.pre(() => { shareQuoteImageUrl = s.share_quote_image_url ?? ''; });

	let bulletinMode = $state<string>(s.bulletin_mode ?? 'custom_text');
	$effect.pre(() => { bulletinMode = s.bulletin_mode ?? 'custom_text'; });

	const shareQuoteTextPlaceholder = [
		'"{quote}"',
		'— {attribution}',
		'',
		'Shared via Vachika Lekhini 🙏',
		'{app_link}'
	].join('\n');
</script>

<!-- Header + Save -->
<div class="mb-8 flex items-start justify-between gap-4">
	<div>
		<h1 class="text-2xl font-bold text-slate-900">App Settings</h1>
		<p class="mt-1 text-sm text-slate-500">Global configuration served to the Flutter app at <code class="rounded bg-slate-100 px-1.5 py-0.5 font-mono text-xs text-slate-600">/api/v1/app-settings</code></p>
	</div>
	<div class="flex shrink-0 items-center gap-3">
		{#if saved}
			<span class="flex items-center gap-1.5 text-sm text-green-700">
				<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd"/></svg>
				Saved
			</span>
		{/if}
		{#if error}
			<span class="flex items-center gap-1.5 text-sm text-red-700">
				<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd"/></svg>
				{error}
			</span>
		{/if}
		<button type="submit" form="app-settings-form" class="rounded-lg bg-brand-600 px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700 transition-colors">
			Save settings
		</button>
	</div>
</div>

<form id="app-settings-form" method="POST" action="?/save" use:enhance>

	<!-- ── Two-column grid ───────────────────────────────────────────────── -->
	<div class="grid grid-cols-1 gap-6 xl:grid-cols-2 h-full">

		<!-- LEFT column: App Logo + Privacy Policy -->
		<div class="flex flex-col gap-6 min-h-0">

			<!-- App Logo -->
			<div class="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
				<div class="flex items-start gap-3">
					<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-violet-50 text-violet-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5M3.75 3.75h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6a2.25 2.25 0 0 1 2.25-2.25z"/></svg>
					</span>
					<div>
						<h2 class="text-sm font-semibold text-slate-800">App Logo URL</h2>
						<p class="mt-0.5 text-xs text-slate-500">Public HTTPS URL to the app logo (PNG or SVG). Shown in the Flutter app header when set.</p>
					</div>
				</div>

				<div>
					<label class="mb-1 block text-xs font-medium text-slate-600" for="app_logo_url">Logo URL</label>
					<input
						id="app_logo_url"
						name="app_logo_url"
						type="url"
						value={s.app_logo_url ?? ''}
						placeholder="https://cdn.example.com/logo.png"
						class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
					/>
				</div>

				{#if hasLogo}
					<div class="flex items-center gap-4 rounded-xl bg-slate-50 border border-slate-200 p-4">
						<img src={logoUrl} alt="App logo preview" class="h-14 w-auto rounded-lg border border-slate-200 bg-white object-contain p-1 shadow-sm" />
						<div>
							<p class="text-xs font-medium text-slate-600">Preview</p>
							<p class="mt-0.5 text-xs text-slate-400 break-all">{logoUrl}</p>
						</div>
					</div>
				{/if}
			</div>

			<!-- Privacy Policy -->
			<div class="flex flex-1 flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
				<div class="flex items-start gap-3">
					<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"/></svg>
					</span>
					<div>
						<h2 class="text-sm font-semibold text-slate-800">Privacy Policy</h2>
						<p class="mt-0.5 text-xs text-slate-500">Shown in Settings → Privacy Policy. Supports Markdown formatting.</p>
					</div>
				</div>
				<div class="flex flex-1 flex-col">
					<label class="mb-1 block text-xs font-medium text-slate-600" for="privacy_policy">Policy text <span class="text-slate-400">(Markdown supported)</span></label>
					<textarea
						id="privacy_policy"
						name="privacy_policy"
						rows="20"
						placeholder="## Privacy Policy&#10;&#10;**Last updated:** June 2026&#10;&#10;..."
						class="flex-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm font-mono focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 resize-y"
					>{s.privacy_policy ?? ''}</textarea>
				</div>
			</div>

		</div>

		<!-- RIGHT column: App Link + Invite Host + About App -->
		<div class="flex flex-col gap-6 min-h-0">

			<!-- App Link -->
			<div class="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
				<div class="flex items-start gap-3">
					<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-orange-50 text-orange-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 8.25h3m-3 3h3m-3 3h3"/></svg>
					</span>
					<div>
						<h2 class="text-sm font-semibold text-slate-800">App Link</h2>
						<p class="mt-0.5 text-xs text-slate-500">Public URL where users can download the app. Used in share messages, invite links, and the API.</p>
					</div>
				</div>
				<div>
					<label class="mb-1 block text-xs font-medium text-slate-600" for="app_link">App URL</label>
					<input
						id="app_link"
						name="app_link"
						type="url"
						value={s.app_link ?? 'https://vaachika-lekhani.vercel.app'}
						placeholder="https://vaachika-lekhani.vercel.app"
						class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
					/>
					<p class="mt-1.5 text-[10px] text-slate-400">Exposed in the Flutter app as <code class="bg-slate-100 px-1 rounded">app_link</code> and used as the <code class="bg-slate-100 px-1 rounded">{'{app_link}'}</code> placeholder in share templates.</p>
				</div>
			</div>

			<!-- Invite Host -->
			<div class="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
				<div class="flex items-start gap-3">
					<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-emerald-50 text-emerald-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244"/></svg>
					</span>
					<div>
						<h2 class="text-sm font-semibold text-slate-800">Invite Host</h2>
						<p class="mt-0.5 text-xs text-slate-500">Base domain for invite links sent to referred friends. Used when building the share URL.</p>
					</div>
				</div>
				<div>
					<label class="mb-1 block text-xs font-medium text-slate-600" for="invite_host">Domain</label>
					<div class="flex rounded-lg border border-slate-300 overflow-hidden focus-within:border-brand-500 focus-within:ring-1 focus-within:ring-brand-500">
						<span class="flex items-center bg-slate-50 px-3 text-sm text-slate-500 border-r border-slate-300">https://</span>
						<input
							id="invite_host"
							name="invite_host"
							type="text"
							value={s.invite_host ?? 'vaachakalekhini.com'}
							placeholder="vaachakalekhini.com"
							class="flex-1 px-3 py-2 text-sm focus:outline-none"
						/>
					</div>
				</div>
			</div>

			<!-- About App -->
			<div class="flex flex-1 flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
				<div class="flex items-start gap-3">
					<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-rose-50 text-rose-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zm-9-3.75h.008v.008H12V8.25z"/></svg>
					</span>
					<div>
						<h2 class="text-sm font-semibold text-slate-800">About App</h2>
						<p class="mt-0.5 text-xs text-slate-500">Shown in Settings → About App. Supports plain text or Markdown.</p>
					</div>
				</div>
				<div class="flex flex-1 flex-col">
					<label class="mb-1 block text-xs font-medium text-slate-600" for="about_app">About text <span class="text-slate-400">(Markdown supported)</span></label>
					<textarea
						id="about_app"
						name="about_app"
						rows="16"
						placeholder="## About Vachika Lekhini&#10;&#10;Vachika Lekhini is a spiritual practice app..."
						class="flex-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm font-mono focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 resize-y"
					>{s.about_app ?? ''}</textarea>
				</div>
			</div>

		</div>

	</div>

	<!-- ── Share Settings (full-width row below the 2-col grid) ─────────────── -->
	<div class="mt-6 rounded-2xl border border-green-200 bg-white p-6 shadow-sm">
		<div class="flex items-start gap-3 mb-5">
			<span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-green-50 text-green-600">
				<svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0 0a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186zm0-12.814a2.25 2.25 0 1 0 3.933-2.185 2.25 2.25 0 0 0-3.933 2.185z"/>
				</svg>
			</span>
			<div>
				<h2 class="text-sm font-semibold text-slate-800">Share Settings</h2>
				<p class="mt-0.5 text-xs text-slate-500">
					Configure the WhatsApp / social share format for the <strong>daily quote card</strong> and set the global <strong>app download link</strong> used in all share messages.
				</p>
			</div>
		</div>

		<div class="grid grid-cols-1 gap-6 xl:grid-cols-3">

			<!-- App Download Link -->
			<div class="flex flex-col gap-2">
				<label class="text-xs font-semibold text-slate-700" for="app_download_link">App Download Link</label>
				<p class="text-xs text-slate-400">Inserted as <code class="bg-slate-100 px-1 rounded">{'{app_link}'}</code> in every share message template.</p>
				<input
					id="app_download_link"
					name="app_download_link"
					type="url"
					value={s.app_download_link ?? ''}
					placeholder="https://vaachika-lekhani.vercel.app"
					class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500"
				/>
				<p class="text-[10px] text-slate-400">Use a universal link that redirects to Play Store / App Store.</p>
			</div>

			<!-- Quote Share Image -->
			<div class="flex flex-col gap-2">
				<p class="text-xs font-semibold text-slate-700">Quote Share Image</p>
				<p class="text-xs text-slate-400">Image attached when the user shares the daily quote card on WhatsApp.</p>
				<MediaUploadField
					category="share-quote"
					targetId="share_quote_image_url"
					accept="image/*"
					buttonLabel={shareQuoteImageUrl ? 'Replace image' : 'Upload image'}
					currentUrl={shareQuoteImageUrl || null}
					onUrlChange={(url) => { shareQuoteImageUrl = url ?? ''; }}
				/>
				<input type="hidden" id="share_quote_image_url" name="share_quote_image_url" value={shareQuoteImageUrl} />
				{#if shareQuoteImageUrl}
					<img src={shareQuoteImageUrl} alt="Quote share preview" class="mt-1 h-20 w-auto rounded-lg border border-slate-200 object-cover shadow-sm" />
				{/if}
			</div>

			<!-- Quote Share Text Template -->
			<div class="flex flex-col gap-2">
				<label class="text-xs font-semibold text-slate-700" for="share_quote_text">Quote Share Message Template</label>
				<p class="text-xs text-slate-400">The text sent when sharing the daily quote. Leave blank for the default.</p>
				<textarea
					id="share_quote_text"
					name="share_quote_text"
					rows="5"
					placeholder={shareQuoteTextPlaceholder}
					class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm font-mono focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500 resize-none"
				>{s.share_quote_text ?? ''}</textarea>
				<p class="text-[10px] text-slate-400 leading-relaxed">
					Placeholders:
					<code class="bg-slate-100 px-1 rounded">{'{quote}'}</code>
					<code class="bg-slate-100 px-1 rounded">{'{attribution}'}</code>
					<code class="bg-slate-100 px-1 rounded">{'{app_link}'}</code>
				</p>
			</div>

		</div>
	</div>

	<!-- ── Home Bulletin (scrolling banner) ───────────────────────────────── -->
	<div class="mt-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
		<h2 class="text-sm font-semibold text-slate-800">Home Bulletin</h2>
		<p class="mt-1 text-xs text-slate-500">The scrolling banner on the app's home screen.</p>

		<div class="mt-4 flex flex-col gap-3">
			<label class="flex items-start gap-3 rounded-xl border p-3 cursor-pointer {bulletinMode === 'custom_text' ? 'border-brand-500 bg-brand-50' : 'border-slate-200'}">
				<input type="radio" name="bulletin_mode" value="custom_text" bind:group={bulletinMode} class="mt-0.5" />
				<span>
					<span class="block text-sm font-medium text-slate-800">Custom text</span>
					<span class="block text-xs text-slate-500">Show the exact message you type below.</span>
				</span>
			</label>
			<label class="flex items-start gap-3 rounded-xl border p-3 cursor-pointer {bulletinMode === 'stats' ? 'border-brand-500 bg-brand-50' : 'border-slate-200'}">
				<input type="radio" name="bulletin_mode" value="stats" bind:group={bulletinMode} class="mt-0.5" />
				<span>
					<span class="block text-sm font-medium text-slate-800">App stats (auto)</span>
					<span class="block text-xs text-slate-500">Live summary: total chants, programs, writings, rewards redeemed, devotees, and per-active-mantra global chants. Updates automatically.</span>
				</span>
			</label>
		</div>

		{#if bulletinMode === 'custom_text'}
			<div class="mt-4 flex flex-col gap-1.5">
				<label class="text-xs font-semibold text-slate-700" for="bulletin_text">Bulletin message</label>
				<textarea
					id="bulletin_text"
					name="bulletin_text"
					rows="2"
					class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
					placeholder="🕉 Join Global Sadhanas • Chant Together, Grow Together"
				>{s.bulletin_text ?? ''}</textarea>
				<p class="text-[10px] text-slate-400">Separate items with • for a clean scrolling look.</p>
			</div>
		{:else}
			<input type="hidden" name="bulletin_text" value={s.bulletin_text ?? ''} />
			<p class="mt-4 rounded-lg bg-slate-50 border border-slate-200 px-3 py-2 text-xs text-slate-500">
				Stats mode is on — the banner text is generated automatically from live app data. Inactive mantras are never shown.
			</p>
		{/if}
	</div>

</form>
