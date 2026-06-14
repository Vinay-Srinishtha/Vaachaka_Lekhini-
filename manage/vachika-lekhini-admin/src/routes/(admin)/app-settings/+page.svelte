<script lang="ts">
	import { enhance } from '$app/forms';

	let { data, form } = $props();

	const s = $derived(form?.settings ?? data.settings);
	const saved = $derived(form?.ok === true);
	const error = $derived(form?.error ?? null);

	const logoUrl = $derived(s.app_logo_url ?? '');
	const hasLogo = $derived(logoUrl.length > 0);
</script>

<div class="mb-6">
	<h1 class="text-xl font-semibold text-slate-900">App Settings</h1>
	<p class="mt-1 text-sm text-slate-500">Global configuration served to the Flutter app at /api/v1/app-settings</p>
</div>

{#if saved}
	<div class="mb-6 rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-700">
		Settings saved successfully.
	</div>
{/if}

{#if error}
	<div class="mb-6 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
		{error}
	</div>
{/if}

<form method="POST" action="?/save" use:enhance class="space-y-6 max-w-2xl">

	<!-- App Logo -->
	<div class="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
		<div>
			<h2 class="text-sm font-semibold text-slate-800">App Logo URL</h2>
			<p class="mt-0.5 text-xs text-slate-500">Optional. A public HTTPS URL to the app logo image (PNG or SVG). Shown in the Flutter app header when set.</p>
		</div>
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="app_logo_url">Logo URL</label>
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
			<div class="pt-1">
				<p class="text-xs text-slate-500 mb-2">Preview:</p>
				<img src={logoUrl} alt="App logo preview" class="h-16 w-auto rounded border border-slate-200 object-contain bg-slate-50 p-1" />
			</div>
		{/if}
	</div>

	<!-- Support Email -->
	<div class="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
		<div>
			<h2 class="text-sm font-semibold text-slate-800">Support Email</h2>
			<p class="mt-0.5 text-xs text-slate-500">Used by the Flutter "Report Issue" screen as the mailto: recipient.</p>
		</div>
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="support_email">Email address</label>
			<input
				id="support_email"
				name="support_email"
				type="email"
				value={s.support_email ?? ''}
				placeholder="support@vaachikalekhini.com"
				class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
			/>
		</div>
	</div>

	<!-- Privacy Policy -->
	<div class="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
		<div>
			<h2 class="text-sm font-semibold text-slate-800">Privacy Policy</h2>
			<p class="mt-0.5 text-xs text-slate-500">Shown in the Flutter app under Settings → Privacy Policy. Supports Markdown formatting.</p>
		</div>
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="privacy_policy">Policy text (Markdown supported)</label>
			<textarea
				id="privacy_policy"
				name="privacy_policy"
				rows="16"
				placeholder="## Privacy Policy&#10;&#10;**Last updated:** June 2026&#10;&#10;..."
				class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm font-mono focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 resize-y"
			>{s.privacy_policy ?? ''}</textarea>
		</div>
	</div>

	<!-- About App -->
	<div class="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
		<div>
			<h2 class="text-sm font-semibold text-slate-800">About App</h2>
			<p class="mt-0.5 text-xs text-slate-500">Shown in the Flutter app under Settings → About App. Supports plain text or Markdown.</p>
		</div>
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="about_app">About text (Markdown supported)</label>
			<textarea
				id="about_app"
				name="about_app"
				rows="10"
				placeholder="## About Vachika Lekhini&#10;&#10;Vachika Lekhini is a spiritual practice app..."
				class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm font-mono focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 resize-y"
			>{s.about_app ?? ''}</textarea>
		</div>
	</div>

	<div class="flex justify-end">
		<button type="submit" class="rounded-lg bg-brand-600 px-5 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">
			Save settings
		</button>
	</div>

</form>
