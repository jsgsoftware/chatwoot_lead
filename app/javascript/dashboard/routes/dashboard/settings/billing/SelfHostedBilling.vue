<script setup>
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import BillingCard from './components/BillingCard.vue';
import ButtonV4 from 'next/button/Button.vue';

const plan = {
	name: 'Growth Plus',
	price: '$49 / month',
	renewal: 'Renews on Jan 12, 2026',
	status: 'Active',
	managedBy: 'Managed by PayPal / Google Pay',
};

const usageMetrics = [
	{
		label: 'Conversations',
		value: '8,120',
		limit: '10,000',
		percent: 81,
	},
	{
		label: 'Active agents',
		value: '6',
		limit: '10',
		percent: 60,
	},
	{
		label: 'AI automations',
		value: '3,240',
		limit: '5,000',
		percent: 65,
	},
];

const quickActions = [
	{
		title: 'Upgrade plan',
		description: 'Compare LeadFlowAI tiers and unlock higher limits.',
		cta: 'Upgrade plan',
	},
	{
		title: 'View invoices',
		description: 'Review and download past LeadFlowAI invoices.',
		cta: 'View invoices',
	},
	{
		title: 'Manage subscription',
		description: 'Open PayPal or Google Pay to update your subscription.',
		cta: 'Manage subscription',
	},
];

const billingHistory = [
	{
		date: 'Feb 27, 2025',
		plan: 'Growth Plus',
		amount: '$49.00',
		status: 'Paid',
		provider: 'PayPal',
	},
	{
		date: 'Jan 3, 2025',
		plan: 'Growth Plus',
		amount: '$49.00',
		status: 'Paid',
		provider: 'Google Pay',
	},
	{
		date: 'Sep 14, 2024',
		plan: 'Growth Plus',
		amount: '$45.00',
		status: 'Paid',
		provider: 'PayPal',
	},
	{
		date: 'Feb 1, 2024',
		plan: 'Starter',
		amount: '$29.00',
		status: 'Paid',
		provider: 'Google Pay',
	},
];
</script>

