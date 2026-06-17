<script lang="ts">
	import { Upload, X, CheckCircle, Trash2, Music } from '@lucide/svelte';

	interface Props {
		category: 'mantra-audio' | 'store-image' | 'mantra-image' | 'mantra-preview';
		targetId: string;
		accept: string;
		buttonLabel: string;
		currentUrl?: string | null;
		onUrlChange?: (url: string | null) => void;
	}

	let { category, targetId, accept, buttonLabel, currentUrl = null, onUrlChange }: Props = $props();

	const isAudio = category === 'mantra-audio';

	let fileInput = $state<HTMLInputElement>();
	let uploading = $state(false);
	let removing = $state(false);
	let message = $state('');
	let errorMessage = $state('');
	let dragOver = $state(false);
	let selectedFile = $state<File | null>(null);

	// existingUrl tracks what's actually linked in DB (shown as preview).
	// Starts from currentUrl; cleared when the user removes it.
	let existingUrl = $state(currentUrl ?? null);

	$effect(() => {
		existingUrl = currentUrl ?? null;
	});

	const acceptedTypes = accept.split(',').map((s) => s.trim());

	function isAccepted(file: File) {
		return acceptedTypes.some((t) => {
			if (t.endsWith('/*')) return file.type.startsWith(t.slice(0, -1));
			return file.type === t;
		});
	}

	function pickFile(file: File) {
		if (!isAccepted(file)) {
			errorMessage = `File type not allowed. Accepted: ${accept}`;
			return;
		}
		errorMessage = '';
		message = '';
		selectedFile = file;
	}

	function onDragOver(e: DragEvent) {
		e.preventDefault();
		dragOver = true;
	}

	function onDragLeave() {
		dragOver = false;
	}

	function onDrop(e: DragEvent) {
		e.preventDefault();
		dragOver = false;
		const file = e.dataTransfer?.files?.[0];
		if (file) pickFile(file);
	}

	function onFileChange() {
		const file = fileInput?.files?.[0];
		if (file) pickFile(file);
	}

	function clearNewFile() {
		selectedFile = null;
		message = '';
		errorMessage = '';
		if (fileInput) fileInput.value = '';
	}

	function getTargetInput(form: HTMLFormElement | null | undefined) {
		return form?.querySelector<HTMLInputElement>(`#${targetId}`) ?? null;
	}

	async function removeExisting() {
		if (!existingUrl) return;
		removing = true;
		errorMessage = '';
		try {
			const res = await fetch('/api/admin/upload', {
				method: 'DELETE',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ url: existingUrl })
			});
			if (!res.ok) {
				const payload = await res.json().catch(() => null);
				throw new Error(payload?.message ?? 'Failed to remove file.');
			}
			// Clear the hidden input so the form saves null to DB
			const form = fileInput?.closest('form');
			const targetInput = getTargetInput(form);
			if (targetInput) {
				targetInput.value = '';
				targetInput.dispatchEvent(new Event('input', { bubbles: true }));
			}
			existingUrl = null;
			onUrlChange?.(null);
			message = 'File removed. Save the form to apply.';
		} catch (err) {
			errorMessage = err instanceof Error ? err.message : 'Remove failed.';
		} finally {
			removing = false;
		}
	}

	async function upload() {
		if (!selectedFile) {
			errorMessage = 'Choose or drop a file first.';
			return;
		}

		const form = fileInput?.closest('form');
		const slugInput = form?.querySelector<HTMLInputElement>('[name="slug"]');
		const targetInput = getTargetInput(form);

		uploading = true;
		errorMessage = '';

		// If there's still an existing file linked, delete it from S3 first
		const oldUrl = existingUrl;

		try {
			if (oldUrl) {
				await fetch('/api/admin/upload', {
					method: 'DELETE',
					headers: { 'content-type': 'application/json' },
					body: JSON.stringify({ url: oldUrl })
				});
				// Continue even if S3 delete fails — new file upload is more important
			}

			const res = await fetch('/api/admin/upload', {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({
					category,
					slug: slugInput?.value ?? '',
					fileName: selectedFile.name,
					contentType: selectedFile.type,
					size: selectedFile.size
				})
			});
			const payload = await res.json().catch(() => null);
			if (!res.ok) throw new Error(payload?.message ?? payload?.error ?? 'Upload failed.');
			if (!payload?.uploadUrl || !payload?.url) {
				throw new Error('Upload URL was not returned.');
			}
			if (!targetInput) {
				throw new Error(`Target input #${targetId} not found in form.`);
			}

			const uploadRes = await fetch(payload.uploadUrl, {
				method: 'PUT',
				headers: payload.headers ?? { 'content-type': selectedFile.type },
				body: selectedFile
			});
			if (!uploadRes.ok) throw new Error('S3 upload failed. Check bucket CORS and permissions.');

			targetInput.value = payload.url;
			targetInput.dispatchEvent(new Event('input', { bubbles: true }));
			existingUrl = payload.url;
			onUrlChange?.(payload.url);
			selectedFile = null;
			if (fileInput) fileInput.value = '';
			message = 'Uploaded. Save this form to publish it.';
		} catch (err) {
			errorMessage = err instanceof Error ? err.message : 'Upload failed.';
		} finally {
			uploading = false;
		}
	}
</script>

