<script lang="ts">
	import { Upload, X, CheckCircle, Trash2, Music } from '@lucide/svelte';

	interface Props {
		category: 'mantra-audio' | 'store-image' | 'mantra-image';
		targetId: string;
		accept: string;
		buttonLabel: string;
		currentUrl?: string | null;
	}

	let { category, targetId, accept, buttonLabel, currentUrl = null }: Props = $props();

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
			if (!payload?.uploadUrl || !payload?.url || !targetInput) {
				throw new Error('Upload URL was not returned.');
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

	<!-- Existing file preview -->
	{#if existingUrl && !selectedFile}
		<div class="flex items-start gap-3 rounded-lg border border-gray-200 bg-gray-50 p-3">
			{#if isAudio}
				<div class="flex flex-col gap-2 flex-1 min-w-0">
					<div class="flex items-center gap-2 text-sm text-gray-700">
						<Music size={16} class="shrink-0 text-indigo-500" />
						<span class="truncate font-medium">{existingUrl.split('/').pop()}</span>
					</div>
					<!-- svelte-ignore a11y_media_has_caption -->
					<audio controls src={existingUrl} class="w-full h-8 [&::-webkit-media-controls-panel]:bg-gray-100"></audio>
				</div>
			{:else}
				<img
					src={existingUrl}
					alt="Current"
					class="h-20 w-20 rounded object-cover border border-gray-200 shrink-0"
				/>
				<div class="flex-1 min-w-0">
					<p class="text-xs text-gray-500 truncate">{existingUrl.split('/').pop()}</p>
				</div>
			{/if}
			<button
				type="button"
				class="btn-secondary shrink-0 text-red-600 border-red-200 hover:bg-red-50"
				onclick={removeExisting}
				disabled={removing}
				title="Remove file"
			>
				<Trash2 size={14} />
				{removing ? 'Removing…' : 'Remove'}
			</button>
		</div>
	{/if}

	<!-- Drop zone (hidden when existing file shown and no new file chosen) -->
	{#if !existingUrl || selectedFile}
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			class="relative flex flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed px-4 py-6 text-center transition-colors cursor-pointer
				{dragOver
					? 'border-indigo-400 bg-indigo-50'
					: selectedFile
						? 'border-green-400 bg-green-50'
						: 'border-gray-300 bg-gray-50 hover:border-gray-400 hover:bg-gray-100'}"
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
				<CheckCircle size={24} class="text-green-500" />
				<p class="text-sm font-medium text-green-700 truncate max-w-full">{selectedFile.name}</p>
				<p class="text-xs text-green-500">{(selectedFile.size / 1024).toFixed(0)} KB</p>
			{:else}
				<Upload size={24} class="text-gray-400" />
				<p class="text-sm text-gray-600">
					<span class="font-medium text-indigo-600">Click to browse</span> or drag & drop
				</p>
				<p class="text-xs text-gray-400">{accept}</p>
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

	<!-- Replace button shown alongside existing preview -->
	{#if existingUrl && !selectedFile}
		<button
			type="button"
			class="btn-secondary w-full"
			onclick={() => fileInput?.click()}
		>
			<Upload size={16} />
			Replace {isAudio ? 'audio' : 'image'}
		</button>
		<input
			bind:this={fileInput}
			type="file"
			accept={accept}
			class="sr-only"
			onchange={onFileChange}
		/>
	{/if}

	<!-- Actions row when a new file is staged -->
	{#if selectedFile}
		<div class="flex gap-2">
			<button
				type="button"
				class="btn-primary flex-1"
				onclick={upload}
				disabled={uploading}
			>
				<Upload size={16} />
				{uploading ? 'Uploading…' : buttonLabel}
			</button>
			<button type="button" class="btn-secondary px-3" onclick={clearNewFile} title="Cancel">
				<X size={16} />
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