<template>
	<SettingsLayout>
		<template #header>
			<BaseSettingsHeader
				title="LeadFlowAI Billing"
				description="Review your subscription details, usage, and invoice history. All payments are processed securely through PayPal or Google Pay."
				feature-name="billing"
			/>
		</template>

		<template #body>
			<div class="flex flex-col gap-6 text-n-slate-12">
				<BillingCard
					title="Current plan"
					description="Your LeadFlowAI subscription is active and renews automatically each month."
				>
					<div class="flex flex-col gap-4 px-5 pb-5 sm:flex-row sm:items-center sm:justify-between">
						<div class="space-y-2">
							<p class="text-lg font-semibold text-white">
								{{ plan.name }}
							</p>
							<p class="text-sm text-n-slate-10">
								{{ plan.price }} · {{ plan.renewal }}
							</p>
							<div class="flex items-center gap-2">
								<span class="inline-flex items-center rounded-full bg-emerald-500/15 px-3 py-1 text-xs font-semibold text-emerald-300">
									{{ plan.status }}
								</span>
								<span class="text-xs text-n-slate-9">
									{{ plan.managedBy }}
								</span>
							</div>
						</div>
						<div class="flex flex-wrap gap-3">
							<ButtonV4 solid blue class="bg-emerald-500 hover:bg-emerald-400 border-0">
								Upgrade plan
							</ButtonV4>
							<ButtonV4 outline class="border-n-weak text-n-slate-12 hover:border-emerald-400 hover:text-emerald-300">
								Cancel subscription
							</ButtonV4>
						</div>
					</div>
				</BillingCard>

				<BillingCard
					title="Usage summary"
					description="Track how your team is consuming LeadFlowAI this billing cycle."
				>
					<div class="px-5 pb-5 space-y-4">
						<div
							v-for="metric in usageMetrics"
							:key="metric.label"
							class="space-y-2"
						>
							<div class="flex items-center justify-between text-sm">
								<p class="font-medium text-white">{{ metric.label }}</p>
								<p class="text-n-slate-9">
									{{ metric.value }} / {{ metric.limit }}
								</p>
							</div>
							<div class="h-2 rounded-full bg-n-solid-3">
								<div
									class="h-full rounded-full bg-emerald-500/80"
									:style="{ width: `${metric.percent}%` }"
								/>
							</div>
						</div>
					</div>
				</BillingCard>

				<BillingCard
					title="Quick actions"
					description="Common tasks to manage your LeadFlowAI subscription."
				>
					<div class="grid gap-4 px-5 pb-5 md:grid-cols-3">
						<article
							v-for="action in quickActions"
							:key="action.title"
							class="flex flex-col gap-3 rounded-xl border border-n-weak bg-n-solid-3/60 p-4"
						>
							<h3 class="text-sm font-semibold text-white">
								{{ action.title }}
							</h3>
							<p class="text-xs leading-relaxed text-n-slate-9">
								{{ action.description }}
							</p>
							<ButtonV4
								outline
								class="mt-auto w-fit border-emerald-500/40 text-emerald-300 hover:border-emerald-400"
							>
								{{ action.cta }}
							</ButtonV4>
						</article>
					</div>
				</BillingCard>

				<BillingCard
					title="Billing history"
					description="Your invoices from the past 12 months."
				>
					<div class="overflow-x-auto px-5 pb-5">
						<table class="min-w-full divide-y divide-n-solid-3 text-sm">
							<thead class="text-left text-xs uppercase tracking-wide text-n-slate-8">
								<tr>
									<th class="py-3 font-medium">Date</th>
									<th class="py-3 font-medium">Plan</th>
									<th class="py-3 font-medium">Amount</th>
									<th class="py-3 font-medium">Status</th>
									<th class="py-3 font-medium">Provider</th>
									<th class="py-3 font-medium text-right">Invoice</th>
								</tr>
							</thead>
							<tbody class="divide-y divide-n-solid-3 text-n-slate-10">
								<tr
									v-for="entry in billingHistory"
									:key="entry.date + entry.amount"
									class="hover:bg-n-solid-3/60"
								>
									<td class="py-3">{{ entry.date }}</td>
									<td class="py-3">{{ entry.plan }}</td>
									<td class="py-3">{{ entry.amount }}</td>
									<td class="py-3">
										<span class="inline-flex items-center rounded-full bg-emerald-500/15 px-2.5 py-1 text-xs font-semibold text-emerald-300">
											{{ entry.status }}
										</span>
									</td>
									<td class="py-3">{{ entry.provider }}</td>
									<td class="py-3 text-right">
										<ButtonV4
											link
											class="text-emerald-300 hover:text-emerald-200"
										>
											View PDF
										</ButtonV4>
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</BillingCard>

				<BillingCard
					title="Payment methods"
					description="LeadFlowAI relies on trusted payment providers for secure checkout."
				>
					<div class="flex flex-col gap-4 px-5 pb-5 md:flex-row md:items-center md:justify-between">
						<div class="flex items-center gap-4">
							<span class="flex items-center justify-center rounded-xl bg-n-solid-3 px-4 py-3 text-sm font-semibold text-white">
								PayPal
							</span>
							<span class="flex items-center justify-center rounded-xl bg-n-solid-3 px-4 py-3 text-sm font-semibold text-white">
								Google Pay
							</span>
						</div>
						<p class="text-xs text-n-slate-9">
							Payments are handled externally. LeadFlowAI never stores your credit card data.
						</p>
					</div>
				</BillingCard>

				<BillingCard
					title="Cancel subscription"
					description="You can cancel any time. Access to LeadFlowAI continues until the end of the billing period."
				>
					<div class="flex flex-col items-start gap-4 px-5 pb-5 sm:flex-row sm:items-center sm:justify-between">
						<p class="max-w-xl text-sm leading-relaxed text-n-slate-9">
							Canceling will stop future renewals. We will redirect you to PayPal or Google Pay to confirm the cancellation. Your workspaces remain accessible until your renewal date.
						</p>
						<ButtonV4
							outline
							class="border-red-400/60 text-red-300 hover:border-red-400 hover:text-red-200"
						>
							Cancel subscription
						</ButtonV4>
					</div>
				</BillingCard>
			</div>
		</template>
	</SettingsLayout>
</template>