<div class="mt-2 space-y-3">

	<!-- ── Existing file preview ─────────────────────────────────────── -->
	{#if existingUrl && !selectedFile}
		{#if isAudio}
			<!-- Audio: filename + native player + actions -->
			<div class="rounded-xl border border-slate-200 bg-slate-50 p-3 space-y-2">
				<div class="flex items-center gap-2 text-sm text-slate-700">
					<Music size={15} class="shrink-0 text-indigo-500" />
					<span class="truncate font-medium flex-1 min-w-0">{existingUrl.split('/').pop()}</span>
				</div>
				<!-- svelte-ignore a11y_media_has_caption -->
				<audio controls src={existingUrl} class="w-full h-9 rounded"></audio>
				<div class="flex gap-2 pt-1">
					<button
						type="button"
						class="btn-secondary flex-1"
						onclick={() => fileInput?.click()}
					>
						<Upload size={14} /> Replace audio
					</button>
					<button
						type="button"
						class="btn-secondary px-3 text-red-600 border-red-200 hover:bg-red-50"
						onclick={removeExisting}
						disabled={removing}
						title="Remove"
					>
						<Trash2 size={14} />
						{removing ? '…' : 'Remove'}
					</button>
				</div>
			</div>
		{:else}
			<!-- Image: full-width preview + replace / remove -->
			<div class="rounded-xl border border-slate-200 bg-slate-50 overflow-hidden">
				<div class="relative group">
					<img
						src={existingUrl}
						alt="Current"
						class="w-full object-cover"
						style="max-height: 220px;"
					/>
					<!-- hover overlay with quick actions -->
					<div class="absolute inset-0 bg-black/0 group-hover:bg-black/30 transition-colors flex items-center justify-center gap-3 opacity-0 group-hover:opacity-100">
						<button
							type="button"
							class="flex items-center gap-1.5 rounded-lg bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700 shadow hover:bg-white transition"
							onclick={() => fileInput?.click()}
						>
							<Upload size={13} /> Replace
						</button>
						<button
							type="button"
							class="flex items-center gap-1.5 rounded-lg bg-red-600/90 px-3 py-1.5 text-xs font-semibold text-white shadow hover:bg-red-600 transition"
							onclick={removeExisting}
							disabled={removing}
						>
							<Trash2 size={13} />
							{removing ? 'Removing…' : 'Remove'}
						</button>
					</div>
				</div>
				<!-- filename + explicit action buttons below the image -->
				<div class="px-3 py-2 border-t border-slate-100 flex items-center gap-2">
					<p class="text-xs text-slate-400 truncate flex-1 min-w-0">{existingUrl.split('/').pop()}</p>
					<button
						type="button"
						class="btn-secondary py-1 px-2.5 text-xs"
						onclick={() => fileInput?.click()}
					>
						<Upload size={12} /> Replace
					</button>
					<button
						type="button"
						class="btn-secondary py-1 px-2.5 text-xs text-red-600 border-red-200 hover:bg-red-50"
						onclick={removeExisting}
						disabled={removing}
					>
						<Trash2 size={12} />
						{removing ? '…' : 'Remove'}
					</button>
				</div>
			</div>
		{/if}

		<!-- Hidden input for replace flow (shared for audio and image) -->
		<input
			bind:this={fileInput}
			type="file"
			accept={accept}
			class="sr-only"
			onchange={onFileChange}
		/>
	{/if}

	<!-- ── Drop zone — shown when no existing file, or staging a new one ── -->
	{#if !existingUrl || selectedFile}
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			class="relative flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed px-4 py-8 text-center transition-colors cursor-pointer
				{dragOver
					? 'border-indigo-400 bg-indigo-50'
					: selectedFile
						? 'border-green-400 bg-green-50'
						: 'border-slate-300 bg-slate-50 hover:border-slate-400 hover:bg-slate-100'}"
			ondragover={onDragOver}
			ondragleave={onDragLeave}
			ondrop={onDrop}
			onclick={() => fileInput?.click()}
			onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && fileInput?.click()}
			role="button"
			tabindex="0"
			aria-label="Upload file"
		>
			{#if selectedFile}
				<CheckCircle size={26} class="text-green-500" />
				<p class="text-sm font-semibold text-green-700 truncate max-w-full">{selectedFile.name}</p>
				<p class="text-xs text-green-500">{(selectedFile.size / 1024).toFixed(0)} KB — ready to upload</p>
			{:else}
				<Upload size={26} class="text-slate-400" />
				<p class="text-sm text-slate-600">
					<span class="font-semibold text-indigo-600">Click to browse</span> or drag & drop
				</p>
				<p class="text-xs text-slate-400">{accept}</p>
			{/if}

			<input
				bind:this={fileInput}
				type="file"
				accept={accept}
				class="sr-only"
				onchange={onFileChange}
			/>
		</div>
	{/if}

	<!-- ── Upload / cancel when a new file is staged ─────────────────── -->
	{#if selectedFile}
		<div class="flex gap-2">
			<button
				type="button"
				class="btn-primary flex-1"
				onclick={upload}
				disabled={uploading}
			>
				<Upload size={15} />
				{uploading ? 'Uploading…' : buttonLabel}
			</button>
			<button type="button" class="btn-secondary px-3" onclick={clearNewFile} title="Cancel">
				<X size={15} />
			</button>
		</div>
	{/if}

	{#if message}
		<p class="text-xs text-green-700">{message}</p>
	{/if}
	{#if errorMessage}
		<p class="text-xs text-red-700">{errorMessage}</p>
	{/if}
</div>
