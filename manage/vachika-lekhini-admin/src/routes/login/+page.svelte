<script lang="ts">
	import { enhance } from '$app/forms';
	import { LogIn } from '@lucide/svelte';

	let { form } = $props();
	let submitting = $state(false);
</script>

<svelte:head>
	<title>Sign in · Vaachaka Lekhini Admin</title>
</svelte:head>

<div class="min-h-screen grid place-items-center px-4 bg-gradient-to-br from-brand-50 to-orange-100">
	<div class="w-full max-w-md">
		<div class="flex flex-col items-center mb-6">
			<div class="w-14 h-14 rounded-2xl bg-brand-600 text-white grid place-items-center text-2xl font-bold shadow-lg">
				ॐ
			</div>
			<h1 class="mt-4 text-2xl font-bold text-gray-900">Vaachaka Lekhini Admin</h1>
			<p class="text-sm text-gray-600">Sign in to manage Vaachaka Lekhini</p>
		</div>

		<div class="card p-6">
			<form
				method="POST"
				use:enhance={() => {
					submitting = true;
					return async ({ update }) => {
						await update();
						submitting = false;
					};
				}}
				class="space-y-4"
			>
				<div>
					<label class="label" for="username">Username</label>
					<input
						id="username"
						name="username"
						type="text"
						autocomplete="username"
						class="input"
						value={form?.username ?? ''}
						required
					/>
				</div>
				<div>
					<label class="label" for="password">Password</label>
					<input
						id="password"
						name="password"
						type="password"
						autocomplete="current-password"
						class="input"
						required
					/>
				</div>

				{#if form?.error}
					<div class="text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
						{form.error}
					</div>
				{/if}

				<button type="submit" class="btn-primary w-full" disabled={submitting}>
					<LogIn size={16} />
					{submitting ? 'Signing in…' : 'Sign in'}
				</button>
			</form>
		</div>

		<p class="text-center text-xs text-gray-500 mt-4">
			Default credentials are seeded; change them after first login.
		</p>
	</div>
</div>
